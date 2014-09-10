//
//  SingleAnswerViewController.m
//  AskApp
//
//  Created by Toxa on 20/08/14.
//
//

#import "SingleAnswerViewController.h"
#import <EDStarRating.h>

@interface SingleAnswerViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textQuestion;
@property (weak, nonatomic) IBOutlet UITextView *textAnswer;
@property (weak, nonatomic) IBOutlet UIView *viewButtons;
@property (weak, nonatomic) IBOutlet UIView *viewRating;
@property (weak, nonatomic) IBOutlet EDStarRating *helpful;
@property (weak, nonatomic) IBOutlet EDStarRating *detailed;
@property (weak, nonatomic) IBOutlet EDStarRating *funny;
@property (weak, nonatomic) IBOutlet UIView *viewRateButtons;

@end

@implementation SingleAnswerViewController

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
    self.textQuestion.text = self.answer[@"questionText"];
    self.textAnswer.text = self.answer[@"answer"];
    [self.answer removeObjectForKey:@"questionText"]; //to prevent send to /rateanswer
    for (UIView *v in self.viewRating.subviews)
        if ([v isKindOfClass:[EDStarRating class]]) {
            EDStarRating *esr = (EDStarRating *)v;
            esr.starImage = [UIImage imageNamed:@"Star_gray"];
            esr.starHighlightedImage = [UIImage imageNamed:@"Star_gold"];
            esr.maxRating = 5.0;
            //esr.delegate = self;
            esr.horizontalMargin = 12;
            esr.editable = ![self.answer[@"rated"] boolValue];
            esr.displayMode = EDStarRatingDisplayFull;
        }
    if ([self.answer[@"rated"] boolValue]) {
        self.viewButtons.hidden = YES;
        self.viewRating.hidden = NO;
        self.viewRateButtons.hidden = YES;
        self.helpful.rating = [self.answer[@"helpful"] floatValue];
        self.detailed.rating = [self.answer[@"detailed"] floatValue];
        self.funny.rating = [self.answer[@"funny"] floatValue];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if ([self.answer[@"rated"] boolValue]) {
        CGRect r = self.viewRating.frame;
        r.origin = self.viewButtons.frame.origin;
        self.viewRating.frame = r;
    }

}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)showReport:(id)sender {
}
- (IBAction)showRates:(id)sender {
    __block CGFloat h = self.viewRating.frame.size.height;
    __block CGRect r;
    r = self.viewRating.frame;
    r.size.height = 0;
    self.viewRating.hidden = NO;
    self.viewRating.frame = r;
    [UIView animateWithDuration:0.3 animations:^{
        r.origin = self.viewButtons.frame.origin;
        r.size.height = h;
        self.viewRating.frame = r;
        r = self.viewButtons.frame;
        r.size.height = 0;
        self.viewButtons.frame = r;
    }];
}
- (IBAction)rateAnswer:(UIButton *)sender {
    if (sender.tag && [[AppDelegate sharedApp].profile[@"points"] intValue] < POINTS_TO_ASK) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Insufficient points" message:@"Not enough points to ask a question. Please, answer some questions to get more points. Continue with rating?" delegate: self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
        [av show];
        return;
    }
    self.answer[@"helpful"] = @(self.helpful.rating);
    self.answer[@"detailed"] = @(self.detailed.rating);
    self.answer[@"funny"] = @(self.funny.rating);
    if (sender.tag)
        self.answer[@"getanotheranswer"] = @(1);
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    HTTPClient *client = [HTTPClient sharedClient];
    [client POST:@"/rateanswer" parameters:self.answer success:^(NSURLSessionDataTask *task, id responseObject) {
        if (responseObject[@"error"]) {
            [SVProgressHUD dismiss];
            [UIAlertView showAlertViewWithTitle:@"Error" message: responseObject[@"error"] cancelButtonTitle:@"OK" otherButtonTitles:nil];
        }
        else {
            self.answer[@"rated"] = @(YES);
            [SVProgressHUD showSuccessWithStatus:@"Rating accepted"];
        }
        [self.navigationController popViewControllerAnimated:YES];
        [((UITableViewController *)self.navigationController.topViewController).tableView reloadData];
        
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

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex) {
        [self rateAnswer:nil];
    }
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
