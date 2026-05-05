#!/usr/bin/env bash
set -euo pipefail

patch_once() {
  local file="$1"
  local check="$2"
  local perl_cmd="$3"

  [ -f "$file" ] || { echo "==> Missing $file"; exit 1; }

  if grep -q "$check" "$file"; then
    echo "==> Already patched ($file)"
  else
    echo "==> Patching $file"
    perl -0pi -e "$perl_cmd" "$file"
  fi
}

echo "==> Applying patches"

# YouSpeed
patch_once "YouSpeed/Tweak.x" \
  'YTVideoOverlay-YouSpeed-Enabled' \
  's/%ctor \{\n/%ctor {\n  [[NSUserDefaults standardUserDefaults] registerDefaults:\@{\@\"YTVideoOverlay-YouSpeed-Enabled\": \@YES}];\n\n/'

# YouMute
echo "==> Patch YouMute default settings"
[ -f YouMute/Tweak.x ] || { echo "Missing YouMute/Tweak.x"; exit 1; }
perl -0pi -e 's/%ctor \{\n/%ctor {\n  [[NSUserDefaults standardUserDefaults] registerDefaults:\@{\@\"YTVideoOverlay-YouMute-Enabled\": \@YES, \@\"YouMuteKeepMuted\": \@YES}];\n\n/' YouMute/Tweak.x

echo "==> Patch YouMute persistent mute"
perl -0777 -i -pe 's~%group Muted\n\n%hook YTSingleVideoController\n\n- \(void\)setMuted:\(BOOL\)muted \{\n    %orig\(shouldMute\(\)\);\n\}\n\n%end\n\n%end\n~%group Muted\n\n%hook YTSingleVideoController\n\n- (void)setMuted:(BOOL)muted {\n    %orig(shouldMute());\n\n    dispatch_async(dispatch_get_main_queue(), ^{\n        %orig(shouldMute());\n    });\n\n    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{\n        %orig(shouldMute());\n    });\n}\n\n- (void)play {\n    %orig;\n\n    dispatch_async(dispatch_get_main_queue(), ^{\n        [self setMuted:shouldMute()];\n    });\n\n    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{\n        [self setMuted:shouldMute()];\n    });\n}\n\n%end\n\n%end\n~s' YouMute/Tweak.x

echo "==> Verify YouMute patch"
grep -n "void)play" YouMute/Tweak.x
grep -n "dispatch_after" YouMute/Tweak.x

# YouChooseQuality
echo "==> Patch YouChooseQuality defaults"

python3 <<'PY'
from pathlib import Path
import textwrap

file = Path("YouChooseQuality/Settings.x")

if not file.is_file():
    print("Missing YouChooseQuality/Settings.x")
    exit(1)

text = file.read_text()

insert = textwrap.dedent("""
__attribute__((constructor)) static void YCQRegisterDefaults(void) {
  [[NSUserDefaults standardUserDefaults] registerDefaults:@{
    @"YCQ-Enabled": @YES,
    @"YCQ-Quality-0": @216060,
    @"YCQ-Quality-2": @216060
  }];
}
""")

if "YCQRegisterDefaults" not in text:
    text = text.replace(
        "static const NSInteger TweakSection = 'ycql';",
        "static const NSInteger TweakSection = 'ycql';\n" + insert,
        1
    )
    file.write_text(text)
    print("Patched YouChooseQuality defaults")
else:
    print("Already patched YouChooseQuality defaults")
PY

# YouMod defaults
echo "==> Patch YouMod defaults"

python3 <<'PY'
from pathlib import Path

file = Path("YouMod/Files/Settings.x")
if not file.is_file():
    print("Missing YouMod/Files/Settings.x")
    exit(1)

text = file.read_text()
old = "OldQualityPicker: @YES,"

new = """OldQualityPicker: @YES,
        GestureControls: @YES,
        HideShortsShelf: @YES,
        GestureHUD: @YES,
        HidePaidPromoOverlay: @YES,"""

if "GestureControls: @YES" not in text and old in text:
    text = text.replace(old, new, 1)
    file.write_text(text)
    print("Patched YouMod defaults")
else:
    print("Already patched or anchor not found")
PY

# YouMod Player runtime defaults
echo "==> Patch YouMod Player runtime defaults"

python3 <<'PY'
from pathlib import Path

file = Path("YouMod/Files/Player.x")
if not file.is_file():
    print("Missing YouMod/Files/Player.x")
    exit(1)

text = file.read_text()
old = "%ctor {\n    %init;"

insert = """%ctor {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        GestureControls: @YES,
        GestureHUD: @YES,
        HidePaidPromoOverlay: @YES,
    }];

    %init;"""

if "HidePaidPromoOverlay: @YES" not in text and old in text:
    text = text.replace(old, insert, 1)
    file.write_text(text)
    print("Patched YouMod Player runtime defaults")
else:
    print("Already patched or anchor not found")
PY

# YouMod Feed runtime defaults
echo "==> Patch YouMod Feed runtime defaults"

python3 <<'PY'
from pathlib import Path

file = Path("YouMod/Files/Feed.x")
if not file.is_file():
    print("Missing YouMod/Files/Feed.x")
    exit(1)

text = file.read_text()
old = "%ctor {\n    %init;"

insert = """%ctor {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        HideShortsShelf: @YES,
    }];

    %init;"""

if "HideShortsShelf: @YES" not in text and old in text:
    text = text.replace(old, insert, 1)
    file.write_text(text)
    print("Patched YouMod Feed runtime defaults")
else:
    print("Already patched or anchor not found")
PY

# YouGroupSettings - YouPro
echo "==> Patch YouGroupSettings"

python3 <<'PY'
from pathlib import Path

file = Path("YouGroupSettings/Tweak.x")
text = file.read_text()

# Add YouPro constant
if "static const NSInteger YouPro" not in text:
    text = text.replace(
        "static const NSInteger YouMod = 'ytmo';",
        "static const NSInteger YouMod = 'ytmo';\nstatic const NSInteger YouPro = 999;"
    )

# Insert YouPro as FIRST item
if "@(YouPro)" not in text:
    text = text.replace(
        "[tweaks addObjectsFromArray:@[",
        "[tweaks addObjectsFromArray:@[\n            @(YouPro), // YouPro"
    )
    print("Inserted YouPro at top")
else:
    print("YouPro already exists")

file.write_text(text)
print("Patched YouGroupSettings YouPro")
PY

echo "==> Patch step complete"
