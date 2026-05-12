#!/usr/bin/env bash
set -euo pipefail

echo "==> Patch YouMod Ads"

python3 <<'PY'
from pathlib import Path

file = Path("YouMod/Files/Ads.x")
if not file.is_file():
    print("Missing YouMod/Files/Ads.x")
    exit(1)

text = file.read_text()

# 1. Remove fragile UI-level hiding (causes white gaps)
as_hook = '''%hook _ASDisplayView
- (void)didMoveToWindow {
    %orig;
    if ([self.accessibilityIdentifier isEqualToString:@"eml.expandable_metadata.vpp"]) [self removeFromSuperview];
    if ([self.accessibilityIdentifier isEqualToString:@"eml.ad_layout.full_width_square_image_layout"]) self.hidden = YES;
}
%end
'''
text = text.replace(as_hook, "")

# 2. Strong renderer detection (keep minimal + stable)
old_renderer = '''static BOOL isAdRenderer(YTIElementRenderer *elementRenderer, int kind) {
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

new_renderer = '''static BOOL isAdRenderer(YTIElementRenderer *elementRenderer, int kind) {
    if (!elementRenderer) return NO;

    if ([elementRenderer respondsToSelector:@selector(hasCompatibilityOptions)] &&
        elementRenderer.hasCompatibilityOptions &&
        elementRenderer.compatibilityOptions.hasAdLoggingData) {
        return YES;
    }

    NSString *description = [[elementRenderer description] lowercaseString];
    NSString *adString = getAdString(description);

    if (adString ||
        [description containsString:@"adslot"] ||
        [description containsString:@"ad_slot"] ||
        [description containsString:@"feed_ad"] ||
        [description containsString:@"sponsored"] ||
        [description containsString:@"promoted"] ||
        [description containsString:@"paid_content"] ||
        [description containsString:@"shopping_ad"]) {
        return YES;
    }

    return NO;
}'''

if old_renderer in text:
    text = text.replace(old_renderer, new_renderer, 1)

# 3. Fix section filtering (remove empty + ad sections safely)
old_first = '''        YTIItemSectionSupportedRenderers *firstObject = [contentsArray firstObject];
        YTIElementRenderer *elementRenderer = firstObject.elementRenderer;
        return isAdRenderer(elementRenderer, 2);'''

new_first = '''        if (contentsArray.count == 0) {
            return YES;
        }

        NSString *sectionDesc = [[sectionRenderer description] lowercaseString];
        if ([sectionDesc containsString:@"sponsored"] ||
            [sectionDesc containsString:@"adslot"] ||
            [sectionDesc containsString:@"ad_slot"] ||
            [sectionDesc containsString:@"feed_ad"] ||
            [sectionDesc containsString:@"promoted"] ||
            [sectionDesc containsString:@"paid_content"] ||
            [sectionDesc containsString:@"shopping_ad"]) {
            return YES;
        }

        YTIItemSectionSupportedRenderers *firstObject = [contentsArray firstObject];
        if (!firstObject || !firstObject.elementRenderer) {
            return YES;
        }

        YTIElementRenderer *elementRenderer = firstObject.elementRenderer;
        return isAdRenderer(elementRenderer, 2);'''

if old_first in text:
    text = text.replace(old_first, new_first, 1)

# 4. Hard block ads at data level
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

# 5. Section-level promoted ads (YTPlusM method)
# https://github.com/Mark02-2012/YTPlusM
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

file.write_text(text)
print("Patched YouMod Ads")
PY

echo "==> YouMod Ads patch complete"
