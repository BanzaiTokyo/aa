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
@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *btnAnswer;
@property (weak, nonatomic) IBOutlet UIProgressView *pgsTime;
@property (weak, nonatomic) IBOutlet UIView *toolbarView;
@end

@implementation QuestionsViewController {
    NSMutableArray *questionViews;
    NSArray *refuseReasons;
    NSDateFormatter *dateFormatter;
    NSTimer *timer;
    UIView *congratulationsView;
    BOOL hasUnansweredQuestions;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    refuseReasons = @[@"It's not in English", @"It's not a question", @"It's offensive", @"Not my expertise", @"Just remove it"];
    dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *tz = [NSTimeZone timeZoneForSecondsFromGMT:0];
    [dateFormatter setTimeZone:tz];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

    questionViews = [NSMutableArray new];
    hasUnansweredQuestions = YES;
}

-(void)viewWillAppear:(BOOL)animated {
    if (self.presentedViewController)
        return;
    if (![AppDelegate sharedApp].profile)
        [self reloadQuestions:nil];
    else if ([[AppDelegate sharedApp].profile[@"can_answer"] boolValue]) {
        NSDate *dateAssigned = [dateFormatter dateFromString: [AppDelegate sharedApp].profile[@"assignedon"]];
        NSTimeInterval dt = -[dateAssigned timeIntervalSinceNow];
        if (dt > MAX_ANSWER_TIME)
            [self reloadQuestions:self];
        else {
            if (!questionViews.count) {
                [self showQuestion];
                [self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width,0) animated:NO];
            }
            [self runTimer];
        }
    }
    else
        [self showCongratulations];
}

- (void)viewWillDisappear:(BOOL)animated {
    [timer invalidate];
}

- (void)runTimer {
    if (![timer isValid])
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimer:) userInfo:nil repeats:YES];
}

- (void)showQuestion {
    if (!self.isViewLoaded)
        return; //prevent scroll freezing when called from HomeViewController
    self.title = @"Questions to Me";
    NSArray *questions = [AppDelegate sharedApp].profile[@"questions"];
    
    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width*questions.count, self.scrollView.contentSize.height);
    self.pageControl.numberOfPages = questions.count;
    self.toolbarView.hidden = NO;
    self.topLabel.text = [NSString stringWithFormat:@"You have %@ points\nEarn more by helping others fast", [AppDelegate sharedApp].profile[@"points"]];
    
    for (UIView *v in questionViews)
        [v removeFromSuperview];
    [congratulationsView removeFromSuperview];
    congratulationsView = nil;
    [questionViews removeAllObjects];
    NSLog(@"Page %d", self.pageControl.currentPage);
    for (int t=0; t<3; t++) {
        int i;
        if (self.pageControl.currentPage == 0)
            i = t ? t-1 : questions.count - 1;
        else if (self.pageControl.currentPage == questions.count - 1)
            i = t==2 ? 0 : self.pageControl.currentPage - 1 + t;
        else
            i = self.pageControl.currentPage - 1 + t;
        
        NSLog(@"%d", i);
        CGFloat w = self.scrollView.bounds.size.width;
        UIView *questionView = [[UIView alloc] initWithFrame:CGRectMake(w*t, 0, w, self.scrollView.bounds.size.height)];
        UIView *roundRect = [[UIView alloc] initWithFrame:CGRectMake(10, 8, 300, 200)];
        roundRect.layer.masksToBounds = YES;
        roundRect.layer.cornerRadius = 20.0;
        roundRect.backgroundColor = [UIColor whiteColor];
        [questionView addSubview:roundRect];
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(20, 19, w - 60, questionView.frame.size.height/2 - 20)];
        l.numberOfLines = 0;
        l.adjustsFontSizeToFitWidth = YES;
        l.minimumScaleFactor = 0.1;
        l.lineBreakMode = NSLineBreakByWordWrapping;
        l.text = questions[i][@"question"];
        [l sizeToFit];
        [roundRect addSubview:l];
        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        b.frame = CGRectMake(w - 35, 15, 20, 20);
        [b setTitle:@"X" forState:UIControlStateNormal];
        [b addTarget:self action:@selector(reportQuestion) forControlEvents:UIControlEventTouchUpInside];
        b.tag = 1;
        [questionView addSubview:b];
        l = [[UILabel alloc] initWithFrame:CGRectMake(30, 220, 260, 20)];
        l.adjustsFontSizeToFitWidth = YES;
        l.minimumScaleFactor = 0.1;
        int n = [questions[i][@"answers"] count];
        if (!n)
            l.text = @"There are no answers yet";
        else if (n == 1) {
            if ([questions[i][@"status"] isEqualToString:@"new"])
                l.text = @"There is 1 answer. Post yours to see it";
        }
        else {
            if ([questions[i][@"status"] isEqualToString:@"new"])
                l.text = [NSString stringWithFormat: @"There are %d answers. Post yours to see them", n];
            else
                l.text = [NSString stringWithFormat: @"There are %d answers.", n];
        }
        [questionView addSubview:l];
        [self.scrollView addSubview:questionView];
        [questionViews addObject:questionView];
    }
    NSLog(@"%1.2f", self.scrollView.contentOffset.x);
    [self updateTimer:nil];
    
    BOOL unanswered = [questions[self.pageControl.currentPage][@"status"] isEqualToString:@"new"];
    ((UIButton *)([questionViews[1] viewWithTag:1])).enabled = unanswered;
    [self.btnAnswer setTitle:unanswered ? @"Answer" : @"View answers" forState:UIControlStateNormal];
}

- (void)showCongratulations {
    self.title = @"Congratulations!";
    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.scrollView.contentSize.height);
    self.topLabel.text = @"You will get more questions sooner\nif one of your answers is voted as helpful";
    
    for (UIView *v in questionViews)
        [v removeFromSuperview];
    [questionViews removeAllObjects];
    if (congratulationsView)
        return;
    CGFloat w = self.scrollView.bounds.size.width;
    congratulationsView = [[UIView alloc] initWithFrame:CGRectMake(10, 8, 300, 200)];
    congratulationsView.layer.masksToBounds = YES;
    congratulationsView.layer.cornerRadius = 20.0;
    congratulationsView.backgroundColor = [UIColor whiteColor];
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(40, 19, w - 40, congratulationsView.frame.size.height/2 - 20)];
    l.numberOfLines = 0;
    l.adjustsFontSizeToFitWidth = NO;
    l.minimumScaleFactor = 0.1;
    l.lineBreakMode = NSLineBreakByWordWrapping;
    l.textAlignment = NSTextAlignmentCenter;
    l.font = [UIFont systemFontOfSize:26];
    l.text = [NSString stringWithFormat: @"You have done an awesome job!\n\n\n+%d points", [[AppDelegate sharedApp].profile[@"questions"] count]*POINTS_FOR_ANSWER];
    [l sizeToFit];
    l.center = CGPointMake(congratulationsView.frame.size.width/2, l.center.y);
    [congratulationsView addSubview:l];
    [self.scrollView addSubview:congratulationsView];
}

- (void)reloadQuestions:(id)sender {
    [timer invalidate];
    NSString *url;
    if (sender)
        url = @"/refreshq";
    else //called if profile is not loaded in HomeViewController
        url = @"/profile";
    HTTPClient *client = [HTTPClient sharedClient];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    [client GET:url parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        [SVProgressHUD dismiss];
        [self runTimer];
        if (responseObject[@"email"]) {
            [AppDelegate sharedApp].profile = [responseObject mutableCopy];
            self.scrollView.contentOffset = CGPointMake(self.scrollView.frame.size.width, 0);
            [self showQuestion];
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
        if (response.statusCode == 403)
            [[AppDelegate sharedApp] handle403];
        else {
            [self runTimer];
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Network error" message:[NSString stringWithFormat:@"HTTP error code %ld", (long)response.statusCode] delegate:self cancelButtonTitle:@"Retry" otherButtonTitles: nil];
            av.tag = 123;
            [av show];
        }
    }];
}

#pragma mark - Scrolling

- (IBAction)scrollPage:(UIPageControl *)sender {
    [self scrollViewDidEndDecelerating:self.scrollView];
}

/*- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = self.scrollView.frame.size.width;
    NSInteger page = (NSInteger)floor((self.scrollView.contentOffset.x * 2.0f + pageWidth) / (pageWidth * 2.0f));
    self.pageControl.currentPage = page;
    
}*/

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.x > scrollView.frame.size.width) {
        // We are moving forward. Load the current doc data on the first page.
        self.pageControl.currentPage = (self.pageControl.currentPage >= [[AppDelegate sharedApp].profile[@"questions"] count]-1) ? 0 : self.pageControl.currentPage + 1;
        [self showQuestion];
    }
    if (scrollView.contentOffset.x < scrollView.frame.size.width) {
        // We are moving backward. Load the current doc data on the last page.
        self.pageControl.currentPage = (self.pageControl.currentPage == 0) ? [[AppDelegate sharedApp].profile[@"questions"] count] - 1 : self.pageControl.currentPage - 1;
        
        [self showQuestion];
    }
    
    // Reset offset back to middle page
    [scrollView setContentOffset:CGPointMake(scrollView.frame.size.width,0) animated:NO];

    BOOL unanswered;
    if (self.pageControl.currentPage < [[AppDelegate sharedApp].profile[@"questions"] count])
        unanswered = [[AppDelegate sharedApp].profile[@"questions"][self.pageControl.currentPage][@"status"] isEqualToString:@"new"];
    else
        unanswered = NO;
    ((UIButton *)([questionViews[self.pageControl.currentPage] viewWithTag:1])).enabled = unanswered;
    [self.btnAnswer setTitle:unanswered ? @"Answer" : @"View answers" forState:UIControlStateNormal];
}

#pragma mark - Actions
-(void)updateTimer:(NSTimer *)timer1 {
    if (![[AppDelegate sharedApp].profile[@"can_answer"] boolValue]) {
        [timer1 invalidate];
        return;
    }
    NSDate *dateAssigned = [dateFormatter dateFromString: [AppDelegate sharedApp].profile[@"assignedon"]];
    NSTimeInterval dt = -[dateAssigned timeIntervalSinceNow];
    self.pgsTime.progress = 1.0 - fabs(dt/MAX_ANSWER_TIME);
    if (dt > MAX_ANSWER_TIME)
        [self reloadQuestions:self];
}

- (IBAction)removeQuestion:(UIButton *)sender {
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"What's wrong with this question?" message:nil delegate:self cancelButtonTitle:@"Leave it" otherButtonTitles: nil];
    for (NSString *reason in refuseReasons)
        [av addButtonWithTitle:reason];
    av.delegate = self;
    [av show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 123)
        [self reloadQuestions:self];
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
    }
}

- (void)reportQuestion {
    [self performSegueWithIdentifier:@"Report" sender:nil];
}
@end
