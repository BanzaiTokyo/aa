//
//  AnswerViewController.m
//  AskApp
//
//  Created by Toxa on 23/07/14.
//
//

#import "AnswerViewController.h"
#import "QuestionsViewController.h"

@interface AnswerViewController () {
    NSDictionary *question;
}
@property (strong, nonatomic) IBOutlet UITextView *textQuestion;
@property (strong, nonatomic) IBOutlet UITextView *textAnswer;
@end

@implementation AnswerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    question = [AppDelegate sharedApp].profile[@"questions"][self.questionIdx];
    self.textQuestion.text = question[@"question"];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

- (IBAction)answerQuestion:(id)sender {
    NSString *text = [self.textAnswer.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (text.length < 1) {
        [UIAlertView showAlertViewWithTitle:@"Need more information" message:@"Your question is too short" cancelButtonTitle:@"OK" otherButtonTitles:nil];
        return;
    }
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    HTTPClient *client = [HTTPClient sharedClient];
    NSDictionary *params = @{@"question": question[@"id"],
                             @"answer":text};
    [client POST:@"/answer" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        if (responseObject[@"error"]) {
            [SVProgressHUD dismiss];
            [UIAlertView showAlertViewWithTitle:@"Error" message: responseObject[@"error"] cancelButtonTitle:@"OK" otherButtonTitles:nil];
        }
        else {
            [SVProgressHUD showSuccessWithStatus:@"Answer accepted"];
            [AppDelegate sharedApp].profile = [responseObject mutableCopy];
        }
        [self.navigationController popViewControllerAnimated:YES];
        [((QuestionsViewController *)self.navigationController.topViewController) showQuestion];
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
