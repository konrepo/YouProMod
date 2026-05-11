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
echo "==> Patch YouMute"
[ -f YouMute/Tweak.x ] || { echo "Missing YouMute/Tweak.x"; exit 1; }

cat > YouMute/Tweak.x <<'EOF'
#import "../YTVideoOverlay/Header.h"
#import "../YTVideoOverlay/Init.x"
#import <YouTubeHeader/QTMIcon.h>
#import <YouTubeHeader/YTColor.h>
#import <YouTubeHeader/YTMainAppVideoPlayerOverlayViewController.h>
#import <YouTubeHeader/YTSingleVideoController.h>

#define TweakKey @"YouMute"
#define KeepMutedKey @"YouMuteKeepMuted"

@interface YTMainAppControlsOverlayView (YouMute)
- (void)didPressMute:(id)arg;
@end

@interface YTInlinePlayerBarContainerView (YouMute)
- (void)didPressMute:(id)arg;
@end

static BOOL isMutedTop(YTMainAppControlsOverlayView *self) {
    YTMainAppVideoPlayerOverlayViewController *c = [self valueForKey:@"_eventsDelegate"];
    YTSingleVideoController *video = [c valueForKey:@"_currentSingleVideoObservable"];
    return [video isMuted];
}

static BOOL isMutedBottom(YTInlinePlayerBarContainerView *self) {
    YTSingleVideoController *video = [self.delegate valueForKey:@"_currentSingleVideo"];
    return [video isMuted];
}

static BOOL shouldMute() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:KeepMutedKey];
}

static UIImage *muteImage(BOOL muted) {
    return [%c(QTMIcon) imageWithName:muted ? @"ic_volume_off" : @"ic_volume_up" color:[%c(YTColor) white1]];
}

%group Muted

%hook YTSingleVideoController

- (void)setMuted:(BOOL)muted {
    %orig(muted);

    if (shouldMute() && !muted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            %orig(YES);
        });

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            %orig(YES);
        });
    }
}

- (void)play {
    %orig;

    if (shouldMute()) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setMuted:YES];
        });

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self setMuted:YES];
        });
    }
}

%end

%end

%group Top

%hook YTMainAppControlsOverlayView

- (UIImage *)buttonImage:(NSString *)tweakId {
    return [tweakId isEqualToString:TweakKey] ? muteImage(isMutedTop(self)) : %orig;
}

%new(v@:@)
- (void)didPressMute:(id)arg {
    YTMainAppVideoPlayerOverlayViewController *c = [self valueForKey:@"_eventsDelegate"];
    YTSingleVideoController *video = [c valueForKey:@"_currentSingleVideoObservable"];

    BOOL muteStatus = ![video isMuted];

    [[NSUserDefaults standardUserDefaults] setBool:muteStatus forKey:KeepMutedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [video setMuted:muteStatus];

    [self.overlayButtons[TweakKey] setImage:muteImage(muteStatus) forState:UIControlStateNormal];
}

%end

%end

%group Bottom

%hook YTInlinePlayerBarContainerView

- (UIImage *)buttonImage:(NSString *)tweakId {
    return [tweakId isEqualToString:TweakKey] ? muteImage(isMutedBottom(self)) : %orig;
}

%new(v@:@)
- (void)didPressMute:(id)arg {
    YTSingleVideoController *video = [self.delegate valueForKey:@"_currentSingleVideo"];

    BOOL muteStatus = ![video isMuted];

    [[NSUserDefaults standardUserDefaults] setBool:muteStatus forKey:KeepMutedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [video setMuted:muteStatus];

    [self.overlayButtons[TweakKey] setImage:muteImage(muteStatus) forState:UIControlStateNormal];
}

%end

%end

%ctor {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([defaults objectForKey:KeepMutedKey] == nil) {
        [defaults setBool:YES forKey:KeepMutedKey];
        [defaults synchronize];
    }

    [defaults registerDefaults:@{
        @"YTVideoOverlay-YouMute-Enabled": @YES,
        KeepMutedKey: @YES
    }];

    initYTVideoOverlay(TweakKey, @{
        AccessibilityLabelKey: @"Mute",
        SelectorKey: @"didPressMute:",
        UpdateImageOnVisibleKey: @YES
    });

    %init(Muted);
    %init(Top);
    %init(Bottom);
}
EOF

echo "==> Verify YouMute patch"
grep -n "void)play" YouMute/Tweak.x
grep -n "YTVideoOverlay-YouMute-Enabled" YouMute/Tweak.x
grep -n "KeepMutedKey" YouMute/Tweak.x

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
import re

file = Path("YouMod/Files/Settings.x")
if not file.is_file():
    print("Missing YouMod/Files/Settings.x")
    exit(1)

text = file.read_text()

# Remove previously injected defaults to avoid duplicate keys
for key in [
    "ForceMiniPlayer",
    "GestureControls",
    "HideShortsShelf",
    "GestureHUD",
    "HidePaidPromoOverlay",
    "DownloadManager",
    "DownloadSaveToPhotos",
]:
    text = re.sub(rf"\n\s*{key}: @(YES|NO),", "", text)

# Set OldQualityPicker default OFF
text = text.replace("OldQualityPicker: @YES,", "OldQualityPicker: @NO,", 1)

# Insert custom defaults after OldQualityPicker
anchor = "OldQualityPicker: @NO,"
insert = """OldQualityPicker: @NO,
        ForceMiniPlayer: @YES,
        GestureControls: @YES,
        HideShortsShelf: @YES,
        GestureHUD: @YES,
        HidePaidPromoOverlay: @YES,
        DownloadManager: @NO,
        DownloadSaveToPhotos: @NO,"""

if anchor in text:
    text = text.replace(anchor, insert, 1)
    file.write_text(text)
    print("Patched YouMod defaults")
else:
    print("Anchor not found")
    exit(1)
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
        ForceMiniPlayer: @YES,
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

# YouMod Download menu - keep only video + audio
echo "==> Patch YouMod Download menu"

python3 <<'PY'
from pathlib import Path
import re

file = Path("YouMod/Files/Download.x")
if not file.is_file():
    print("Missing Download.x")
    exit(1)

text = file.read_text()

patterns = [
    r'\s*\[items addObject:\[YouModMenuItem itemWithTitle:@"Download captions".*?\]\];',
    r'\s*\[items addObject:\[YouModMenuItem itemWithTitle:@"Copy diagnostics".*?\]\];',
    r'\s*\[items addObject:\[YouModMenuItem itemWithTitle:@"Save thumbnail".*?\]\];',
    r'\s*\[items addObject:\[YouModMenuItem itemWithTitle:@"Copy video information".*?\]\];',
]

for pattern in patterns:
    text = re.sub(pattern, '', text, flags=re.S)

# Add Khmer header row above Download video
if 'itemWithTitle:@"ខ្មែរ"' not in text:
    text = text.replace(
        '[items addObject:[YouModMenuItem itemWithTitle:@"Download video"',
        '[items addObject:[YouModMenuItem itemWithTitle:@"🇰🇭  ខ្មែរ" subtitle:@"" icon:nil handler:nil]];\n\n'
        '    [items addObject:[YouModMenuItem itemWithTitle:@"Download video"'
    )

# Silence unused helper functions after removing menu items
unused_helpers = [
    "YouModCopyDownloadDiagnostics",
    "YouModDownloadThumbnail",
    "YouModCopyVideoInfo",
    "YouModShowCaptionsSheet",
]

for name in unused_helpers:
    text = text.replace(
        f"static void {name}(",
        f"static __attribute__((unused)) void {name}("
    )

# Silence unused videoID only in Download Manager
text = text.replace(
    '    NSString *videoID = YouModVideoIDForPlayer(player);\n'
    '    NSMutableArray *items = [NSMutableArray array];',
    '    NSString *videoID = YouModVideoIDForPlayer(player);\n'
    '    (void)videoID;\n'
    '    NSMutableArray *items = [NSMutableArray array];'
)

file.write_text(text)
print("Patched Download menu")
PY

# YouMod Ads - improve feed ad filtering
echo "==> Patch YouMod Ads feed filters"

python3 <<'PY'
from pathlib import Path

file = Path("YouMod/Files/Ads.x")
if not file.is_file():
    print("Missing YouMod/Files/Ads.x")
    exit(1)

text = file.read_text()

extra_strings = [
    '@"adSlotRenderer",',
    '@"ad_slot_renderer",',
    '@"promoted",',
    '@"promoted_video",',
    '@"promotedVideo",',
    '@"sparkles_web_rendering_layout",',
    '@"in_feed_ad",',
    '@"inline_content_ad",',
    '@"compact_promoted_item",',
    '@"promoted_sparkles",',
    '@"paid_content_overlay",',
    '@"adBreakRenderer",',
    '@"ad_break_renderer",',
]

anchor = '        @"brand_promo",'
if '@"adSlotRenderer",' not in text and anchor in text:
    insert = "\n".join("        " + s for s in extra_strings) + "\n"
    text = text.replace(anchor, insert + anchor, 1)

old = '''%hook _ASDisplayView
- (void)didMoveToWindow {
    %orig;
    if ([self.accessibilityIdentifier isEqualToString:@"eml.expandable_metadata.vpp"]) [self removeFromSuperview];
    if ([self.accessibilityIdentifier isEqualToString:@"eml.ad_layout.full_width_square_image_layout"]) self.hidden = YES;
}
%end'''

new = '''%hook _ASDisplayView
- (void)didMoveToWindow {
    %orig;

    NSString *identifier = self.accessibilityIdentifier ?: @"";

    if ([identifier containsString:@"ad_layout"] ||
        [identifier containsString:@"promoted"] ||
        [identifier containsString:@"sparkles"] ||
        [identifier containsString:@"feed_ad"] ||
        [identifier isEqualToString:@"eml.expandable_metadata.vpp"]) {
        self.hidden = YES;
        [self removeFromSuperview];
    }
}
%end'''

if old in text:
    text = text.replace(old, new, 1)
else:
    print("Warning: _ASDisplayView block not found or already changed")

file.write_text(text)
print("Patched YouMod Ads feed filters")
PY

# YouMod Ads - collapse blank feed ad spaces
echo "==> Patch YouMod Ads blank-space removal"

python3 <<'PY'
from pathlib import Path

file = Path("YouMod/Files/Ads.x")
if not file.is_file():
    print("Missing YouMod/Files/Ads.x")
    exit(1)

text = file.read_text()

# Strengthen isAdRenderer detection
old = '''static BOOL isAdRenderer(YTIElementRenderer *elementRenderer, int kind) {
    if ([elementRenderer respondsToSelector:@selector(hasCompatibilityOptions)] && elementRenderer.hasCompatibilityOptions && elementRenderer.compatibilityOptions.hasAdLoggingData) {
        return YES;
    }
    NSString *description = [elementRenderer description];
    NSString *adString = getAdString(description);
    if (adString) {
        return YES;
    }
    return NO;
}'''

new = '''static BOOL isAdRenderer(YTIElementRenderer *elementRenderer, int kind) {
    if (!elementRenderer) return NO;

    if ([elementRenderer respondsToSelector:@selector(hasCompatibilityOptions)] && elementRenderer.hasCompatibilityOptions && elementRenderer.compatibilityOptions.hasAdLoggingData) {
        return YES;
    }

    NSString *description = [[elementRenderer description] lowercaseString];

    if ([description containsString:@"adslot"] ||
        [description containsString:@"ad_slot"] ||
        [description containsString:@"feed_ad"] ||
        [description containsString:@"in_feed_ad"] ||
        [description containsString:@"inline_content_ad"] ||
        [description containsString:@"promoted"] ||
        [description containsString:@"sparkles"] ||
        [description containsString:@"paid_content"] ||
        [description containsString:@"shopping_ad"]) {
        return YES;
    }

    NSString *adString = getAdString(description);
    if (adString) {
        return YES;
    }

    return NO;
}'''

if old in text:
    text = text.replace(old, new, 1)
else:
    print("Warning: isAdRenderer block not found or already changed")

# Remove item sections that become empty after ad filtering
old2 = '''        YTIItemSectionSupportedRenderers *firstObject = [contentsArray firstObject];
        YTIElementRenderer *elementRenderer = firstObject.elementRenderer;
        return isAdRenderer(elementRenderer, 2);'''

new2 = '''        if (contentsArray.count == 0) {
            return YES;
        }

        YTIItemSectionSupportedRenderers *firstObject = [contentsArray firstObject];
        if (!firstObject || !firstObject.elementRenderer) {
            return YES;
        }

        YTIElementRenderer *elementRenderer = firstObject.elementRenderer;

        NSString *desc = [[elementRenderer description] lowercaseString];

        if ([desc containsString:@"adslot"] ||
            [desc containsString:@"ad_slot"] ||
            [desc containsString:@"feed_ad"] ||
            [desc containsString:@"in_feed_ad"] ||
            [desc containsString:@"inline_content_ad"] ||
            [desc containsString:@"promoted"] ||
            [desc containsString:@"sparkles"] ||
            [desc containsString:@"shopping_ad"] ||
            [desc containsString:@"paid_content"]) {
            return YES;
        }

        return isAdRenderer(elementRenderer, 2);'''

if old2 in text:
    text = text.replace(old2, new2, 1)
else:
    print("Warning: empty-section removal anchor not found or already changed")

file.write_text(text)
print("Patched YouMod Ads blank-space removal")
PY

echo "==> Patch step complete"
