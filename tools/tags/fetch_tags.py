# -*- coding: utf-8 -*-
"""重新生成 lib/models/comic/comic_tag_table.g.dart。

服务端 /comic/filter/category 只返回一部分标签，ゆり、AA、纯爱、历史 这些
都被藏了起来，但它们的 tagId 拿去 /comic/filter/list 依然可以正常筛选。
这个脚本把全站扫一遍，把实际在用的标签全部找出来。

做法：
  1. 按首字母 a-z、9 翻 /comic/filter/list，收集作品和它们的 types 字符串；
  2. types 只有名字没有 ID，所以对含未知标签的作品查 /comic/detail/{id}，
     详情接口的 types 数组带 tag_id；
  3. 合并服务端 cateList（受众/地区/进度/题材四个维度）后输出 Dart 文件。

用法：python tools/tags/fetch_tags.py [--pages 25]
"""
import argparse
import json
import pathlib
import re
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from urllib.request import Request, urlopen

BASE = "https://v4api.zaimanhua.com/app/v1"
ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "lib" / "models" / "comic" / "comic_tag_table.g.dart"

DIMENSION_NAME = {1: "theme", 4: "zone", 5: "status", 6: "audience"}
DIMENSION_LABEL = {1: "题材", 4: "地区", 5: "进度", 6: "受众"}
SPLIT = re.compile(r"[,/、]")

# 列表接口的 types 里还留着旧名字，详情接口才是现用名
ALIAS = {
    "百合": "ゆり",
    "伪娘": "秀吉",
    "生活": "亲情",
    "恐怖": "惊悚",
    "轻小说改": "轻小说",
    "车万": "东方",
}


def get_json(url, tries=3):
    for i in range(tries):
        try:
            req = Request(url, headers={"User-Agent": "okhttp/4.9.3"})
            with urlopen(req, timeout=25) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except Exception:
            if i == tries - 1:
                return None
            time.sleep(0.5)
    return None


def fetch_cate_list():
    data = get_json(BASE + "/comic/filter/category?source=1")
    if not data:
        sys.exit("无法读取 /comic/filter/category")
    return data["data"]["cateList"]


def sweep_comics(pages):
    """按首字母翻全站，返回 {comicId: types 字符串}"""
    jobs = []
    for letter in list("abcdefghijklmnopqrstuvwxyz") + ["9"]:
        for page in range(1, pages + 1):
            jobs.append((letter, page))

    comics = {}

    def run(job):
        letter, page = job
        url = (BASE + "/comic/filter/list?theme=0&status=0&sortType=1"
               "&page=%d&size=40&firstLetter=%s" % (page, letter))
        data = get_json(url)
        if not data:
            return []
        return data.get("data", {}).get("comicList") or []

    with ThreadPoolExecutor(max_workers=10) as pool:
        for items in pool.map(run, jobs):
            for item in items:
                comics[item["id"]] = item.get("types") or ""
    return comics


def split_types(text):
    return [x.strip() for x in SPLIT.split(text) if x.strip()]


def resolve_ids(comics, known_names):
    """对含未知标签的作品查详情，拿回 tag_id"""
    by_name = {}
    for comic_id, types in comics.items():
        for name in split_types(types):
            by_name.setdefault(name, []).append(comic_id)

    pending = [n for n in by_name if n not in known_names and n not in ALIAS]
    found = {}

    def run(name):
        out = []
        for comic_id in by_name[name][:25]:
            data = get_json(BASE + "/comic/detail/%d" % comic_id)
            if not data:
                continue
            types = (data.get("data", {}).get("data", {}) or {}).get("types") or []
            for tag in types:
                out.append((tag["tag_id"], tag["tag_name"]))
            if any(n == name for _, n in out):
                break
        return out

    with ThreadPoolExecutor(max_workers=6) as pool:
        for pairs in pool.map(run, pending):
            for tag_id, tag_name in pairs:
                found[tag_id] = tag_name

    unresolved = sorted(
        n for n in pending
        if n not in known_names and n not in found.values()
    )
    return found, unresolved


def dart_escape(text):
    return text.replace("\\", "\\\\").replace('"', '\\"').replace("$", "\\$")


def render(tags):
    """tags: [(tagId, title, dimension)]"""
    lines = [
        "// 漫画标签表",
        "//",
        "// 由 tools/tags/fetch_tags.py 生成，请勿手动修改。",
        "// 服务端 /comic/filter/category 只返回一部分标签，像 ゆり、AA、纯爱、历史 这些",
        "// 都被藏了起来，但它们的 tagId 拿去 /comic/filter/list 依然可以正常筛选。",
        "// 这里保存完整表，运行时和服务端返回的列表合并。",
        "",
        "/// 标签维度，与服务端 cateList 的 tagType 一致",
        "class ComicTagDimension {",
        "  /// 题材",
        "  static const int theme = 1;",
        "",
        "  /// 地区",
        "  static const int zone = 4;",
        "",
        "  /// 进度",
        "  static const int status = 5;",
        "",
        "  /// 受众",
        "  static const int audience = 6;",
        "}",
        "",
        "/// 本地排序分组用的维度，服务端不存在",
        "const int kComicSortDimension = -1;",
        "",
        "class ComicTagEntry {",
        "  const ComicTagEntry(this.tagId, this.title, this.dimension);",
        "",
        "  final int tagId;",
        "  final String title;",
        "  final int dimension;",
        "}",
        "",
        "/// 完整标签表",
        "const List<ComicTagEntry> kComicTagTable = <ComicTagEntry>[",
    ]
    for dimension in (6, 4, 5, 1):
        group = [t for t in tags if t[2] == dimension]
        if not group:
            continue
        lines.append("  // %s" % DIMENSION_LABEL[dimension])
        for tag_id, title, _ in sorted(group, key=lambda x: x[0]):
            lines.append('  ComicTagEntry(%d, "%s", ComicTagDimension.%s),'
                         % (tag_id, dart_escape(title), DIMENSION_NAME[dimension]))
    lines += [
        "];",
        "",
        "/// tagId -> 标签",
        "final Map<int, ComicTagEntry> kComicTagById = <int, ComicTagEntry>{",
        "  for (final ComicTagEntry tag in kComicTagTable) tag.tagId: tag,",
        "};",
        "",
        "/// 服务端列表里出现过、但和标签表用词不同的别名",
        "///",
        "/// 列表接口返回的 types 字符串有时还是旧名字，详情接口才是现用名。",
        "const Map<String, String> kComicTagAlias = <String, String>{",
    ]
    for old, new in ALIAS.items():
        lines.append('  "%s": "%s",' % (dart_escape(old), dart_escape(new)))
    lines.append("};")
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--pages", type=int, default=25,
                        help="每个首字母翻多少页（40 条/页）")
    args = parser.parse_args()

    cate_list = fetch_cate_list()
    tags = {}
    for item in cate_list:
        tags[item["tagId"]] = (item["title"], item.get("tagType", 1))
    known_names = {v[0] for v in tags.values()}
    print("服务端标签 %d 个" % len(tags))

    comics = sweep_comics(args.pages)
    print("扫到作品 %d 部" % len(comics))

    found, unresolved = resolve_ids(comics, known_names)
    added = 0
    for tag_id, title in found.items():
        if tag_id in tags:
            # 详情接口的名字更新，以它为准
            tags[tag_id] = (title, tags[tag_id][1])
        else:
            tags[tag_id] = (title, 1)
            added += 1
    print("补上隐藏标签 %d 个" % added)
    if unresolved:
        print("查不到 tagId（列表专用标签，已跳过）：%s" % "、".join(unresolved))

    rows = [(tag_id, title, dimension)
            for tag_id, (title, dimension) in tags.items()]
    OUT.write_text(render(rows), encoding="utf-8")
    print("已写入 %s，共 %d 个标签" % (OUT.relative_to(ROOT), len(rows)))


if __name__ == "__main__":
    main()
