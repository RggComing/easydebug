//
//  EZDDisplayer.m
//  easydebug
//
//  Created by Song on 2018/8/21.
//

#import "EZDDisplayer.h"

#import "EZDMenuViewController.h"

#import "EZDAppShortInfoLabel.h"

#import "EZDDefine.h"
#import "EZDDebugServer.h"
#import "EZDSystemUtil.h"

#import "UIViewController+EZDAddition.h"
#import "UIView+EZDAddition_frame.h"

static EZDDisplayer *displayer;
static UIImage *EZDIconImage = nil;

@interface EZDDisplayer()

@property (weak,nonatomic) UIWindow *curWindow;

@property (nonatomic, strong) UIButton *displayerSwitch;
@property (strong,nonatomic) EZDAppShortInfoLabel *fpsLabel;

@property (nonatomic, strong) UIImage *icon;

@end

@implementation EZDDisplayer

#if EZDEBUG_DEBUGLOG
+ (instancetype)setupDisplayerWithWindow:(UIWindow *)window{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        displayer = [[self alloc] initWithWindow:window];
    });
    return displayer;
}

+ (void)showFPSLabel:(bool)show{
    displayer.fpsLabel.hidden = !show;
}

+ (void)setToolIcon:(UIImage *)icon {
    EZDIconImage = icon;

    if (displayer && icon) {
        [displayer.displayerSwitch setImage:icon forState:UIControlStateNormal];
    }
}

#pragma mark - life circle
- (instancetype)initWithWindow:(UIWindow *)window{
    if (self = [super init]) {
        [self setupBaseUI];
        [self tryToAddToWindow:window];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    }
    return self;
}

- (void)tryToAddToWindow:(UIWindow *)window{
    if (!window) {
        if ([EZDSystemUtil currentWindow]) {
            window = [EZDSystemUtil currentWindow];
            [[UIApplication sharedApplication] addObserver:self forKeyPath:@"keyWindow" options:(NSKeyValueObservingOptionNew) context:nil];
        }else{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self tryToAddToWindow:window];
            });
        }
    }
    
    if (window) {
        [self setupToWindow:window];
    }
}

- (void)dealloc{
    [[UIApplication sharedApplication] removeObserver:self forKeyPath:@"keyWindow"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupBaseUI{
    self.fpsLabel = [[EZDAppShortInfoLabel alloc] initWithFrame:CGRectMake(0, ([UIScreen mainScreen].bounds.size.height - 34), 0, 0)];
    self.fpsLabel.hidden = [[[NSUserDefaults alloc] initWithSuiteName:kEZDUserDefaultSuiteName] boolForKey:@"kEZDOptionHideFPSLabelKey"];
    
    self.displayerSwitch = [UIButton buttonWithType:UIButtonTypeCustom];
    self.displayerSwitch.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.displayerSwitch.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    self.displayerSwitch.contentHorizontalAlignment = UIControlContentVerticalAlignmentFill;
    
    UIImage *icon;
    if (!EZDIconImage) {
        NSURL *bundleURL = [[NSBundle bundleForClass:[self
                                                        class]] URLForResource:@"easydebug_asset.bundle" withExtension:@""];
        NSBundle *easydebugBundle = [NSBundle bundleWithURL:bundleURL];
        NSString *iconPath = [easydebugBundle pathForResource:@"tool.jpg" ofType:@""];

        icon = [UIImage imageWithContentsOfFile:iconPath];
    } else {
        icon = EZDIconImage;
    }
    
    [self.displayerSwitch setImage:icon forState:UIControlStateNormal];
    [self.displayerSwitch addTarget:self action:@selector(displayerSwitchClicked) forControlEvents:UIControlEventTouchUpInside];
    self.displayerSwitch.ezd_size = CGSizeMake(60, 60);
}

#pragma mark - UI funcs
- (void)setupToWindow:(UIWindow *)window{
    if (!window || [window isEqual:self.curWindow]) {
        return;
    }
    
    self.curWindow = window;
    [self.curWindow addSubview:self.displayerSwitch];
    [self.curWindow addSubview:self.fpsLabel];
    
    self.displayerSwitch.ezd_origin = CGPointMake(window.ezd_width * .1, window.ezd_height - displayer.displayerSwitch.ezd_height * .4);
    
    [EZDDebugServer startServerWithPort:8081];
}

#pragma mark - private funcs
- (void)showDisplayer{
    EZDMenuViewController *displayController = [[EZDMenuViewController alloc] initWithLogger:self.logger];
    [UIViewController presentIfCanWithController:displayController needNavigationController:true];
}

#pragma mark - response funcs
- (void)displayerSwitchClicked{
    static BOOL comeOut = false;
    if (!comeOut) {
        comeOut = true;
        [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.displayerSwitch.ezd_y -= self.displayerSwitch.ezd_height * .6;
        } completion:^(BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:.25 animations:^{
                    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;
                    CGFloat targetY = self.displayerSwitch.ezd_y + self.displayerSwitch.ezd_height * .6;
                    if (targetY < screenH) {
                        self.displayerSwitch.ezd_y = targetY;
                    } else {
                        self.displayerSwitch.ezd_y = screenH - self.displayerSwitch.ezd_height * .6;
                    }
                } completion:^(BOOL finished) {
                    comeOut = false;
                }];
            });
        }];
    }else{
        [self showDisplayer];
    }
}

- (void)keyboardChange:(NSNotification *)note{
    
    CGRect frame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;
    if (frame.origin.y < screenH) {
        self.displayerSwitch.ezd_y = frame.origin.y - 40;
    } else {
        self.displayerSwitch.ezd_y = screenH - self.displayerSwitch.ezd_height * .4;
    }
}

#pragma mark - observer
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"keyWindow"]) {
        [self setupToWindow:[EZDSystemUtil currentWindow]];
    }
}

#else
+ (instancetype)setupDisplayerWithWindow:(UIWindow *)window{return nil;}
+ (void)setToolIcon:(UIImage *)image {}
+ (void)showFPSLabel:(bool)show {}

#endif

@end
