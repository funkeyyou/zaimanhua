# -*- coding: utf-8 -*-
# UI 簡轉繁（台灣用語）建置期轉換：lib/**/*.dart + assets/statement.txt
# 用法：pip install opencc-python-reimplemented && python tools/s2twp/convert.py
# 注意：這會改動工作目錄的源碼，建置完請還原（git checkout -- lib assets）
#      源碼一律以簡體提交（與上游一致）；繁體只存在於建置產物。
import pathlib
from opencc import OpenCC

cc = OpenCC('s2twp')
root = pathlib.Path(__file__).resolve().parents[2]

# 與伺服器回傳值比對的字面量，必須維持簡體
KEEP_SIMPLIFIED = ['漫画不存在', '连载中']
# 生成檔不動
SKIP_SUFFIXES = ('.pb.dart', '.pbenum.dart', '.pbjson.dart', '.pbserver.dart', '.g.dart')

def convert_file(path):
    with open(path, encoding='utf-8', newline='') as fh:
        text = fh.read()
    new = cc.convert(text)
    for lit in KEEP_SIMPLIFIED:
        new = new.replace(cc.convert(lit), lit)
    if new != text:
        with open(path, 'w', encoding='utf-8', newline='') as fh:
            fh.write(new)
        return True
    return False

count = 0
for f in sorted((root / 'lib').rglob('*.dart')):
    if f.name.endswith(SKIP_SUFFIXES):
        continue
    if convert_file(f):
        count += 1
print('converted dart files:', count)

st = root / 'assets' / 'statement.txt'
if st.exists() and convert_file(st):
    print('statement.txt converted')
