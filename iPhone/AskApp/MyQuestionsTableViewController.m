//
//  MyQuestionsTableViewController.m
//  AskApp
//
//  Created by Toxa on 19/08/14.
//
//

#import "MyQuestionsTableViewController.h"
#import "SingleQuestionViewController.h"

@implementation MyQuestionCell
@end

@interface MyQuestionsTableViewController () {
    NSArray *questions;
}

@end

@implementation MyQuestionsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //[self.refreshControl beginRefreshing];
    //self.tableView.contentOffset = CGPointMake(0, -64);
    [self reloadQuestions:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)reloadQuestions:(id)sender {
    HTTPClient *client = [HTTPClient sharedClient];
    [client GET:@"/myquestions" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        [sender endRefreshing];
        if ([responseObject isKindOfClass:[NSArray class]]) {
            questions = responseObject;
            [self.tableView reloadData];
        }
        else {
            NSString *errorMessage = @"Error";
            if (responseObject[@"error"])
                errorMessage = responseObject[@"error"];
            [UIAlertView showAlertViewWithTitle:@"Error" message: errorMessage cancelButtonTitle:@"OK" otherButtonTitles:nil];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [sender endRefreshing];
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        if (response.statusCode == 403) {
            [[AppDelegate sharedApp] handle403];
        }
        else
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"HTTP error code %ld", (long)response.statusCode]];
    }];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *selectedRow = [self.tableView indexPathForSelectedRow];
    SingleQuestionViewController *vc = (SingleQuestionViewController *)segue.destinationViewController;
    vc.question = questions[selectedRow.row];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger n = [questions count];
    if (!n)
        n = 1;
    return n;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MyQuestionCell *cell = (MyQuestionCell *)[tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    if ([questions count]) {
        cell.labelDate.hidden = NO;
        cell.labelNumAnswers.hidden = NO;
        cell.labelQuestion.textAlignment = NSTextAlignmentLeft;
        
        NSDictionary *q = [questions objectAtIndex:indexPath.row];
        
        cell.labelDate.text = q[@"askedon"];
        int numAnswers = [q[@"numanswers"] intValue];
        if (numAnswers < 1)
            cell.labelNumAnswers.text = @"No answers";
        else if (numAnswers == 1)
            cell.labelNumAnswers.text = @"1 answer";
        else
            cell.labelNumAnswers.text = [NSString stringWithFormat:@"%d answers", numAnswers];
        cell.labelQuestion.text = q[@"question"];
        [AppDelegate adjustLabelHeight:cell.labelQuestion minHeight:20.0 forSize:cell.frame.size];
    }
    else {
        cell.labelDate.hidden = YES;
        cell.labelNumAnswers.hidden = YES;
        cell.labelQuestion.textAlignment = NSTextAlignmentCenter;
        cell.labelQuestion.text = @"You have no questions";
    }
    [cell layoutIfNeeded];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([questions count]) {
        CGFloat height;
        NSDictionary *q = [questions objectAtIndex:indexPath.row];
        
        height = 37.0;
        height += [AppDelegate heightForText:q[@"question"] andFont:[UIFont systemFontOfSize:17.0] forSize:self.view.frame.size];
        return MAX(67.0, height);
    }
    else {
        return self.tableView.frame.size.height;
    }
}

@end
