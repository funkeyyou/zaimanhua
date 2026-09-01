# -*- coding: utf-8 -*-
# codemod：给 lib 下含中文的字串字面量补上 .i18n 后缀，并补 import。
# 幂等：已带 .i18n 的不重复处理。跳过注释、生成档、受保护字面量。
# 用法：python tools/i18n/apply_i18n.py
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
LIB = ROOT / 'lib'

CJK = re.compile(r'[一-鿿]')
SKIP_FILES = {'i18n.dart', 'i18n_dict.g.dart'}
SKIP_SUFFIXES = ('.pb.dart', '.pbenum.dart', '.pbjson.dart', '.pbserver.dart', '.g.dart')
PROTECTED = {'连载中', '漫画不存在'}
IMPORT_LINE = "import 'package:zai_x/app/i18n.dart';"

def process_line(line, state):
    """返回 (新行, state, 是否改动)。逐字扫描，跳过注释；对代码区的中文字串补 .i18n。"""
    out = []
    i, n = 0, len(line)
    changed = False
    while i < n:
        ch = line[i]
        if state['block']:
            j = line.find('*/', i)
            if j < 0:
                out.append(line[i:])
                return ''.join(out), state, changed
            out.append(line[i:j + 2])
            state['block'] = False
            i = j + 2
            continue
        if ch in ('"', "'"):
            quote = ch
            j = i + 1
            body = []
            while j < n:
                c = line[j]
                if c == '\\' and j + 1 < n:
                    body.append(line[j:j + 2])
                    j += 2
                    continue
                if c == quote:
                    break
                body.append(c)
                j += 1
            if j >= n:  # 未闭合（三引号等），整行原样
                out.append(line[i:])
                return ''.join(out), state, changed
            raw = ''.join(body)
            literal = line[i:j + 1]
            rest = line[j + 1:j + 6]
            if (CJK.search(raw) and raw not in PROTECTED
                    and not rest.startswith('.i18n')
                    and not (i >= 1 and line[i - 1] == 'r')):
                out.append(literal + '.i18n')
                changed = True
            else:
                out.append(literal)
            i = j + 1
            continue
        if ch == '/' and i + 1 < n and line[i + 1] == '/':
            out.append(line[i:])
            return ''.join(out), state, changed
        if ch == '/' and i + 1 < n and line[i + 1] == '*':
            state['block'] = True
            out.append('/*')
            i += 2
            continue
        out.append(ch)
        i += 1
    return ''.join(out), state, changed

changed_files = 0
for f in sorted(LIB.rglob('*.dart')):
    if f.name in SKIP_FILES or f.name.endswith(SKIP_SUFFIXES):
        continue
    text = f.read_text(encoding='utf-8')
    state = {'block': False}
    new_lines = []
    file_changed = False
    for line in text.split('\n'):
        s = line.lstrip()
        if s.startswith('import ') or s.startswith('export ') or s.startswith('part '):
            new_lines.append(line)
            continue
        nl, state, ch = process_line(line, state)
        new_lines.append(nl)
        file_changed = file_changed or ch
    if not file_changed:
        continue
    new_text = '\n'.join(new_lines)
    if IMPORT_LINE not in new_text:
        lines = new_text.split('\n')
        last_import = -1
        for idx, l in enumerate(lines):
            if l.lstrip().startswith('import '):
                last_import = idx
        if last_import >= 0:
            lines.insert(last_import + 1, IMPORT_LINE)
        else:
            lines.insert(0, IMPORT_LINE)
        new_text = '\n'.join(lines)
    f.write_text(new_text, encoding='utf-8', newline='')
    changed_files += 1
print('changed files:', changed_files)
