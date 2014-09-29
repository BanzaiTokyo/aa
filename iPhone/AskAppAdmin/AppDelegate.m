//
//  AppDelegate.m
//  AskAppAdmin
//
//  Created by Toxa on 18/09/14.
//  Copyright (c) 2014 BanzaiTokyo. All rights reserved.
//

#import "AppDelegate.h"
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
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

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
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
    [@{@"device_token": self.deviceToken,
       @"device_identifier": self.deviceIdentifier,
       @"moderator": @(YES)} mutableCopy];
    [[HTTPClient sharedClient] POST:@"/registerdevice" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"%@", responseObject);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        NSLog(@"%@", response);
    }];
    
}

- (void)handleRemoteNotification:(NSDictionary *)userInfo fromLaunch:(BOOL)fromLaunch {
/*    [AppDelegate clearCookies];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    HTTPClient *client = [HTTPClient sharedClient];
 */
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [self handleRemoteNotification:userInfo fromLaunch:NO];
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
        _sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:@"http://localhost:8080"]];
        //_sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:@"http://aaask-app.appspot.com"]];
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

- (id)addDeviceIdentifier:(id)parameters {
    NSString *deviceIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    if (!parameters)
        return @{@"deviceIdentifier": deviceIdentifier};
    if ([parameters isKindOfClass:[NSDictionary class]]) {
        if (![parameters isKindOfClass:[NSMutableDictionary class]])
            parameters = [parameters mutableCopy];
        parameters[@"deviceIdentifier"] = deviceIdentifier;
    }
    return parameters;
}

- (NSURLSessionDataTask *)GET:(NSString *)URLString
                   parameters:(id)parameters
                      success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                      failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    parameters = [self addDeviceIdentifier:parameters];
    return [super GET:URLString parameters:parameters success:success failure:failure];
}

- (NSURLSessionDataTask *)HEAD:(NSString *)URLString
                    parameters:(id)parameters
                       success:(void (^)(NSURLSessionDataTask *task))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    parameters = [self addDeviceIdentifier:parameters];
    return [super HEAD:URLString parameters:parameters success:success failure:failure];
}

- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(id)parameters
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    parameters = [self addDeviceIdentifier:parameters];
    return [super POST:URLString parameters:parameters success:success failure:failure];
}

- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(id)parameters
     constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    parameters = [self addDeviceIdentifier:parameters];
    return [super POST:URLString parameters:parameters constructingBodyWithBlock:block success:success failure:failure];
}

- (NSURLSessionDataTask *)PUT:(NSString *)URLString
                   parameters:(id)parameters
                      success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                      failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    parameters = [self addDeviceIdentifier:parameters];
    return [super PUT:URLString parameters:parameters success:success failure:failure];
}

- (NSURLSessionDataTask *)PATCH:(NSString *)URLString
                     parameters:(id)parameters
                        success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                        failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    parameters = [self addDeviceIdentifier:parameters];
    return [super PATCH:URLString parameters:parameters success:success failure:failure];
}

- (NSURLSessionDataTask *)DELETE:(NSString *)URLString
                      parameters:(id)parameters
                         success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                         failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    parameters = [self addDeviceIdentifier:parameters];
    return [super DELETE:URLString parameters:parameters success:success failure:failure];
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

@implementation NSString(BanzaiTokyo)
-(NSString *)stringValue {
    return self;
}
@end