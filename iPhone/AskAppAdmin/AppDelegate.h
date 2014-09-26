//
//  AppDelegate.h
//  AskAppAdmin
//
//  Created by Toxa on 18/09/14.
//  Copyright (c) 2014 BanzaiTokyo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AFNetworking/AFHTTPSessionManager.h>
#import <SVProgressHUD.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) NSMutableDictionary *profile;
@property (strong, nonatomic) NSString *deviceToken;
@property (strong, nonatomic) NSString *deviceIdentifier;
@property (nonatomic) BOOL handlingPushMessage;

+ (AppDelegate*)sharedApp;
+ (CGFloat)heightForText:(NSString *)text andFont:(UIFont *)font forSize:(CGSize)size;
+ (void)adjustLabelHeight:(UILabel *)l minHeight:(CGFloat)minHeight forSize:(CGSize)size;
+ (void)clearCookies;
- (void)handle403;
@end

@interface HTTPClient: AFHTTPSessionManager
+ (instancetype)sharedClient;
- (instancetype)initWithBaseURL:(NSURL *)url;
@end

@interface UIAlertView (BanzaiTokyo)
+ (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSArray *)otherButtonTitles;
@end

@interface NSString(BanzaiTokyo)
-(NSString *)stringValue;
@end