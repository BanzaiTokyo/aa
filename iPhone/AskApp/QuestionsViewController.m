//
//  QuestionsViewController.m
//  AskApp
//
//  Created by Toxa on 11/09/14.
//
//

#import "QuestionsViewController.h"
#import "AnswerViewController.h"
#import "ReportViewController.h"

@interface QuestionsViewController ()<UIAlertViewDelegate, UIScrollViewDelegate>
@end

@implementation QuestionsViewController {
    NSMutableArray *questionViews;
    NSArray *refuseReasons;
    NSDateFormatter *dateFormatter;
    NSTimer *timer;
    UIRefreshControl *refreshControl;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    refuseReasons = @[@"It's not in English", @"It's not a question", @"It's offensive", @"Not my expertise", @"Just remove it"];
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(reloadQuestions:) forControlEvents:UIControlEventValueChanged];
    [self.scrollView addSubview:refreshControl];
    questionViews = [NSMutableArray new];
}

-(void)viewWillAppear:(BOOL)animated {
    if (self.presentedViewController)
        return;
    if (![AppDelegate sharedApp].profile) {
        self.scrollView.contentOffset = CGPointMake(0, -64);
        [refreshControl beginRefreshing];
        [self reloadQuestions:nil];
    }
    else if (self.needReloadAfterLogin) {
        [self showQuestion];
        [self runTimer];
    }
    else {
        NSDate *d = [dateFormatter dateFromString: [AppDelegate sharedApp].profile[@"assignedon"]];
        NSTimeInterval dt = [d timeIntervalSinceNow];
        if (dt < -MAX_ANSWER_TIME) {
            self.scrollView.contentOffset = CGPointMake(0, -64);
            [refreshControl beginRefreshing];
            [self reloadQuestions:refreshControl];
        }
        else {
            if (!questionViews.count)
                [self showQuestion];
            [self runTimer];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [timer invalidate];
}

- (void)runTimer {
    if (![timer isValid])
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimer:) userInfo:nil repeats:YES];
}

- (void)showQuestion {
    NSArray *questions = [AppDelegate sharedApp].profile[@"questions"];
    
    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width*questions.count, self.scrollView.bounds.size.height+1);
    self.pageControl.numberOfPages = questions.count;
    
    for (UIView *v in questionViews)
        [v removeFromSuperview];
    [questionViews removeAllObjects];
    for (int i=0; i<questions.count; i++) {
        CGFloat w = self.scrollView.bounds.size.width;
        UIView *questionView = [[UIView alloc] initWithFrame:CGRectMake(w*i, 0, w, self.scrollView.bounds.size.height)];
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, w - 20, questionView.frame.size.height/2 - 20)];
        l.numberOfLines = 0;
        l.lineBreakMode = NSLineBreakByWordWrapping;
        l.text = questions[i][@"question"];
        [l sizeToFit];
        [questionView addSubview:l];
        if (![questions[i][@"status"] isEqualToString:@"new"]) {
            l = [[UILabel alloc] initWithFrame:questionView.frame];
            l.text = [questions[i][@"status"] capitalizedString];
            [l sizeToFit];
            l.center = CGPointMake(w/2, questionView.frame.size.height-l.frame.size.height/2-20);
            [questionView addSubview:l];
        }
        [self.scrollView addSubview:questionView];
        [questionViews addObject:questionView];
    }
    NSDate *d = [dateFormatter dateFromString: questions[0][@"assignedon"]];
    NSTimeInterval dt = [d timeIntervalSinceNow];
    self.pgsTime.progress = 1.0 - fabs(dt/MAX_ANSWER_TIME);
    [self scrollPage:self.pageControl];
}

- (void)reloadQuestions:(id)sender {
    [timer invalidate];
    NSString *url;
    if (sender)
        url = @"/refreshq";
    else //called if profile is not loaded in HomeViewController
        url = @"/profile";
    HTTPClient *client = [HTTPClient sharedClient];
    [client GET:url parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        [refreshControl endRefreshing];
        [self runTimer];
        if (responseObject[@"email"]) {
            [AppDelegate sharedApp].profile = [responseObject mutableCopy];
            self.needReloadAfterLogin = NO;
            [self showQuestion];
        }
        else {
            NSString *errorMessage = @"Error";
            if (responseObject[@"error"])
                errorMessage = responseObject[@"error"];
            [UIAlertView showAlertViewWithTitle:@"Error" message: errorMessage cancelButtonTitle:@"OK" otherButtonTitles:nil];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [refreshControl endRefreshing];
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        if (response.statusCode == 403)
            [[AppDelegate sharedApp] handle403];
        else {
            [self runTimer];
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"HTTP error code %ld", (long)response.statusCode]];
        }
    }];
}

#pragma mark - Scrolling

- (IBAction)scrollPage:(UIPageControl *)sender {
    CGFloat pageWidth = self.scrollView.frame.size.width;
    CGPoint pos = CGPointMake(self.pageControl.currentPage*pageWidth, self.scrollView.contentOffset.y);
    [self.scrollView scrollRectToVisible:CGRectMake(pos.x, pos.y, pageWidth, self.scrollView.frame.size.height) animated:YES];
    BOOL unanswered = [[AppDelegate sharedApp].profile[@"questions"][sender.currentPage][@"status"] isEqualToString:@"new"];
    self.btnAnswer.enabled = unanswered;
    self.btnRemove.enabled = unanswered;
    self.btnReport.enabled = unanswered;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = self.scrollView.frame.size.width;
    NSInteger page = (NSInteger)floor((self.scrollView.contentOffset.x * 2.0f + pageWidth) / (pageWidth * 2.0f));
    self.pageControl.currentPage = page;
    BOOL unanswered = [[AppDelegate sharedApp].profile[@"questions"][page][@"status"] isEqualToString:@"new"];
    self.btnAnswer.enabled = unanswered;
    self.btnRemove.enabled = unanswered;
    self.btnReport.enabled = unanswered;
}

#pragma mark - Actions
-(void)updateTimer:(NSTimer *)timer {
    self.pgsTime.progress = self.pgsTime.progress - 1.0/MAX_ANSWER_TIME;
    if (self.pgsTime.progress < FLT_EPSILON) {
        self.scrollView.contentOffset = CGPointMake(0, -64);
        [refreshControl beginRefreshing];
        [self reloadQuestions:self];
    }
}

- (IBAction)removeQuestion:(UIButton *)sender {
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"What's wrong with this question?" message:nil delegate:self cancelButtonTitle:@"Leave it" otherButtonTitles: nil];
    for (NSString *reason in refuseReasons)
        [av addButtonWithTitle:reason];
    av.delegate = self;
    [av show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (!buttonIndex)
        return;
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    HTTPClient *client = [HTTPClient sharedClient];
    NSDictionary *question = [AppDelegate sharedApp].profile[@"questions"][self.pageControl.currentPage];
    NSMutableDictionary *params = [@{@"question":question[@"id"]} mutableCopy];
    if (buttonIndex < refuseReasons.count)
        params[@"reason"] = refuseReasons[buttonIndex-1];
    [client POST:@"/refuse" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        if (responseObject[@"error"])
            [SVProgressHUD showErrorWithStatus:responseObject[@"error"]];
        else {
            [SVProgressHUD dismiss];
            [AppDelegate sharedApp].profile = [responseObject mutableCopy];
            [SVProgressHUD showSuccessWithStatus:@"Question refused"];
            [self showQuestion];
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
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Answer"]) {
        AnswerViewController *vc = (AnswerViewController *)segue.destinationViewController;
        vc.questionIdx = self.pageControl.currentPage;
    }
    else if ([segue.identifier isEqualToString:@"Report"]) {
        ReportViewController *vc = (ReportViewController *)segue.destinationViewController;
        vc.questionIdx = self.pageControl.currentPage;
        NSDictionary *question = [[AppDelegate sharedApp].profile[@"questions"] objectAtIndex:vc.questionIdx];
        vc.questionText = question[@"question"];
    }
}

@end
