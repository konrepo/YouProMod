#!/usr/bin/env bash
set -euo pipefail

# YouSpeed Patch
#echo "==> Patch YouSpeed default video overlay enabled"
#[ -f YouSpeed/Tweak.x ] || { echo "Missing YouSpeed/Tweak.x"; exit 1; }
#perl -0pi -e 's/%ctor \{\n/%ctor {\n  [[NSUserDefaults standardUserDefaults] registerDefaults:\@{\@\"YTVideoOverlay-YouSpeed-Enabled\": \@YES}];\n\n/' YouSpeed/Tweak.x

# YouMute Patch
echo "==> Patch YouMute default settings"
[ -f YouMute/Tweak.x ] || { echo "Missing YouMute/Tweak.x"; exit 1; }
perl -0pi -e 's/%ctor \{\n/%ctor {\n  [[NSUserDefaults standardUserDefaults] registerDefaults:\@{\@\"YTVideoOverlay-YouMute-Enabled\": \@YES, \@\"YouMuteKeepMuted\": \@YES}];\n\n/' YouMute/Tweak.x

echo "==> Patch YouMute persistent mute"
perl -0777 -i -pe 's~%group Muted\n\n%hook YTSingleVideoController\n\n- \(void\)setMuted:\(BOOL\)muted \{\n    %orig\(shouldMute\(\)\);\n\}\n\n%end\n\n%end\n~%group Muted\n\n%hook YTSingleVideoController\n\n- (void)setMuted:(BOOL)muted {\n    %orig(shouldMute());\n\n    dispatch_async(dispatch_get_main_queue(), ^{\n        %orig(shouldMute());\n    });\n\n    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{\n        %orig(shouldMute());\n    });\n}\n\n- (void)play {\n    %orig;\n\n    dispatch_async(dispatch_get_main_queue(), ^{\n        [self setMuted:shouldMute()];\n    });\n\n    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{\n        [self setMuted:shouldMute()];\n    });\n}\n\n%end\n\n%end\n~s' YouMute/Tweak.x

echo "==> Verify YouMute patch"
grep -n "void)play" YouMute/Tweak.x
grep -n "dispatch_after" YouMute/Tweak.x

# YouChooseQuality Patch
echo "==> Patch YouChooseQuality defaults"
python3 <<'PY'
from pathlib import Path
import textwrap
import sys

file = Path("YouChooseQuality/Settings.x")
if not file.is_file():
    print("Missing YouChooseQuality/Settings.x")
    sys.exit(1)

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
    print("Already patched")
PY

# Gonerino Patch
#echo "==> Patch Gonerino default button visibility"
#[ -f Gonerino/sources/Tweak.x ] || { echo "Missing Gonerino/sources/Tweak.x"; exit 1; }
#[ -f Gonerino/sources/Settings.x ] || { echo "Missing Gonerino/sources/Settings.x"; exit 1; }
#perl -0pi -e 's/\? YES(\s*:\s*\[\[NSUserDefaults standardUserDefaults\] boolForKey:@"GonerinoShowButton"\])/\? NO$1/g' Gonerino/sources/Tweak.x
#perl -0pi -e 's/\? YES(\s*:\s*\[\[NSUserDefaults standardUserDefaults\] boolForKey:@"GonerinoShowButton"\])/\? NO$1/g' Gonerino/sources/Settings.x
