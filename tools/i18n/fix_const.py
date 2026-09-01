# -*- coding: utf-8 -*-
# 迭代跑 flutter analyze，自动移除因 .i18n 造成 const 冲突的 `const ` 关键字。
# 用法：python tools/i18n/fix_const.py
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
FLUTTER = r"C:\Users\funke\flutter\bin\flutter.bat"

ERR = re.compile(r'^\s*error [-•] .*? [-•] (.+?\.dart):(\d+):(\d+) [-•] ([a-z_]+)\s*$')
CONST_CODES_EXACT = {
    'non_constant_list_element', 'const_with_non_constant_argument',
    'invalid_constant', 'const_initialized_with_non_constant_value',
    'non_constant_map_element', 'non_constant_map_key', 'non_constant_map_value',
}
CONST_CODES_PREFIX = ('const_eval',)

def analyze():
    p = subprocess.run([FLUTTER, 'analyze', '--no-pub'], cwd=str(ROOT),
                       capture_output=True, text=True, encoding='utf-8', errors='replace')
    errs = []
    for line in (p.stdout or '').splitlines() + (p.stderr or '').splitlines():
        m = ERR.match(line)
        if m:
            errs.append((m.group(1), int(m.group(2)), int(m.group(3)), m.group(4)))
    return errs

for round_no in range(1, 13):
    errs = analyze()
    const_errs = [e for e in errs if e[3] in CONST_CODES_EXACT
                  or e[3].startswith(CONST_CODES_PREFIX)]
    default_errs = [e for e in errs if e[3] == 'non_constant_default_value']
    other = [e for e in errs if e not in const_errs and e not in default_errs]
    print(f'round {round_no}: const-errors={len(const_errs)} default-errors={len(default_errs)} other-errors={len(other)}')
    if other:
        for e in other[:10]:
            print('  OTHER:', e)
    if not const_errs and not default_errs:
        print('done.')
        sys.exit(0)
    touched = set()
    by_file = {}
    for f, ln, col, code in const_errs + default_errs:
        by_file.setdefault(f, []).append((ln, col, code))
    for f, items in by_file.items():
        path = (ROOT / f).resolve() if not pathlib.Path(f).is_absolute() else pathlib.Path(f)
        try:
            lines = path.read_text(encoding='utf-8').split('\n')
        except FileNotFoundError:
            print('  missing file?', f)
            continue
        # 从下往上处理，避免行号位移（只动关键字，不动行数，其实安全，但保持谨慎）
        for ln, col, code in sorted(items, reverse=True):
            if code == 'non_constant_default_value':
                # 参数默认值不能非常量：移除该行附近的 .i18n
                idx = ln - 1
                if 0 <= idx < len(lines) and '.i18n' in lines[idx]:
                    lines[idx] = lines[idx].replace('.i18n', '', 1)
                    print(f'  removed .i18n (default value) {f}:{ln}')
                continue
            # 向上找最近的 const
            removed = False
            for up in range(0, 26):
                idx = ln - 1 - up
                if idx < 0:
                    break
                key = (f, idx)
                if key in touched:
                    continue
                line = lines[idx]
                ms = list(re.finditer(r'\bconst\s+', line))
                if not ms:
                    continue
                if up == 0:
                    ms = [m for m in ms if m.start() <= col - 1] or ms
                m = ms[-1]
                lines[idx] = line[:m.start()] + line[m.end():]
                touched.add(key)
                removed = True
                break
            if not removed:
                print(f'  UNFIXED {f}:{ln}:{col} {code}')
        path.write_text('\n'.join(lines), encoding='utf-8', newline='')
print('max rounds reached; check remaining errors manually')
sys.exit(1)
