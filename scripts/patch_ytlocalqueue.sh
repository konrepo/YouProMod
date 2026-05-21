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

# 1) Playlist / renderer menu path
text = text.replace(
    "for (NSUInteger i = 0; i < actions.count; i++) {",
    "for (NSInteger i = 0; i < (NSInteger)actions.count; i++) {",
    1
)

old_menu = '''if ([t containsString:@"play next in queue"]) { 
                    queueIndex = i; 
                    break; 
                }'''

new_menu = '''if ([t isEqualToString:@"download video"] ||
                    [t isEqualToString:@"download"]) {
                    [actions removeObjectAtIndex:i];
                    i--;
                    continue;
                }

                if ([t containsString:@"play next in queue"]) { 
                    queueIndex = i; 
                    break; 
                }'''

if old_menu in text and "removeObjectAtIndex:i" not in text:
    text = text.replace(old_menu, new_menu, 1)
    print("Patched YTMenuController path")
else:
    print("YTMenuController path already patched or anchor not found")

# 2) Feed / default sheet path
old_sheet = '''    if (origDefaultSheetAddAction) origDefaultSheetAddAction(self, _cmd, action);'''

new_sheet = '''    @try {
        NSString *title = nil;

        if ([action respondsToSelector:@selector(button)]) {
            id btn = [action button];
            if ([btn isKindOfClass:[UIButton class]]) {
                title = [(UIButton *)btn currentTitle];
            }
        }

        if (title.length == 0) {
            title = [action valueForKey:@"_title"];
        }

        NSString *t = title.lowercaseString;
        if ([t isEqualToString:@"download video"] ||
            [t isEqualToString:@"download"]) {
            return;
        }
    } @catch (__unused NSException *e) {}

    if (origDefaultSheetAddAction) origDefaultSheetAddAction(self, _cmd, action);'''

if old_sheet in text and "YTLPRemoveNativeDownload" not in text:
    text = text.replace(
        old_sheet,
        "    // YTLPRemoveNativeDownload\n" + new_sheet,
        1
    )
    print("Patched YTDefaultSheetController path")
else:
    print("YTDefaultSheetController path already patched or anchor not found")

file.write_text(text)
print("YTLocalQueue patch complete")
PY
