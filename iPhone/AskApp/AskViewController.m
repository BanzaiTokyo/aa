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
@property (weak, nonatomic) IBOutlet UILabel *textLength;
@property (weak, nonatomic) IBOutlet UIButton *btnAsk;

@end

@implementation AskViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textLength.text = [NSString stringWithFormat:@"%d", MAX_TEXT_LENGTH];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.textQuestion performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if (textView.text.length + text.length - range.length > MAX_TEXT_LENGTH)
        return NO;
    
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    self.btnAsk.enabled = textView.text.length > 0;
    self.textLength.text = [NSString stringWithFormat:@"%d", MAX_TEXT_LENGTH - self.textQuestion.text.length];
}

- (IBAction)askQuestion:(id)sender {
    NSString *text = [self.textQuestion.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
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
