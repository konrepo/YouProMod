#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <math.h>

static BOOL YouProQualitySheetVisible = NO;

static NSString *YouProNormalizeDigits(NSString *text) {
    if (![text isKindOfClass:[NSString class]] || text.length == 0) return text;

    NSDictionary *map = @{
        @"٠": @"0", @"١": @"1", @"٢": @"2", @"٣": @"3", @"٤": @"4",
        @"٥": @"5", @"٦": @"6", @"٧": @"7", @"٨": @"8", @"٩": @"9",
        @"۰": @"0", @"۱": @"1", @"۲": @"2", @"۳": @"3", @"۴": @"4",
        @"۵": @"5", @"۶": @"6", @"۷": @"7", @"۸": @"8", @"۹": @"9"
    };

    for (NSString *key in map) {
        text = [text stringByReplacingOccurrencesOfString:key withString:map[key]];
    }

    return text;
}

static NSString *YouProResolutionFromText(NSString *text) {
    if (![text isKindOfClass:[NSString class]] || text.length == 0) return nil;

    NSString *lower = text.lowercaseString;

    if ([lower containsString:@"4k"] || [lower containsString:@"2160p"]) return @"4K";
    if ([lower containsString:@"1440p"]) return @"1440p";
    if ([lower containsString:@"1080p"]) return @"1080p";
    if ([lower containsString:@"720p"]) return @"720p";
    if ([lower containsString:@"480p"]) return @"480p";
    if ([lower containsString:@"360p"]) return @"360p";
    if ([lower containsString:@"240p"]) return @"240p";
    if ([lower containsString:@"144p"]) return @"144p";

    return nil;
}

static BOOL YouProHasResolutionMarker(NSString *text) {
    return YouProResolutionFromText(text) != nil;
}

static NSString *YouProFormatFromText(NSString *text) {
    if (![text isKindOfClass:[NSString class]] || text.length == 0) return nil;

    NSString *lower = text.lowercaseString;

    if ([lower containsString:@"webm"]) return @"webM";
    if ([lower containsString:@"mp4"]) return @"mp4";

    NSString *resolution = YouProResolutionFromText(text);
    if ([resolution isEqualToString:@"4K"] || [resolution isEqualToString:@"1440p"]) {
        return @"webM";
    }

    if (resolution.length > 0) {
        return @"mp4";
    }

    return nil;
}

static BOOL YouProIsDownloadText(NSString *text) {
    if (![text isKindOfClass:[NSString class]] || text.length == 0) return NO;
    return [text isEqualToString:@"تنزيل"] || [text isEqualToString:@"Download"];
}

static BOOL YouProIsCancelText(NSString *text) {
    if (![text isKindOfClass:[NSString class]] || text.length == 0) return NO;
    return [text isEqualToString:@"إلغاء"] || [text isEqualToString:@"Cancel"];
}

static NSString *YouProEnglishify(NSString *text) {
    if (![text isKindOfClass:[NSString class]] || text.length == 0) return text;

    text = YouProNormalizeDigits(text);
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    text = [text stringByReplacingOccurrencesOfString:@"صوت" withString:@"Audio"];
    text = [text stringByReplacingOccurrencesOfString:@"فيديو" withString:@"Video"];
    text = [text stringByReplacingOccurrencesOfString:@"م.ب" withString:@"MB"];

    if ([text containsString:@"تم الحفظ في الصور"]) return @"Saved";
    if ([text containsString:@"تم الحفظ"]) return @"Saved";
    if ([text containsString:@"الدمج"]) return @"Merging...";

    NSString *resolution = YouProResolutionFromText(text);
    if (resolution) {
        return resolution;
    }

    if ([text containsString:@"جودة التنزيل"]) return @"Download Quality (ខ្មែរ)";
    if (YouProIsDownloadText(text)) return @"Download";
    if (YouProIsCancelText(text)) return @"Cancel";

    if ([text containsString:@"MB"]) {
        NSScanner *scanner = [NSScanner scannerWithString:text];
        double value = 0;

        if ([scanner scanDouble:&value]) {
            if (value >= 1024.0) {
                double gb = value / 1024.0;
                if (fmod(gb, 1.0) == 0) {
                    return [NSString stringWithFormat:@"%.0f GB", gb];
                } else {
                    return [NSString stringWithFormat:@"%.1f GB", gb];
                }
            } else {
                return [NSString stringWithFormat:@"%.0f MB", value];
            }
        }
    }

    return text;
}

static NSString *YouProPaddedQualityText(NSString *text) {
    if (![text isKindOfClass:[NSString class]] || text.length == 0) return text;

    NSString *resolution = YouProResolutionFromText(text);
    if (!resolution) return text;

    NSString *format = YouProFormatFromText(text);
    if (!format) return resolution;

    NSInteger targetWidth = 8;
    NSInteger padCount = targetWidth - resolution.length;
    if (padCount < 1) padCount = 1;

    NSMutableString *spaces = [NSMutableString string];
    for (NSInteger i = 0; i < padCount; i++) {
        [spaces appendString:@" "];
    }

    return [NSString stringWithFormat:@"%@%@%@", resolution, spaces, format];
}

static NSString *YouProAddFormatIfMissing(NSString *text) {
    return YouProPaddedQualityText(text);
}

static NSAttributedString *YouProStyledQualityText(NSString *text, UIFont *font) {
    if (![text isKindOfClass:[NSString class]] || text.length == 0) return nil;

    NSString *finalText = YouProPaddedQualityText(text);
    if (!YouProHasResolutionMarker(finalText)) return nil;

    UIFont *useFont = font ?: [UIFont systemFontOfSize:17.0];

    NSMutableAttributedString *attr =
        [[NSMutableAttributedString alloc] initWithString:finalText
                                               attributes:@{
        NSFontAttributeName: useFont,
        NSForegroundColorAttributeName: [UIColor blackColor]
    }];

    NSError *error = nil;
    NSRegularExpression *regex =
        [NSRegularExpression regularExpressionWithPattern:@"\\b(mp4|webm)\\b"
                                                  options:NSRegularExpressionCaseInsensitive
                                                    error:&error];
    if (error) return attr;

    NSArray<NSTextCheckingResult *> *matches =
        [regex matchesInString:finalText options:0 range:NSMakeRange(0, finalText.length)];

    for (NSTextCheckingResult *match in matches) {
        if (match.range.location != NSNotFound && match.range.length > 0) {
            [attr addAttribute:NSForegroundColorAttributeName
                         value:[UIColor redColor]
                         range:match.range];
        }
    }

    return attr;
}

static void YouProSetPlainButtonTitle(UIButton *button, NSString *title) {
    if (![button isKindOfClass:[UIButton class]] || title.length == 0) return;

    NSArray *states = @[
        @(UIControlStateNormal),
        @(UIControlStateHighlighted),
        @(UIControlStateSelected),
        @(UIControlStateDisabled)
    ];

    for (NSNumber *stateNumber in states) {
        UIControlState state = (UIControlState)[stateNumber unsignedIntegerValue];
        [button setAttributedTitle:nil forState:state];
        [button setTitle:title forState:state];
    }
}

static void YouProApplyLabelFix(UILabel *label) {
    if (![label isKindOfClass:[UILabel class]]) return;

    NSString *raw = nil;
    if (label.attributedText.length > 0) {
        raw = label.attributedText.string;
    } else {
        raw = label.text;
    }

    if (![raw isKindOfClass:[NSString class]] || raw.length == 0) return;

    NSString *fixed = YouProEnglishify(raw);
    if (!fixed.length) return;

    if (YouProHasResolutionMarker(raw) || YouProHasResolutionMarker(fixed)) {
        NSAttributedString *styled = YouProStyledQualityText(raw, label.font);
        if (styled) {
            label.attributedText = styled;
            return;
        }
    }

    if (![raw isEqualToString:fixed]) {
        label.text = fixed;
    }
}

static void YouProApplyButtonFix(UIButton *button) {
    if (![button isKindOfClass:[UIButton class]]) return;

    NSString *currentTitle = button.currentTitle;
    NSString *fixedCurrent = currentTitle ? YouProEnglishify(currentTitle) : @"";

    if (YouProIsDownloadText(currentTitle) || YouProIsDownloadText(fixedCurrent)) {
        YouProSetPlainButtonTitle(button, @"Download");
        return;
    }

    if (YouProIsCancelText(currentTitle) || YouProIsCancelText(fixedCurrent)) {
        YouProSetPlainButtonTitle(button, @"Cancel");
        return;
    }

    NSArray *states = @[
        @(UIControlStateNormal),
        @(UIControlStateHighlighted),
        @(UIControlStateSelected),
        @(UIControlStateDisabled)
    ];

    for (NSNumber *stateNumber in states) {
        UIControlState state = (UIControlState)[stateNumber unsignedIntegerValue];

        NSString *title = [button titleForState:state];
        if ([title isKindOfClass:[NSString class]] && title.length > 0) {
            NSString *fixed = YouProEnglishify(title);

            if (YouProHasResolutionMarker(title) || YouProHasResolutionMarker(fixed)) {
                NSAttributedString *styled = YouProStyledQualityText(title, button.titleLabel.font);
                if (styled) {
                    [button setAttributedTitle:styled forState:state];
                }
            } else if (![title isEqualToString:fixed]) {
                [button setTitle:fixed forState:state];
            }
        }

        NSAttributedString *attrTitle = [button attributedTitleForState:state];
        if (attrTitle.length > 0) {
            NSString *raw = attrTitle.string;
            NSString *fixed = YouProEnglishify(raw);

            if (YouProHasResolutionMarker(raw) || YouProHasResolutionMarker(fixed)) {
                NSAttributedString *styled = YouProStyledQualityText(raw, button.titleLabel.font);
                if (styled) {
                    [button setAttributedTitle:styled forState:state];
                }
            } else if (![raw isEqualToString:fixed]) {
                NSMutableAttributedString *newAttr =
                    [[NSMutableAttributedString alloc] initWithAttributedString:attrTitle];
                [newAttr replaceCharactersInRange:NSMakeRange(0, newAttr.length) withString:fixed];
                [button setAttributedTitle:newAttr forState:state];
            }
        }
    }
}

static void YouProFixViewTexts(UIView *view) {
    if (!view || !YouProQualitySheetVisible) return;

    if ([view isKindOfClass:[UILabel class]]) {
        YouProApplyLabelFix((UILabel *)view);
    } else if ([view isKindOfClass:[UIButton class]]) {
        YouProApplyButtonFix((UIButton *)view);
    }

    for (UIView *subview in view.subviews) {
        YouProFixViewTexts(subview);
    }
}

%hook YouPro_DownloadManager

- (NSString *)arabicQualityLabel:(NSString *)label {
    NSString *result = %orig;
    NSString *fixed = YouProEnglishify(result);

    if (YouProHasResolutionMarker(result) || YouProHasResolutionMarker(fixed)) {
        return YouProAddFormatIfMissing(result);
    }

    return fixed;
}

%end

%hook UILabel

- (void)setText:(NSString *)text {
    NSString *fixed = YouProEnglishify(text);

    if (YouProQualitySheetVisible &&
        (YouProHasResolutionMarker(text) || YouProHasResolutionMarker(fixed))) {
        NSAttributedString *styled = YouProStyledQualityText(text, self.font);
        if (styled) {
            [self setAttributedText:styled];
            return;
        }
    }

    %orig(fixed);
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    if (attributedText.length > 0) {
        NSString *raw = attributedText.string;
        NSString *fixed = YouProEnglishify(raw);

        if (YouProQualitySheetVisible &&
            (YouProHasResolutionMarker(raw) || YouProHasResolutionMarker(fixed))) {
            NSAttributedString *styled = YouProStyledQualityText(raw, self.font);
            if (styled) {
                %orig(styled);
                return;
            }
        }

        if (fixed && ![fixed isEqualToString:raw]) {
            NSMutableAttributedString *newAttr =
                [[NSMutableAttributedString alloc] initWithAttributedString:attributedText];
            [newAttr replaceCharactersInRange:NSMakeRange(0, newAttr.length) withString:fixed];
            %orig(newAttr);
            return;
        }
    }

    %orig;
}

%end

%hook YouProQualitySheet

- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);
    YouProQualitySheetVisible = YES;
    YouProFixViewTexts([(UIViewController *)self view]);
}

- (void)viewDidAppear:(BOOL)animated {
    %orig(animated);

    YouProQualitySheetVisible = YES;

    UIView *rootView = [(UIViewController *)self view];
    YouProFixViewTexts(rootView);

    @try {
        UIButton *dlBtn = [(id)self valueForKey:@"dlBtn"];
        if ([dlBtn isKindOfClass:[UIButton class]]) {
            YouProSetPlainButtonTitle(dlBtn, @"Download");
        }

        UIButton *canBtn = [(id)self valueForKey:@"canBtn"];
        if ([canBtn isKindOfClass:[UIButton class]]) {
            YouProSetPlainButtonTitle(canBtn, @"Cancel");
        }
    } @catch (__unused NSException *e) {
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        YouProFixViewTexts(rootView);
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        YouProFixViewTexts(rootView);
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        YouProFixViewTexts(rootView);
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig(animated);
    YouProQualitySheetVisible = NO;
}

- (void)viewDidLayoutSubviews {
    %orig;
    YouProFixViewTexts([(UIViewController *)self view]);
}

- (void)dealloc {
    YouProQualitySheetVisible = NO;
    %orig;
}

%end
