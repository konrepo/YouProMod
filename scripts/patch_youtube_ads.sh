#!/usr/bin/env bash
set -euo pipefail

echo "==> Patch YouMod Ads"

python3 <<'PY'
from pathlib import Path
import re

file = Path("YouMod/Files/Ads.x")
if not file.is_file():
    print("Missing YouMod/Files/Ads.x")
    exit(1)

text = file.read_text()

# Add extra ad strings
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
    '@"medium_rectangle",',
    '@"search_pyv",',
    '@"instream",',
    '@"visit_advertiser",',
    '@"learn_more",',
    '@"call_to_action_button",',
    '@"advertiser",',
]

anchor = '        @"brand_promo",'
if '@"adSlotRenderer",' not in text and anchor in text:
    insert = "\n".join("        " + s for s in extra_strings) + "\n"
    text = text.replace(anchor, insert + anchor, 1)

# Replace isAdRenderer
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

    if ([elementRenderer respondsToSelector:@selector(hasCompatibilityOptions)] &&
        elementRenderer.hasCompatibilityOptions &&
        elementRenderer.compatibilityOptions.hasAdLoggingData) {
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
        [description containsString:@"shopping_ad"] ||
        [description containsString:@"sponsored"] ||
        [description containsString:@"ad_badge"] ||
        [description containsString:@"simple_ad_badge"] ||
        [description containsString:@"medium_rectangle"] ||
        [description containsString:@"search_pyv"] ||
        [description containsString:@"instream"] ||
        [description containsString:@"visit_advertiser"] ||
        [description containsString:@"learn_more"] ||
        [description containsString:@"call_to_action_button"] ||
        [description containsString:@"cta"] ||
        [description containsString:@"advertiser"]) {
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

# Replace final firstObject check
old2 = '''        YTIItemSectionSupportedRenderers *firstObject = [contentsArray firstObject];
        YTIElementRenderer *elementRenderer = firstObject.elementRenderer;
        return isAdRenderer(elementRenderer, 2);'''

new2 = '''        NSString *sectionDesc = [[sectionRenderer description] lowercaseString];

        if ([sectionDesc containsString:@"sponsored"] ||
            [sectionDesc containsString:@"ad_badge"] ||
            [sectionDesc containsString:@"simple_ad_badge"] ||
            [sectionDesc containsString:@"adslot"] ||
            [sectionDesc containsString:@"ad_slot"] ||
            [sectionDesc containsString:@"feed_ad"] ||
            [sectionDesc containsString:@"in_feed_ad"] ||
            [sectionDesc containsString:@"inline_content_ad"] ||
            [sectionDesc containsString:@"promoted_sparkles"] ||
            [sectionDesc containsString:@"paid_content"] ||
            [sectionDesc containsString:@"call_to_action"] ||
            [sectionDesc containsString:@"medium_rectangle"] ||
            [sectionDesc containsString:@"search_pyv"] ||
            [sectionDesc containsString:@"instream"] ||
            [sectionDesc containsString:@"visit_advertiser"] ||
            [sectionDesc containsString:@"learn_more"] ||
            [sectionDesc containsString:@"call_to_action_button"] ||
            [sectionDesc containsString:@"cta"] ||
            [sectionDesc containsString:@"advertiser"]) {
            return YES;
        }

        if (contentsArray.count == 0) {
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
            [desc containsString:@"sponsored"] ||
            [desc containsString:@"ad_badge"] ||
            [desc containsString:@"simple_ad_badge"] ||
            [desc containsString:@"shopping_ad"] ||
            [desc containsString:@"paid_content"] ||
            [desc containsString:@"call_to_action"] ||
            [desc containsString:@"medium_rectangle"] ||
            [desc containsString:@"search_pyv"] ||
            [desc containsString:@"instream"] ||
            [desc containsString:@"visit_advertiser"] ||
            [desc containsString:@"learn_more"] ||
            [desc containsString:@"call_to_action_button"] ||
            [desc containsString:@"cta"] ||
            [desc containsString:@"advertiser"]) {
            return YES;
        }

        return isAdRenderer(elementRenderer, 2);'''

if old2 in text:
    text = text.replace(old2, new2, 1)
else:
    print("Warning: firstObject block not found or already changed")

# Remove UI hiding hook to avoid blank white space
as_hook = r'''%hook _ASDisplayView
- (void)didMoveToWindow {
    %orig;
    if ([self.accessibilityIdentifier isEqualToString:@"eml.expandable_metadata.vpp"]) [self removeFromSuperview];
    if ([self.accessibilityIdentifier isEqualToString:@"eml.ad_layout.full_width_square_image_layout"]) self.hidden = YES;
}
%end
'''
text = text.replace(as_hook, "")

# Add YTSectionListViewController hook
section_hook = r'''
%hook YTSectionListViewController

- (void)loadWithModel:(YTISectionListRenderer *)model {
    NSMutableArray *contentsArray = model.contentsArray;

    NSIndexSet *removeIndexes = [contentsArray indexesOfObjectsPassingTest:^BOOL(id renderers, NSUInteger idx, BOOL *stop) {
        id sectionRenderer = [renderers respondsToSelector:@selector(itemSectionRenderer)] ? [renderers itemSectionRenderer] : nil;
        NSMutableArray *sectionContents = [sectionRenderer respondsToSelector:@selector(contentsArray)] ? [sectionRenderer contentsArray] : nil;
        id firstObject = [sectionContents firstObject];

        if (!firstObject) return NO;

        return ([firstObject respondsToSelector:@selector(hasPromotedVideoRenderer)] && [firstObject hasPromotedVideoRenderer]) ||
               ([firstObject respondsToSelector:@selector(hasCompactPromotedVideoRenderer)] && [firstObject hasCompactPromotedVideoRenderer]) ||
               ([firstObject respondsToSelector:@selector(hasPromotedVideoInlineMutedRenderer)] && [firstObject hasPromotedVideoInlineMutedRenderer]);
    }];

    [contentsArray removeObjectsAtIndexes:removeIndexes];

    %orig;
}

%end
'''

if "%hook YTSectionListViewController" not in text:
    text += "\n" + section_hook

# Add hard elementData block
element_hook = r'''
%hook YTIElementRenderer

- (NSData *)elementData {
    if ([self respondsToSelector:@selector(hasCompatibilityOptions)] &&
        self.hasCompatibilityOptions &&
        self.compatibilityOptions.hasAdLoggingData) {
        return nil;
    }

    return %orig;
}

%end
'''

if "%hook YTIElementRenderer" not in text:
    text += "\n" + element_hook

file.write_text(text)
print("Patched YouMod Ads")
PY

echo "==> YouMod Ads patch complete"
