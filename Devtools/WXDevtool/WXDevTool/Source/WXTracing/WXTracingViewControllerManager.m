//
//  WXTracingViewController.m
//  TBWXDevTool
//
//  Created by 齐山 on 2017/7/4.
//  Copyright © 2017年 Taobao. All rights reserved.
//

#import "WXTracingViewControllerManager.h"
#import "UIButton+WXEnlargeArea.h"
#import "WXRenderTracingViewController.h"
#import "WXWindow.h"
#import "WXTracingLogImpl.h"
#import <WeexSDK/WXSDKEngine.h>
#import "WXTracingHomePageViewController.h"
#import "WXDebugger.h"
#import "WXTracingExceptionImpl.h"
#import "WXTracingImpl.h"

#define WXWeexButtonTag 1001

@interface WXTracingViewControllerManager ()<WXWindowEventDelegate>

@property(nonatomic,strong)WXTracingHomePageViewController *tracingVC;
@property(nonatomic,strong)UINavigationController *nav;
@property(nonatomic,strong) WXWindow *wind;
@property(nonatomic)BOOL isLoad;
@property(nonatomic)BOOL isLoadTracing;
@property(nonatomic)BOOL isShowButton;

@end

@implementation WXTracingViewControllerManager

+ (instancetype) sharedInstance{
    
    static WXTracingViewControllerManager *instance = nil;
    static dispatch_once_t once;
    
    dispatch_once(&once, ^{
        instance = [[WXTracingViewControllerManager alloc] init];
    });
    
    return instance;
}

//+ (void)load
//{
//    [self loadTracingView];
//}

+(void)showButton
{
    WXTracingViewControllerManager *manager = [WXTracingViewControllerManager sharedInstance];
    if(manager.isShowButton){
        return;
    }
    UIView *view = [manager.wind viewWithTag:WXWeexButtonTag];
    view.hidden = NO;
    if(view){
        manager.isShowButton = YES;
    }
}

+(void)loadTracingView
{
    [WXTracingManager switchTracing:YES];
    if(![WXTracingManager isTracing]) {
        return;
    }
    if(![WXTracingViewControllerManager sharedInstance].isLoad){
        [WXTracingViewControllerManager sharedInstance].isLoad = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [WXTracingViewControllerManager addWeexView];
            [WXLog registerExternalLog:[WXTracingLogImpl new]];
            [WXSDKEngine registerHandler:[WXTracingExceptionImpl new] withProtocol:@protocol(WXJSExceptionProtocol)];
            [WXSDKEngine registerHandler:[WXTracingImpl new] withProtocol:@protocol(WXTracingProtocol)];
        });
    }
}

+(BOOL)isLoadTracing
{
    return [WXTracingViewControllerManager sharedInstance].isLoadTracing;
}

+(void)addWeexView
{
    double delayInSeconds = 2.0;
    __weak __typeof__(self) weakSelf = self;
    dispatch_time_t delayInNanoSeconds =dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_queue_t concurrentQueue =dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_after(delayInNanoSeconds, concurrentQueue, ^(void){
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf addTracingView];

        });
    });
    
}

+(void)removeWeexView
{
    WXTracingViewControllerManager *instance = [WXTracingViewControllerManager sharedInstance];
    instance.wind.hidden = YES;
}

+(void)addTracingView
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 80, 20);
    [button setTitle:@"weex monitor" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:10.0];
    button.titleLabel.numberOfLines = 0;
    [button addTarget:self action:@selector(showTracing) forControlEvents:UIControlEventTouchUpInside];
    button.backgroundColor = [UIColor colorWithRed:1/255.0 green:140/255.0 blue:238/255.0 alpha:1.0];
    button.tag = WXWeexButtonTag;
    if([@"TB" isEqualToString:[[WXUtility getEnvironment] objectForKey:@"appName"]]){
        button.hidden = YES;
    }
    [button setEnlargeEdgeWithTop:20 right:20.0 bottom:0.0 left:20.0];
    WXTracingViewControllerManager *instance = [WXTracingViewControllerManager sharedInstance];
    instance.wind = [[WXWindow alloc]initWithFrame:CGRectMake(80, 0, 80, 20)];
    instance.wind.eventDelegate = instance;
    [instance.wind addSubview:button];
    instance.wind.windowLevel = UIWindowLevelStatusBar+100;
    instance.wind.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    instance.wind.userInteractionEnabled = YES;
    instance.wind.hidden = NO;
    //            [instance.wind makeKeyAndVisible];
    //            [instance.wind makeKeyWindow];
    [WXTracingViewControllerManager sharedInstance].textView = [UITextView new];
    [WXTracingViewControllerManager sharedInstance].messages = [NSMutableArray new];
    [WXTracingViewControllerManager sharedInstance].textView.font = [UIFont systemFontOfSize:16];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if(![defaults objectForKey:@"wxloglevel"]) {
        [defaults setObject:@(WXLogLevelLog) forKey:@"wxloglevel"];
        [defaults synchronize];
    }
    
    WXDebugger *debugger = [WXDebugger defaultInstance];
    [WXDebugger setEnabled:NO];//setting NO default
    if([WXDebugger isEnabled]){
        [debugger enableNetworkTrafficDebugging];
        [debugger forwardAllNetworkTraffic];
    }
}

+ (void)resetView
{
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 80, 20);
    [button setTitle:@"weex monitor" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:10.0];
    button.titleLabel.numberOfLines = 0;
    [button addTarget:self action:@selector(showTracing) forControlEvents:UIControlEventTouchUpInside];
    button.backgroundColor = [UIColor colorWithRed:1/255.0 green:140/255.0 blue:238/255.0 alpha:1.0];
    button.tag = WXWeexButtonTag;
    [button setEnlargeEdgeWithTop:20 right:20.0 bottom:0.0 left:20.0];
    WXTracingViewControllerManager *instance = [WXTracingViewControllerManager sharedInstance];
    instance.wind = [[WXWindow alloc]initWithFrame:CGRectMake(80, 0, 80, 20)];
    instance.wind.eventDelegate = instance;
    [instance.wind addSubview:button];
    instance.wind.windowLevel = UIWindowLevelStatusBar+100;
    instance.wind.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    instance.wind.userInteractionEnabled = YES;
    instance.wind.hidden = NO;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

+(void)showTracing
{
    
    if(![WXTracingViewControllerManager sharedInstance].isLoadTracing){
        [WXLog registerExternalLog:[WXTracingLogImpl new]];
        WXTracingViewControllerManager *manager = [WXTracingViewControllerManager sharedInstance];
        manager.wind.frame = [UIScreen mainScreen].bounds;
        UIView *view = [manager.wind viewWithTag:WXWeexButtonTag];
        view.frame = CGRectMake(80, 0, 80, 20);
        if(!manager.tracingVC){
            manager.tracingVC = [[WXTracingHomePageViewController alloc]init];
        }
        manager.nav = [[UINavigationController alloc] initWithRootViewController:manager.tracingVC];;
        manager.tracingVC.view.backgroundColor = [UIColor whiteColor];
        manager.wind.rootViewController = manager.nav;
        [manager.wind makeKeyAndVisible];
        [manager.nav setNavigationBarHidden:YES];
        manager.tracingVC.view.frame = CGRectMake(manager.wind.frame.origin.x, manager.wind.frame.origin.y+20, manager.wind.frame.size.width, manager.wind.frame.size.height-20);
        [manager.wind addSubview:manager.nav.view];
        manager.nav.view.frame = CGRectMake(manager.wind.frame.origin.x, manager.wind.frame.origin.y+20, manager.wind.frame.size.width, manager.wind.frame.size.height-20);
        manager.nav.view.backgroundColor = [UIColor whiteColor];
        [WXTracingViewControllerManager sharedInstance].isLoadTracing = YES;
    }else{
        WXTracingViewControllerManager *manager = [WXTracingViewControllerManager sharedInstance];
        [manager.tracingVC removeFromParentViewController];
        [manager.tracingVC.view removeFromSuperview];
        [manager.nav.view removeFromSuperview];
        manager.wind.frame = CGRectMake(80, 0, 80, 20);
        [manager.wind resignKeyWindow];
        [manager.wind removeFromSuperview];
        [self resetView];
        
//        UIView *view = [manager.wind viewWithTag:WXWeexButtonTag];
//        view.frame = CGRectMake(0, 0, 80, 20);
        [WXTracingViewControllerManager sharedInstance].isLoadTracing = NO;
    }
    
    
}

#pragma mark - WXWindowEventDelegate

- (BOOL)shouldHandleTouchAtPoint:(CGPoint)pointInWindow
{
    BOOL shouldReceiveTouch = YES;
    // Ask the explorer view controller
    UIView *view = [[WXTracingViewControllerManager sharedInstance].wind viewWithTag:WXWeexButtonTag];
    if (CGRectContainsPoint(view.frame, pointInWindow)) {
        shouldReceiveTouch = YES;
    }
    return shouldReceiveTouch;
}

- (BOOL)canBecomeKeyWindow
{
    // Only when the explorer view controller wants it because it needs to accept key input & affect
    // the status bar.
    return NO;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
