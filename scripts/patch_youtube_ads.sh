#!/usr/bin/env bash
set -euo pipefail

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

echo "==> YouMod Ads patch complete"
