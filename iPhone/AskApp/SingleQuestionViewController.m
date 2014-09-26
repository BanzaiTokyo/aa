//
//  SingleQuestionViewController.m
//  AskApp
//
//  Created by Toxa on 19/08/14.
//
//

#import "SingleQuestionViewController.h"
#import "SingleAnswerViewController.h"

@interface SingleQuestionViewController () {
    NSMutableArray *answers;
}
@property (weak, nonatomic) IBOutlet UILabel *labelDate;
@property (weak, nonatomic) IBOutlet UITextView *textQuestion;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation SingleQuestionViewController

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
    self.labelDate.text = [self.question[@"askedon"] stringByAppendingString:@" You have asked:"];
    self.textQuestion.text = self.question[@"question"];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    HTTPClient *client = [HTTPClient sharedClient];
    [client GET:@"/answers" parameters:@{@"question": self.question[@"id"]} success:^(NSURLSessionDataTask *task, id responseObject) {
        [SVProgressHUD dismiss];
        if ([responseObject isKindOfClass:[NSArray class]]) {
            answers = [responseObject mutableCopy];
            for (int i=0; i < answers.count; i++)
                answers[i] = [answers[i] mutableCopy];
            [self.tableView reloadData];
        }
        else {
            NSString *errorMessage = @"Error";
            if (responseObject[@"error"])
                errorMessage = responseObject[@"error"];
            [UIAlertView showAlertViewWithTitle:@"Error" message: errorMessage cancelButtonTitle:@"OK" otherButtonTitles:nil];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"singleAnswer"])
        return [answers count] > 0;
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"singleAnswer"]) {
        SingleAnswerViewController *vc = (SingleAnswerViewController *)segue.destinationViewController;
        NSIndexPath *selectedRow = [self.tableView indexPathForSelectedRow];
        vc.answer = answers[selectedRow.row];
        vc.answer[@"questionText"] = self.textQuestion.text;
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger n = [answers count];
    if (!n)
        n = 1;
    return n;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    if ([answers count]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.numberOfLines = 0;
        cell.detailTextLabel.numberOfLines = 0;
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        
        NSDictionary *q = [answers objectAtIndex:indexPath.row];
        
        cell.detailTextLabel.text = q[@"answeredon"];
        [AppDelegate adjustLabelHeight:cell.textLabel minHeight:20.0 forSize:self.view.frame.size];
        cell.textLabel.text = q[@"answer"];
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.detailTextLabel.text = @"";
        cell.textLabel.text = @"You have no answers";
        cell.textLabel.frame = self.tableView.frame;
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    [cell layoutIfNeeded];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([answers count]) {
        CGFloat height;
        NSDictionary *q = [answers objectAtIndex:indexPath.row];
        
        height = 20.0;
        height += [AppDelegate heightForText:q[@"answer"] andFont:[UIFont systemFontOfSize:17.0] forSize:self.view.frame.size];
        return MAX(44.0, height);
    }
    else {
        return self.tableView.frame.size.height;
    }
}

@end
