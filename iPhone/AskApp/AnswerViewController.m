//
//  AnswerViewController.m
//  AskApp
//
//  Created by Toxa on 23/07/14.
//
//

#import "AnswerViewController.h"
#import "QuestionsViewController.h"

@interface AnswerViewController ()<UITableViewDataSource, UITableViewDelegate> {
    NSDictionary *question;
}
@property (strong, nonatomic) IBOutlet UILabel *textQuestion;
@property (weak, nonatomic) IBOutlet UIView *answerView;
@property (strong, nonatomic) IBOutlet UITextView *textAnswer;
@property (weak, nonatomic) IBOutlet UIButton *btnSend;
@property (weak, nonatomic) IBOutlet UITableView *answersTable;
@end

@implementation AnswerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    question = [AppDelegate sharedApp].profile[@"questions"][self.questionIdx];
    self.textQuestion.text = question[@"question"];
    if ([question[@"status"] isEqualToString:@"new"])
        return;
    self.answerView.hidden = YES;
    self.answersTable.hidden = NO;
    [self.answersTable reloadData];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController)
        [((QuestionsViewController *)self.navigationController.topViewController) showQuestion];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    self.btnSend.enabled = textView.text.length > 0;    
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
            [self viewDidLoad];
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

#pragma mark - Table Data Source

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [question[@"answers"] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.textLabel.text = question[@"answers"][indexPath.row][@"answer"];
    cell.contentView.layer.borderWidth = 3;
    cell.contentView.layer.borderColor = [UIColor groupTableViewBackgroundColor].CGColor;
    /*cell.contentView.layer.masksToBounds = YES;
    cell.contentView.layer.cornerRadius = 10;
    cell.backgroundColor = [UIColor whiteColor];
    cell.backgroundView.layer.masksToBounds = YES;
    cell.backgroundView.layer.cornerRadius = 10;*/
    return cell;
}

@end
