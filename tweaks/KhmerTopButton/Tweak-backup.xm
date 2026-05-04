// This use image logo .png

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface YTQTMButton : UIButton
+ (instancetype)barButtonWithImage:(UIImage *)image
                accessibilityLabel:(NSString *)label
           accessibilityIdentifier:(NSString *)identifier;
@end

@interface YTRightNavigationButtons : NSObject
- (void)setButton:(id)button forType:(int)type;
@end

@interface YTHeaderViewController : UIViewController
- (BOOL)isTopLevelPage;
@end

static const void *kKhmerTopButtonKey = &kKhmerTopButtonKey;

static NSBundle *KhmerTopButtonBundle(void) {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"KhmerTopButton" ofType:@"bundle"];
        if (!bundlePath) {
            bundlePath = @"/Library/Application Support/KhmerTopButton.bundle";
        }
        bundle = [NSBundle bundleWithPath:bundlePath];
    });
    return bundle;
}

static YTQTMButton *KhmerGetButton(id self) {
    return (YTQTMButton *)objc_getAssociatedObject(self, kKhmerTopButtonKey);
}

static void KhmerSetButton(id self, YTQTMButton *button) {
    objc_setAssociatedObject(self, kKhmerTopButtonKey, button, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static NSArray *KhmerFilterButtons(YTRightNavigationButtons *self, BOOL visibleOnly) {
    NSMutableArray *buttons = [NSMutableArray array];
    NSMapTable<NSNumber *, YTQTMButton *> *buttonsTable = [self valueForKey:@"_buttons"];

    for (NSNumber *key in buttonsTable) {
        YTQTMButton *button = [buttonsTable objectForKey:key];

        // HIDE SponsorBlock button
        if (key.intValue == 'ispb') {
            continue;
        }

        if (!visibleOnly || !button.hidden) {
            if (key.intValue == 'khtb') {
                if ([self valueForKey:@"_buttons"][key]) {
                    [buttons insertObject:button atIndex:0];
                }
            } else {
                [buttons addObject:button];
            }
        }
    }

    NSArray *dynamicButtons = [self valueForKey:@"_dynamicButtons"];
    for (YTQTMButton *button in dynamicButtons) {
        if (!visibleOnly || !button.hidden) {
            [buttons addObject:button];
        }
    }

    YTQTMButton *button7 = [buttonsTable objectForKey:@7];
    if (button7 && (!visibleOnly || !button7.hidden)) {
        [buttons addObject:button7];
    }

    return buttons;
}

%hook YTHeaderViewController

- (id)initWithParentResponder:(id)arg {
    self = %orig;
    if (!self) return self;

    UIImage *image = [UIImage imageNamed:@"KhmerLogo" inBundle:KhmerTopButtonBundle() compatibleWithTraitCollection:nil];
    if (!image) return self;

    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

    YTQTMButton *button = [%c(YTQTMButton)
        barButtonWithImage:image
        accessibilityLabel:@"Khmer"
        accessibilityIdentifier:@"khmerTopButton"];

    [button addTarget:self
               action:@selector(khmerTopButtonPressed:)
     forControlEvents:UIControlEventTouchUpInside];

    KhmerSetButton(self, button);

    YTRightNavigationButtons *rightButtons = [self valueForKey:@"_rightNavigationButtons"];
    [rightButtons setButton:button forType:'khtb'];

    return self;
}

- (void)setRightButtons {
    %orig;
    YTRightNavigationButtons *rightButtons = [self valueForKey:@"_rightNavigationButtons"];
    [rightButtons setButton:[self isTopLevelPage] ? KhmerGetButton(self) : nil forType:'khtb'];
}

%new(v@:@)
- (void)khmerTopButtonPressed:(UIButton *)sender {

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"TheDevilz"
                                                                   message:@"KhmerDub Site"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Open"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        NSURL *url = [NSURL URLWithString:@"https://khmerdrama.onrender.com/"];
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }]];

    [[[UIApplication sharedApplication] delegate].window.rootViewController presentViewController:alert animated:YES completion:nil];
}

%end

%hook NSUserDefaults

static BOOL YouProIsRotateKey(NSString *key) {
    if (![key isKindOfClass:[NSString class]]) return NO;

    NSString *lower = key.lowercaseString;

    return
        [lower containsString:@"rotate"] ||
        [lower containsString:@"rotation"] ||
        [lower containsString:@"landscape"] ||
        [lower containsString:@"autorotate"] ||
        [lower containsString:@"watchrotate"];
}

- (BOOL)boolForKey:(NSString *)key {
    if (YouProIsRotateKey(key)) {
        return YES;
    }
    return %orig;
}

- (id)objectForKey:(NSString *)key {
    if (YouProIsRotateKey(key)) {
        return @YES;
    }
    return %orig;
}

%end

%hook YTRightNavigationButtons
- (NSArray *)buttons {
    return KhmerFilterButtons(self, NO);
}
- (NSArray *)visibleButtons {
    return KhmerFilterButtons(self, YES);
}
%end

%ctor {
    %init;
}
