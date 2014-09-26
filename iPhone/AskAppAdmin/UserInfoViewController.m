//
//  UserInfoViewController.m
//  AskAppAdmin
//
//  Created by Toxa on 24/09/14.
//  Copyright (c) 2014 BanzaiTokyo. All rights reserved.
//

#import "UserInfoViewController.h"
#import "AppDelegate.h"
#import "ModerationTableViewController.h"

@interface UserInfoViewController ()
@property (weak, nonatomic) IBOutlet UILabel *email;
@property (weak, nonatomic) IBOutlet UILabel *registeredon;
@property (weak, nonatomic) IBOutlet UILabel *points;
@property (weak, nonatomic) IBOutlet UILabel *questions;
@property (weak, nonatomic) IBOutlet UILabel *answers;

@end

@implementation UserInfoViewController {
    NSMutableDictionary *profile;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    HTTPClient *client = [HTTPClient sharedClient];
    NSString *url = [NSString stringWithFormat: @"/userinfo?userid=%@", self.userid];
    [client GET:url parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        [SVProgressHUD dismiss];
        if (responseObject[@"email"]) {
            profile = [responseObject mutableCopy];
            profile[@"questions"] = [profile[@"questions"] mutableCopy];
            profile[@"answers"] = [profile[@"answers"] mutableCopy];
            self.email.text = profile[@"email"];
            self.registeredon.text = profile[@"registeredon"];
            self.points.text = [profile[@"points"] stringValue];
            self.questions.text = [profile[@"questions"][@"total"] stringValue];
            self.answers.text = [profile[@"answers"][@"total"] stringValue];
        }
        else {
            NSString *errorMessage = @"Error";
            if (responseObject[@"error"])
                errorMessage = responseObject[@"error"];
            [UIAlertView showAlertViewWithTitle:@"Error" message: errorMessage cancelButtonTitle:@"OK" otherButtonTitles:nil];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [SVProgressHUD dismiss];
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        if (response.statusCode == 403) {
            [[AppDelegate sharedApp] handle403];
        }
        else
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"HTTP error code %ld", (long)response.statusCode]];
    }];
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ModerationTableViewController *vc = (ModerationTableViewController *)segue.destinationViewController;
    vc.profile = profile;
    vc.workWithAnswers = [segue.identifier isEqualToString:@"answers"];
}

@end
