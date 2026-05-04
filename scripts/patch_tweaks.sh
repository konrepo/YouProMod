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

# YouMute defaults
patch_once "YouMute/Tweak.x" \
  'YouMuteKeepMuted' \
  's/%ctor \{\n/%ctor {\n  [[NSUserDefaults standardUserDefaults] registerDefaults:\@{\@\"YTVideoOverlay-YouMute-Enabled\": \@YES, \@\"YouMuteKeepMuted\": \@YES}];\n\n/'

# YouMute persistent mute
echo "==> Patch YouMute persistent mute"

[ -f "YouMute/Tweak.x" ] || { echo "==> Missing YouMute/Tweak.x"; exit 1; }

if grep -q "void)play" YouMute/Tweak.x; then
  echo "==> Already patched (YouMute persistent mute)"
else
  perl -0777 -i -pe 's~%group Muted\n\n%hook YTSingleVideoController\n\n- \(void\)setMuted:\(BOOL\)muted \{\n    %orig\(shouldMute\(\)\);\n\}\n\n%end\n\n%end\n~%group Muted\n\n%hook YTSingleVideoController\n\n- (void)setMuted:(BOOL)muted {\n    %orig(shouldMute());\n\n    dispatch_async(dispatch_get_main_queue(), ^{\n        %orig(shouldMute());\n    });\n\n    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{\n        %orig(shouldMute());\n    });\n}\n\n- (void)play {\n    %orig;\n\n    dispatch_async(dispatch_get_main_queue(), ^{\n        [self setMuted:shouldMute()];\n    });\n\n    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{\n        [self setMuted:shouldMute()];\n    });\n}\n\n%end\n\n%end\n~s' YouMute/Tweak.x
fi

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

if "GestureControls: @YES" not in text and old in text:
    text = text.replace(
        old,
        """OldQualityPicker: @YES,
        GestureControls: @YES,
        HideShortsShelf: @YES,
        GestureHUD: @YES,""",
        1
    )
    file.write_text(text)
    print("Patched YouMod defaults")
else:
    print("Already patched or anchor not found")
PY

echo "==> Patch step complete"
