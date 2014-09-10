//
//  AskViewController.m
//  AskApp
//
//  Created by Toxa on 23/07/14.
//
//

#import "AskViewController.h"

@interface AskViewController ()
@property (strong, nonatomic) IBOutlet UITextView *textQuestion;

@end

@implementation AskViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

- (IBAction)askQuestion:(id)sender {
    NSString *text = [self.textQuestion.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (text.length < 1) {
        [UIAlertView showAlertViewWithTitle:@"Need more information" message:@"Your question is too short" cancelButtonTitle:@"OK" otherButtonTitles:nil];
        return;
    }
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    HTTPClient *client = [HTTPClient sharedClient];
    [client POST:@"/ask" parameters:@{@"question":text} success:^(NSURLSessionDataTask *task, id responseObject) {
        if (responseObject[@"error"]) {
            [SVProgressHUD dismiss];
            [UIAlertView showAlertViewWithTitle:@"Error" message: responseObject[@"error"] cancelButtonTitle:@"OK" otherButtonTitles:nil];
        }
        else {
            [SVProgressHUD showSuccessWithStatus:@"Question asked"];
            int n = [[AppDelegate sharedApp].profile[@"points"] intValue];
            [AppDelegate sharedApp].profile[@"points"] = @(n - POINTS_TO_ASK);
            self.textQuestion.text = @"";
            self.tabBarController.selectedIndex = 2;
        }        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        if (response.statusCode == 403) {
            [SVProgressHUD dismiss];
            [[AppDelegate sharedApp] handle403];
        }
        else
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"HTTP error code %ld", (long)response.statusCode]];
    }];
}

@end
