#!/usr/bin/env bash
set -euo pipefail

echo "==> Patch YTLocalQueue"

python3 <<'PY'
from pathlib import Path

file = Path("YTLocalQueue/Tweak.xm")
if not file.is_file():
    print("YTLocalQueue/Tweak.xm not found, skipping")
    raise SystemExit(0)

text = file.read_text()

text = text.replace(
    "for (NSUInteger i = 0; i < actions.count; i++) {",
    "for (NSInteger i = 0; i < (NSInteger)actions.count; i++) {",
    1
)

old = '''if ([t containsString:@"play next in queue"]) { 
                    queueIndex = i; 
                    break; 
                }'''

new = '''if ([t containsString:@"download"]) {
                    [actions removeObjectAtIndex:i];
                    i--;
                    continue;
                }

                if ([t containsString:@"play next in queue"]) { 
                    queueIndex = i; 
                    break; 
                }'''

if old in text and "removeObjectAtIndex:i" not in text:
    text = text.replace(old, new, 1)
    file.write_text(text)
    print("Patched YTLocalQueue menu")
else:
    print("Already patched or anchor not found")
PY
