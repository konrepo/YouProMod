#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <math.h>

static BOOL IsArabicSize(NSString *text) {
    if (![text isKindOfClass:[NSString class]]) return NO;
    return [text containsString:@"م.ب"] || [text containsString:@"ب.م"];
}

static BOOL IsDownloadQualityTitle(NSString *text) {
    if (![text isKindOfClass:[NSString class]]) return NO;
    return [text isEqualToString:@"Download Quality"];
}

static NSString *FixSize(NSString *text) {
    if (!IsArabicSize(text)) return text;

    NSDictionary *map = @{
        @"٠": @"0", @"١": @"1", @"٢": @"2", @"٣": @"3", @"٤": @"4",
        @"٥": @"5", @"٦": @"6", @"٧": @"7", @"٨": @"8", @"٩": @"9",
        @"۰": @"0", @"۱": @"1", @"۲": @"2", @"۳": @"3", @"۴": @"4",
        @"۵": @"5", @"۶": @"6", @"۷": @"7", @"۸": @"8", @"۹": @"9"
    };

    for (NSString *k in map) {
        text = [text stringByReplacingOccurrencesOfString:k withString:map[k]];
    }

    text = [text stringByReplacingOccurrencesOfString:@"م.ب" withString:@"MB"];
    text = [text stringByReplacingOccurrencesOfString:@"ب.م" withString:@"MB"];

    NSRegularExpression *regex =
        [NSRegularExpression regularExpressionWithPattern:@"([0-9]+(?:\\.[0-9]+)?)"
                                                  options:0
                                                    error:nil];

    NSTextCheckingResult *match =
        [regex firstMatchInString:text options:0 range:NSMakeRange(0, text.length)];

    if (!match) return text;

    double value = [[text substringWithRange:match.range] doubleValue];

    if (value >= 1024.0) {
        double gb = value / 1024.0;
        return (fmod(gb, 1.0) == 0)
            ? [NSString stringWithFormat:@"%.0f GB", gb]
            : [NSString stringWithFormat:@"%.1f GB", gb];
    }

    return (fmod(value, 1.0) == 0)
        ? [NSString stringWithFormat:@"%.0f MB", value]
        : [NSString stringWithFormat:@"%.1f MB", value];
}

static BOOL IsArabicDownloadText(NSString *text) {
    if (![text isKindOfClass:[NSString class]]) return NO;
    NSString *trim = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [trim isEqualToString:@"تنزيل"];
}

%hook UILabel

- (void)setText:(NSString *)text {
    if (IsArabicSize(text)) {
        text = FixSize(text);
    } else if (IsDownloadQualityTitle(text)) {
        text = @"🇰🇭 ខ្មែរ";
    }
    %orig(text);
}

%end

%hook UIButton

- (void)setTitle:(NSString *)title forState:(UIControlState)state {
    if (IsArabicDownloadText(title)) {
        title = @"Download";
    }
    %orig(title, state);
}

%end
