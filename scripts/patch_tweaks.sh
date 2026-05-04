#!/usr/bin/env bash
set -euo pipefail

patch_if_file() {
  local file="$1"
  local label="$2"

  if [ ! -f "$file" ]; then
    echo "==> Skipping $label, missing: $file"
    return 0
  fi

  return 0
}

echo "==> Applying optional patches"

if [ -f "YouMod/YouSpeed/Tweak.x" ]; then
  echo "==> Patch YouSpeed default video overlay enabled"
  perl -0pi -e 's/%ctor \{\n/%ctor {\n  [[NSUserDefaults standardUserDefaults] registerDefaults:\@{\@\"YTVideoOverlay-YouSpeed-Enabled\": \@YES}];\n\n/' YouMod/YouSpeed/Tweak.x
else
  echo "==> Skipping YouSpeed patch"
fi

if [ -f "YouMod/YouMute/Tweak.x" ]; then
  echo "==> Patch YouMute default settings"
  perl -0pi -e 's/%ctor \{\n/%ctor {\n  [[NSUserDefaults standardUserDefaults] registerDefaults:\@{\@\"YTVideoOverlay-YouMute-Enabled\": \@YES, \@\"YouMuteKeepMuted\": \@YES}];\n\n/' YouMod/YouMute/Tweak.x

  echo "==> Patch YouMute persistent mute"
  perl -0777 -i -pe 's~%group Muted\n\n%hook YTSingleVideoController\n\n- \(void\)setMuted:\(BOOL\)muted \{\n    %orig\(shouldMute\(\)\);\n\}\n\n%end\n\n%end\n~%group Muted\n\n%hook YTSingleVideoController\n\n- (void)setMuted:(BOOL)muted {\n    %orig(shouldMute());\n\n    dispatch_async(dispatch_get_main_queue(), ^{\n        %orig(shouldMute());\n    });\n\n    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{\n        %orig(shouldMute());\n    });\n}\n\n- (void)play {\n    %orig;\n\n    dispatch_async(dispatch_get_main_queue(), ^{\n        [self setMuted:shouldMute()];\n    });\n\n    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{\n        [self setMuted:shouldMute()];\n    });\n}\n\n%end\n\n%end\n~s' YouMod/YouMute/Tweak.x
else
  echo "==> Skipping YouMute patch"
fi

if [ -f "YouMod/YouChooseQuality/Settings.x" ]; then
  echo "==> Patch YouChooseQuality defaults"

  python3 <<'PY'
from pathlib import Path

file = Path("YouMod/YouChooseQuality/Settings.x")
text = file.read_text()

insert = """
__attribute__((constructor)) static void YCQRegisterDefaults(void) {
  [[NSUserDefaults standardUserDefaults] registerDefaults:@{
    @"YCQ-Enabled": @YES,
    @"YCQ-Quality-0": @216060,
    @"YCQ-Quality-2": @216060
  }];
}
"""

if "YCQRegisterDefaults" not in text:
    text = text.replace(
        "static const NSInteger TweakSection = 'ycql';",
        "static const NSInteger TweakSection = 'ycql';\n" + insert,
        1
    )
    file.write_text(text)
    print("Patched YouChooseQuality defaults")
else:
    print("Already patched")
PY
else
  echo "==> Skipping YouChooseQuality patch"
fi

if [ -f "YouMod/Gonerino/sources/Tweak.x" ]; then
  echo "==> Patch Gonerino default button visibility"
  perl -0pi -e 's/\? YES(\s*:\s*\[\[NSUserDefaults standardUserDefaults\] boolForKey:@"GonerinoShowButton"\])/\? NO$1/g' YouMod/Gonerino/sources/Tweak.x
fi

if [ -f "YouMod/Gonerino/sources/Settings.x" ]; then
  perl -0pi -e 's/\? YES(\s*:\s*\[\[NSUserDefaults standardUserDefaults\] boolForKey:@"GonerinoShowButton"\])/\? NO$1/g' YouMod/Gonerino/sources/Settings.x
fi

echo "==> Patch step complete"