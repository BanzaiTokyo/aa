//
//  QuestionsTableViewController.m
//  AskApp
//
//  Created by Toxa on 13/08/14.
//
//

#import "QuestionsTableViewController.h"
#import "AnswerViewController.h"
#import "ReportViewController.h"

@implementation QuestionCell
@end

@interface QuestionsTableViewController ()<UIAlertViewDelegate> {
    NSArray *refuseReasons;
    NSDateFormatter *dateFormatter;
    NSTimer *timer;
}
@end

@implementation QuestionsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    refuseReasons = @[@"It's not in English", @"It's not a question", @"It's offensive", @"Not my expertise", @"Just remove it"];
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
}

- (void)viewWillAppear:(BOOL)animated {
    if (self.presentedViewController)
        return;
    if (![AppDelegate sharedApp].profile) {
        self.tableView.contentOffset = CGPointMake(0, -64);
        [self.refreshControl beginRefreshing];
        [self reloadQuestions:nil];
    }
    else if (self.needReloadAfterLogin) {
        [self.tableView reloadData];
        [self runTimer];
    }
    else {
        BOOL reloading = NO;
        for (NSDictionary *q in [AppDelegate sharedApp].profile[@"questions"]) {
            NSDate *d = [dateFormatter dateFromString: q[@"assignedon"]];
            NSTimeInterval dt = [d timeIntervalSinceNow];
            if (dt < -MAX_ANSWER_TIME) {
                self.tableView.contentOffset = CGPointMake(0, -64);
                [self.refreshControl beginRefreshing];
                [self reloadQuestions:self.refreshControl];
                reloading = YES;
                break;
            }
        }
        if (!reloading)
            [self runTimer];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [timer invalidate];
}

- (void)runTimer {
    if (![timer isValid])
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimer:) userInfo:nil repeats:YES];
}

#pragma mark - Table view data source
- (IBAction)reloadQuestions:(id)sender {
    [timer invalidate];
    NSString *url;
    if (sender)
        url = @"/refreshq";
    else //called if profile is not loaded in HomeViewController
        url = @"/profile";
    HTTPClient *client = [HTTPClient sharedClient];
    [client GET:url parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        [self.refreshControl endRefreshing];
        [self runTimer];
        if (responseObject[@"email"]) {
            [AppDelegate sharedApp].profile = [responseObject mutableCopy];
            self.needReloadAfterLogin = NO;
            [self.tableView reloadData];
        }
        else {
            NSString *errorMessage = @"Error";
            if (responseObject[@"error"])
                errorMessage = responseObject[@"error"];
            [UIAlertView showAlertViewWithTitle:@"Error" message: errorMessage cancelButtonTitle:@"OK" otherButtonTitles:nil];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [self.refreshControl endRefreshing];
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        if (response.statusCode == 403)
            [[AppDelegate sharedApp] handle403];
        else {
            [self runTimer];
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"HTTP error code %ld", (long)response.statusCode]];
        }
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *question = [[AppDelegate sharedApp].profile[@"questions"] objectAtIndex:indexPath.row];
    CGRect textRect = [question[@"question"] boundingRectWithSize:CGSizeMake(300, self.view.frame.size.height) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17.0]} context:nil];
    return tableView.rowHeight - 21 + textRect.size.height;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[AppDelegate sharedApp].profile[@"questions"] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    QuestionCell *cell = (QuestionCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    NSDictionary *question = [[AppDelegate sharedApp].profile[@"questions"] objectAtIndex:indexPath.row];
    cell.question.text = question[@"question"];
    [AppDelegate adjustLabelHeight:cell.question minHeight:20.0 forSize:CGSizeMake(cell.question.frame.size.width, self.view.frame.size.height)];
    cell.textHeight.constant = cell.question.frame.size.height + 2.0; //just a bit
    [cell layoutIfNeeded];
    cell.tag = cell.btnAnswer.tag = cell.btnRemove.tag = cell.btnReport.tag = indexPath.row;
    NSDate *d = [dateFormatter dateFromString: question[@"assignedon"]];
    NSTimeInterval dt = [d timeIntervalSinceNow];
    cell.pgsTime.progress = 1.0 - fabs(dt/MAX_ANSWER_TIME);
    return cell;
}

#pragma mark - Actions
-(void)updateTimer:(NSTimer *)timer {
    NSArray *paths = [self.tableView indexPathsForVisibleRows];

    for (NSIndexPath *path in paths) {
        QuestionCell *cell = (QuestionCell *)[self.tableView cellForRowAtIndexPath:path];
        cell.pgsTime.progress = cell.pgsTime.progress - 1.0/MAX_ANSWER_TIME;
        if (cell.pgsTime.progress < FLT_EPSILON) {
            self.tableView.contentOffset = CGPointMake(0, -64);
            [self.refreshControl beginRefreshing];
            [self reloadQuestions:self];
        }
    }

}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (!buttonIndex)
        return;
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    HTTPClient *client = [HTTPClient sharedClient];
    NSMutableDictionary *params = [@{@"question":@(alertView.tag)} mutableCopy];
    if (buttonIndex < refuseReasons.count)
        params[@"reason"] = refuseReasons[buttonIndex-1];
    [client POST:@"/refuse" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        if (responseObject[@"error"])
            [SVProgressHUD showErrorWithStatus:responseObject[@"error"]];
        else {
            [SVProgressHUD dismiss];
            [AppDelegate sharedApp].profile = [responseObject mutableCopy];
            [SVProgressHUD showSuccessWithStatus:@"Question refused"];
            [self.tableView reloadData];
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

#pragma mark - Navigation
- (IBAction)removeQuestion:(UIButton *)sender {
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"What's wrong with this question?" message:nil delegate:self cancelButtonTitle:@"Leave it" otherButtonTitles: nil];
    for (NSString *reason in refuseReasons)
        [av addButtonWithTitle:reason];
    av.delegate = self;
    av.tag = sender.tag;
    [av show];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Answer"]) {
        AnswerViewController *vc = (AnswerViewController *)segue.destinationViewController;
        vc.questionIdx = ((UIButton *)sender).tag;
    }
    else if ([segue.identifier isEqualToString:@"Report"]) {
        ReportViewController *vc = (ReportViewController *)segue.destinationViewController;
        vc.questionIdx = ((UIButton *)sender).tag;
        NSDictionary *question = [[AppDelegate sharedApp].profile[@"questions"] objectAtIndex:vc.questionIdx];
        vc.questionText = question[@"question"];
    }
}


@end
