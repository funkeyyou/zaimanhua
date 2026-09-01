# -*- coding: utf-8 -*-
# codemod v2：服务器内容显示点加 .i18n
# 只处理 Text(X.field) / Tab(text: X.field) 且 field 在内容字段白名单内的场景；
# 逻辑比较、存储、请求参数不受影响（只动显示处）。幂等。
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
LIB = ROOT / 'lib'

FIELDS = (
    'title|name|authors|author|status|content|subTitle|types|tags|'
    'chapterTitle|chapterName|volumeName|comicName|novelName|objName|'
    'lastChapterName|lastName|recommendBrief|recommendReason|brief|'
    'description|summary|nickname|entityName'
)

# Text( 后可跨行空白；表达式为 a.b / a.b.c / a?.b 形式并以白名单字段结尾；后随 , 或 )
PATTERN = re.compile(
    r'((?:Text|SelectableText)\(\s*|Tab\(\s*text:\s*)'
    r'([A-Za-z_][\w?.\[\]\']*?\.(?:%s))'
    r'(\s*[,)])' % FIELDS,
    re.S,
)

SKIP_SUFFIXES = ('.pb.dart', '.pbenum.dart', '.pbjson.dart', '.pbserver.dart', '.g.dart')
SKIP_FILES = {'i18n.dart', 'i18n_dict.g.dart'}

changed = 0
for f in sorted(LIB.rglob('*.dart')):
    if f.name in SKIP_FILES or f.name.endswith(SKIP_SUFFIXES):
        continue
    text = f.read_text(encoding='utf-8')

    def repl(m):
        expr = m.group(2)
        if expr.endswith('.i18n'):
            return m.group(0)
        return m.group(1) + expr + '.i18n' + m.group(3)

    new = PATTERN.sub(repl, text)
    if new != text:
        if "import 'package:zai_x/app/i18n.dart';" not in new:
            lines = new.split('\n')
            last_import = -1
            for idx, l in enumerate(lines):
                if l.lstrip().startswith('import '):
                    last_import = idx
            lines.insert(last_import + 1, "import 'package:zai_x/app/i18n.dart';")
            new = '\n'.join(lines)
        f.write_text(new, encoding='utf-8', newline='')
        changed += 1
print('changed files:', changed)
