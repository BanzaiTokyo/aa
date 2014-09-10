//
//  ReportViewController.m
//  AskApp
//
//  Created by Toxa on 20/08/14.
//
//

#import "ReportViewController.h"

@interface ReportViewController ()
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *reasons;
@property (weak, nonatomic) IBOutlet UITextView *question;
@property (weak, nonatomic) IBOutlet UITextView *reason;

@end

@implementation ReportViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.question.text = self.questionText;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)selectReason:(id)sender {
    for (UIButton *b in self.reasons)
        b.selected = NO;
    ((UIButton *)sender).selected = YES;
    self.reason.editable = [self.reasons indexOfObject:sender] == self.reasons.count-1;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

- (IBAction)sendReport:(id)sender {
    NSMutableDictionary *params = [@{@"question":@(self.questionIdx)} mutableCopy];
    NSInteger reasonIdx = self.reasons.count;
    for (int i=0; i < self.reasons.count; i++)
        if (((UIButton *)self.reasons[i]).selected) {
            reasonIdx = i;
            break;
        }
    if (reasonIdx >= 0 && reasonIdx < self.reasons.count - 1)
        params[@"reason"] = [((UIButton *)self.reasons[reasonIdx]) titleForState:UIControlStateNormal];
    else if ([self.reason.text length] && reasonIdx == self.reasons.count - 1)
        params[@"reason"] = self.reason.text;
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    HTTPClient *client = [HTTPClient sharedClient];
    [client POST:@"/refuse" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        if (responseObject[@"error"])
            [SVProgressHUD showErrorWithStatus:responseObject[@"error"]];
        else {
            [SVProgressHUD showSuccessWithStatus:@"Question reported"];
            [AppDelegate sharedApp].profile = [responseObject mutableCopy];
            UIViewController *vc = self.navigationController.viewControllers[self.navigationController.viewControllers.count-2];
            if ([vc isKindOfClass:[UITableViewController class]])
                [((UITableViewController *)vc).tableView reloadData];
            [self.navigationController popViewControllerAnimated:YES];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
