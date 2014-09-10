//
//  LoginRegisterViewController.m
//  AskApp
//
//  Created by Toxa on 23/07/14.
//
//

#import "LoginRegisterViewController.h"

@interface LoginRegisterViewController ()
@property (strong, nonatomic) IBOutlet UITextField *email;
@property (strong, nonatomic) IBOutlet UITextField *password;
@property (strong, nonatomic) IBOutlet UITextField *nickname;

@end

@implementation LoginRegisterViewController

- (void)viewDidAppear:(BOOL)animated {
    [self.email becomeFirstResponder];
}

- (IBAction)goSignUp:(id)sender {
    UIViewController *parent = self.presentingViewController;
    id vc = [self.storyboard instantiateViewControllerWithIdentifier:@"Register"];
    [self dismissViewControllerAnimated:NO completion:nil];
    [parent presentViewController:vc animated:NO completion:nil];
}

- (IBAction)goLogin:(id)sender {
    UIViewController *parent = self.presentingViewController;
    id vc = [self.storyboard instantiateViewControllerWithIdentifier:@"Login"];
    [self dismissViewControllerAnimated:NO completion:nil];
    [parent presentViewController:vc animated:NO completion:nil];
}

- (IBAction)login:(id)sender {
    NSMutableDictionary *params = [@{@"email": self.email.text,
                                     @"password": self.password.text,
                                     @"deviceIdentifier": [AppDelegate sharedApp].deviceIdentifier,
                                    } mutableCopy];
    if ([AppDelegate sharedApp].deviceToken)
        params[@"deviceToken"] = [AppDelegate sharedApp].deviceToken;
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    [[HTTPClient sharedClient] POST:@"/login" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        [SVProgressHUD dismiss];
        if (responseObject[@"email"]) {
            [AppDelegate sharedApp].profile = [responseObject mutableCopy];
            [self dismissViewControllerAnimated:YES completion:nil];
            return;
        }
        NSString *errorMessage = @"Error";
        if (responseObject[@"error"])
            errorMessage = responseObject[@"error"];
        [UIAlertView showAlertViewWithTitle:@"Error" message: errorMessage cancelButtonTitle:@"OK" otherButtonTitles:nil];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"HTTP error code %ld", (long)response.statusCode]];
    }];
}

- (IBAction)signup:(id)sender {
    NSString *nickname = [self.nickname.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *email = [self.email.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *password = [self.password.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (nickname.length == 0) {
        [UIAlertView showAlertViewWithTitle:@"Need more information" message:@"Please provide your nickname" cancelButtonTitle:@"OK" otherButtonTitles:nil];
        return;
    }
    if (email.length == 0) {
        [UIAlertView showAlertViewWithTitle:@"Need more information" message:@"Please provide your email" cancelButtonTitle:@"OK" otherButtonTitles:nil];
        return;
    }
    if (![self isValidEmail]) {
        [UIAlertView showAlertViewWithTitle:@"Need more information" message:@"Please provide a valid email address" cancelButtonTitle:@"OK" otherButtonTitles:nil];
        return;
    }
    if (password.length == 0) {
        [UIAlertView showAlertViewWithTitle:@"Need more information" message:@"Please provide a password of 6 characters or more" cancelButtonTitle:@"OK" otherButtonTitles:nil];
        return;
    }
    
    NSMutableDictionary *params = [@{@"nickname": self.nickname.text,
                             @"email": self.email.text,
                             @"password": self.password.text,
                             @"deviceIdentifier": [AppDelegate sharedApp].deviceIdentifier,
                                     } mutableCopy];
    if ([AppDelegate sharedApp].deviceToken)
        params[@"deviceToken"] = [AppDelegate sharedApp].deviceToken;
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    [[HTTPClient sharedClient] POST:@"/register" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        [SVProgressHUD dismiss];
        if (responseObject[@"email"]) {
            [AppDelegate sharedApp].profile = [responseObject mutableCopy];
            [self dismissViewControllerAnimated:YES completion:nil];
            return;
        }
        NSString *errorMessage = @"Error";
        if (responseObject[@"error"])
            errorMessage = responseObject[@"error"];
        [UIAlertView showAlertViewWithTitle:@"Error" message: errorMessage cancelButtonTitle:@"OK" otherButtonTitles:nil];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"HTTP error code %ld", (long)response.statusCode]];
    }];
}

-(BOOL) isValidEmail {
    BOOL stricterFilter = YES; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:self.email.text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.password) {
        if (self.nickname) //only signup VC has this field
            [self signup:nil];
        else
            [self login:nil];
    }
    return YES;
}
@end
