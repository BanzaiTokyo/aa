//
//  AppDelegate.m
//  AskApp
//
//  Created by Toxa on 22/07/14.
//
//

#import "AppDelegate.h"
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import "MyQuestionsTableViewController.h"
#import "SingleQuestionViewController.h"
#import "SingleAnswerViewController.h"
#import "HomeViewController.h"
#import "QuestionsViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeAlert)];
    self.deviceIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSDictionary *remotePayload = launchOptions[@"UIApplicationLaunchOptionsRemoteNotificationKey"];
	if (remotePayload) {
        _handlingPushMessage = YES;
        [self handleRemoteNotification:remotePayload fromLaunch:YES];
    }
    else
        _handlingPushMessage = NO;
    
   return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    self.deviceToken = [[[deviceToken description]
                                    stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]]
                                   stringByReplacingOccurrencesOfString:@" "
                                   withString:@""];
    [self registerDeviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	NSLog(@"Error registering device: %@", error);
}

- (void)registerDeviceToken {
    NSMutableDictionary *params =
        [@{@"deviceToken": self.deviceToken,
          @"deviceIdentifier": self.deviceIdentifier} mutableCopy];
    if (self.profile[@"email"])
        params[@"email"] = self.profile[@"email"];
    [[HTTPClient sharedClient] POST:@"/registerdevice" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        ;
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        ;
    }];

}

- (void)handleRemoteNotification:(NSDictionary *)userInfo fromLaunch:(BOOL)fromLaunch {
    [AppDelegate clearCookies];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    HTTPClient *client = [HTTPClient sharedClient];
    [client GET:@"/singleanswer" parameters:@{@"id": userInfo[@"custom"]} success:^(NSURLSessionDataTask *task, id responseObject) {
        _handlingPushMessage = NO;
        [SVProgressHUD dismiss];
        if (!responseObject[@"profile"] || !responseObject[@"question"])
            return;
        
        //[UIAlertView showAlertViewWithTitle:@"singleanswer" message:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        self.profile = [responseObject[@"profile"] mutableCopy];
        SingleQuestionViewController *sqvc;
        SingleAnswerViewController *savc;
        UITabBarController *tabController = (UITabBarController *)self.window.rootViewController;
        if (tabController.selectedViewController.presentedViewController)
            [tabController.selectedViewController.presentedViewController dismissViewControllerAnimated:NO completion:nil];
        tabController.selectedIndex = 2;
        UINavigationController *navController = (UINavigationController *)tabController.selectedViewController;
        [navController popToRootViewControllerAnimated:NO];
        if ([NSStringFromClass([navController.topViewController class]) isEqualToString:@"HomeViewController"]) {
            MyQuestionsTableViewController *vc = (MyQuestionsTableViewController *)[tabController.storyboard instantiateViewControllerWithIdentifier:@"MyQuestions"];
            [navController pushViewController:vc animated:NO];
        }
        if ([NSStringFromClass([navController.topViewController class]) isEqualToString:@"MyQuestionsTableViewController"]) {
            [navController.topViewController viewDidLoad];
            sqvc = (SingleQuestionViewController *)[tabController.storyboard instantiateViewControllerWithIdentifier:@"SingleQuestion"];
            sqvc.question = responseObject[@"question"];
            [navController pushViewController:sqvc animated:NO];
        }
        else if ([NSStringFromClass([navController.topViewController class]) isEqualToString:@"SingleQuestionViewController"]) {
            sqvc = (SingleQuestionViewController *)navController.topViewController;
            sqvc.question = responseObject[@"question"];
            [sqvc viewDidLoad];
        }
        if (!responseObject[@"answer"])
            return;
        if ([NSStringFromClass([navController.topViewController class]) isEqualToString:@"SingleQuestionViewController"]) {
            savc = (SingleAnswerViewController *)[tabController.storyboard instantiateViewControllerWithIdentifier:@"SingleAnswer"];
            savc.answer = [responseObject[@"answer"] mutableCopy];
            [navController pushViewController:savc animated:NO];
        }
        else if ([NSStringFromClass([navController.topViewController class]) isEqualToString:@"SingleAnswerViewController"]) {
            savc = (SingleAnswerViewController *)navController.topViewController;
            savc.answer = [responseObject[@"answer"] mutableCopy];
            [savc viewDidLoad];
            [savc.view setNeedsLayout];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        _handlingPushMessage = NO;
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        if (response.statusCode == 403) {
            [SVProgressHUD dismiss];
            [self handle403];
        }
        else
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"HTTP error code %ld", (long)response.statusCode]];
    }];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [self handleRemoteNotification:userInfo fromLaunch:NO];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return YES;
}

+ (AppDelegate*)sharedApp {
    return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

+ (CGFloat)heightForText:(NSString *)text andFont:(UIFont *)font forSize:(CGSize)size {
    CGRect textRect = [text boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil];
    return textRect.size.height;
}

+ (void)adjustLabelHeight:(UILabel *)l minHeight:(CGFloat)minHeight forSize:(CGSize)size {
    CGRect r = l.frame;
    r.size.height = [self heightForText:l.text andFont:l.font forSize:size];
    r.size.height = MAX(r.size.height, minHeight);
    l.frame = r;
}

+ (void)clearCookies {
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [storage cookies]) {
        [storage deleteCookie:cookie];
    }
}

- (void)handle403 {
    if (_handlingPushMessage)
        return;
    UITabBarController *tb = (UITabBarController *)self.window.rootViewController;
    [((UINavigationController *)tb.viewControllers[0]) popToRootViewControllerAnimated:NO];
    [((UINavigationController *)tb.viewControllers[2]) popToRootViewControllerAnimated:NO];
    id presenter, vc = [tb.storyboard instantiateViewControllerWithIdentifier:@"Login"];
    if ([tb.selectedViewController isKindOfClass:[UINavigationController class]])
        presenter = ((UINavigationController *)tb.selectedViewController).viewControllers[0];
    else
        presenter = tb.selectedViewController;
    [presenter presentViewController:vc animated:YES completion:nil];
}
@end

@implementation HTTPClient

+(instancetype)sharedClient {
    static HTTPClient *_sharedClient = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //_sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:@"http://localhost:8080"]];
        _sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:@"http://aaask-app.appspot.com"]];
    });
    
    return _sharedClient;
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    
    if (self) {
        self.responseSerializer = [AFJSONResponseSerializer serializer];
        self.requestSerializer = [AFJSONRequestSerializer serializer];
    }
    
    return self;
}
@end

@implementation UIAlertView (BanzaiTokyo)

+ (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSArray *)otherButtonTitles {
	// If no buttons were specified, cancel button becomes "Dismiss"
	if (!cancelButtonTitle.length && !otherButtonTitles.count)
		cancelButtonTitle = @"Dismiss";
	
	UIAlertView *alertView = [[[self class] alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
    
	// Set other buttons
	[otherButtonTitles enumerateObjectsUsingBlock:^(NSString *button, NSUInteger idx, BOOL *stop) {
		[alertView addButtonWithTitle:button];
	}];
    
	// Show alert view
	[alertView show];
}

@end

@implementation NSNull (BanzaiTokyo)
- (NSInteger)length {
    return 0;
}
- (NSInteger)count {
    return 0;
}
@end

@implementation NSDate (BanzaiTokyo)
-(NSDate *) toLocalTime {
    NSTimeZone *tz = [NSTimeZone localTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate: self];
    return [NSDate dateWithTimeInterval: seconds sinceDate: self];
}
-(NSDate *) toGlobalTime {
    NSTimeZone *tz = [NSTimeZone localTimeZone];
    NSInteger seconds = -[tz secondsFromGMTForDate: self];
    return [NSDate dateWithTimeInterval: seconds sinceDate: self];
}
@end