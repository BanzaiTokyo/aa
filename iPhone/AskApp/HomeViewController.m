//
//  ViewController.m
//  AskApp
//
//  Created by Toxa on 22/07/14.
//
//

#import "HomeViewController.h"

@interface HomeViewController ()
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *labelPoints;
@property (weak, nonatomic) IBOutlet UILabel *labelNickname;
@property (strong, nonatomic) IBOutlet UIButton *btnAnswer;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    self.scrollView.scrollEnabled = YES;
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reloadProfile:) forControlEvents:UIControlEventValueChanged];
    [self.scrollView addSubview:self.refreshControl];

    if (![AppDelegate sharedApp].handlingPushMessage) {
        [self.refreshControl beginRefreshing];
        [self reloadProfile:self.refreshControl];
        self.scrollView.contentOffset = CGPointMake(0, -64);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self updateScreen];
}

- (void)viewDidLayoutSubviews {
    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 1);
}

- (void)reloadProfile:(UIRefreshControl *)refreshControl {
    for (UIView *v in self.scrollView.subviews)
        if ([v isKindOfClass:[UIButton class]])
            v.hidden = YES;
    HTTPClient *client = [HTTPClient sharedClient];
//    [client POST:@"/login" parameters:@{@"email": @"banzaitokyo@gmail.com", @"password": @"kostroma"} success:^(NSURLSessionDataTask *task, id responseObject) {
    [client GET:@"/profile" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        [self.refreshControl endRefreshing];
        if (responseObject[@"error"]) {
            [UIAlertView showAlertViewWithTitle:@"Error" message: responseObject[@"error"] cancelButtonTitle:@"OK" otherButtonTitles:nil];
        }
        else {
            [AppDelegate sharedApp].profile = [responseObject mutableCopy];
            [self updateScreen];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [self.refreshControl endRefreshing];
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        if (response.statusCode == 403) {
            [[AppDelegate sharedApp] handle403];
        }
        else
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"HTTP error code %ld", (long)response.statusCode]];
    }];
}

- (void)updateScreen {
    NSDictionary *profile = [AppDelegate sharedApp].profile;
    if (!profile)
        return;
    self.labelPoints.text = [NSString stringWithFormat:@"You have %@ points", profile[@"points"]];
    self.labelNickname.text = [@"Nickname: " stringByAppendingString: profile[@"nickname"]];
    for (UIView *v in self.scrollView.subviews)
        if ([v isKindOfClass:[UIButton class]])
            v.hidden = NO;
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"segueAsk"])
        if (![[AppDelegate sharedApp].profile[@"can_ask"] boolValue]) {
            [UIAlertView showAlertViewWithTitle:@"Error" message:@"You cannot ask questions until get answer to the previous" cancelButtonTitle:@"OK" otherButtonTitles:nil];
            return NO;
        }
    return YES;
}
- (IBAction)logout:(id)sender {
    [AppDelegate clearCookies];
    id vc = [self.storyboard instantiateViewControllerWithIdentifier:@"Login"];
    [self presentViewController:vc animated:YES completion:nil];
}

@end
