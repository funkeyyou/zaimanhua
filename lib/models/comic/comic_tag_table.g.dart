// 漫画标签表
//
// 由 tools/tags/fetch_tags.py 生成，请勿手动修改。
// 服务端 /comic/filter/category 只返回一部分标签，像 ゆり、AA、纯爱、历史 这些
// 都被藏了起来，但它们的 tagId 拿去 /comic/filter/list 依然可以正常筛选。
// 这里保存完整表，运行时和服务端返回的列表合并。

/// 标签维度，与服务端 cateList 的 tagType 一致
class ComicTagDimension {
  /// 题材
  static const int theme = 1;

  /// 地区
  static const int zone = 4;

  /// 进度
  static const int status = 5;

  /// 受众
  static const int audience = 6;
}

/// 本地排序分组用的维度，服务端不存在
const int kComicSortDimension = -1;

class ComicTagEntry {
  const ComicTagEntry(this.tagId, this.title, this.dimension);

  final int tagId;
  final String title;
  final int dimension;
}

/// 完整标签表
const List<ComicTagEntry> kComicTagTable = <ComicTagEntry>[
  // 受众
  ComicTagEntry(3262, "少年漫", ComicTagDimension.audience),
  ComicTagEntry(3263, "少女漫", ComicTagDimension.audience),
  ComicTagEntry(3264, "青年漫", ComicTagDimension.audience),
  ComicTagEntry(13626, "女青漫", ComicTagDimension.audience),
  // 地区
  ComicTagEntry(2304, "日本", ComicTagDimension.zone),
  ComicTagEntry(2305, "韩国", ComicTagDimension.zone),
  ComicTagEntry(2306, "欧美", ComicTagDimension.zone),
  ComicTagEntry(2308, "国漫", ComicTagDimension.zone),
  // 进度
  ComicTagEntry(2309, "连载", ComicTagDimension.status),
  ComicTagEntry(2310, "完结", ComicTagDimension.status),
  // 题材
  ComicTagEntry(4, "冒险", ComicTagDimension.theme),
  ComicTagEntry(5, "欢乐向", ComicTagDimension.theme),
  ComicTagEntry(6, "格斗", ComicTagDimension.theme),
  ComicTagEntry(7, "科幻", ComicTagDimension.theme),
  ComicTagEntry(8, "爱情", ComicTagDimension.theme),
  ComicTagEntry(9, "侦探", ComicTagDimension.theme),
  ComicTagEntry(10, "竞技", ComicTagDimension.theme),
  ComicTagEntry(11, "魔法", ComicTagDimension.theme),
  ComicTagEntry(12, "神鬼", ComicTagDimension.theme),
  ComicTagEntry(13, "校园", ComicTagDimension.theme),
  ComicTagEntry(14, "惊悚", ComicTagDimension.theme),
  ComicTagEntry(16, "其他", ComicTagDimension.theme),
  ComicTagEntry(17, "四格", ComicTagDimension.theme),
  ComicTagEntry(3242, "亲情", ComicTagDimension.theme),
  ComicTagEntry(3243, "ゆり", ComicTagDimension.theme),
  ComicTagEntry(3244, "秀吉", ComicTagDimension.theme),
  ComicTagEntry(3245, "悬疑", ComicTagDimension.theme),
  ComicTagEntry(3246, "纯爱", ComicTagDimension.theme),
  ComicTagEntry(3248, "热血", ComicTagDimension.theme),
  ComicTagEntry(3250, "历史", ComicTagDimension.theme),
  ComicTagEntry(3251, "战争", ComicTagDimension.theme),
  ComicTagEntry(3252, "萌系", ComicTagDimension.theme),
  ComicTagEntry(3253, "宅系", ComicTagDimension.theme),
  ComicTagEntry(3254, "治愈", ComicTagDimension.theme),
  ComicTagEntry(3255, "励志", ComicTagDimension.theme),
  ComicTagEntry(3324, "武侠", ComicTagDimension.theme),
  ComicTagEntry(3325, "机战", ComicTagDimension.theme),
  ComicTagEntry(3326, "音乐舞蹈", ComicTagDimension.theme),
  ComicTagEntry(3327, "美食", ComicTagDimension.theme),
  ComicTagEntry(3328, "职场", ComicTagDimension.theme),
  ComicTagEntry(4518, "TS", ComicTagDimension.theme),
  ComicTagEntry(5077, "东方", ComicTagDimension.theme),
  ComicTagEntry(5806, "魔幻", ComicTagDimension.theme),
  ComicTagEntry(5848, "奇幻", ComicTagDimension.theme),
  ComicTagEntry(6316, "轻小说", ComicTagDimension.theme),
  ComicTagEntry(6437, "颜艺", ComicTagDimension.theme),
  ComicTagEntry(7568, "搞笑", ComicTagDimension.theme),
  ComicTagEntry(7900, "仙侠", ComicTagDimension.theme),
  ComicTagEntry(13627, "舰娘", ComicTagDimension.theme),
  ComicTagEntry(18522, "AA", ComicTagDimension.theme),
  ComicTagEntry(23323, "福瑞", ComicTagDimension.theme),
  ComicTagEntry(30788, "日常", ComicTagDimension.theme),
  ComicTagEntry(31137, "画集", ComicTagDimension.theme),
  ComicTagEntry(34093, "2025冬", ComicTagDimension.theme),
  ComicTagEntry(36172, "2026春", ComicTagDimension.theme),
];

/// tagId -> 标签
final Map<int, ComicTagEntry> kComicTagById = <int, ComicTagEntry>{
  for (final ComicTagEntry tag in kComicTagTable) tag.tagId: tag,
};

/// 服务端列表里出现过、但和标签表用词不同的别名
///
/// 列表接口返回的 types 字符串有时还是旧名字，详情接口才是现用名。
const Map<String, String> kComicTagAlias = <String, String>{
  "百合": "ゆり",
  "伪娘": "秀吉",
  "生活": "亲情",
  "恐怖": "惊悚",
  "轻小说改": "轻小说",
  "车万": "东方",
};
