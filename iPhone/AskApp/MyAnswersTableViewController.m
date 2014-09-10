//
//  MyQuestionsTableViewController.m
//  AskApp
//
//  Created by Toxa on 23/07/14.
//
//

#import "MyAnswersTableViewController.h"

@interface MyAnswersTableViewController () {
    NSArray *answers;
}
@end

@implementation MyAnswersTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self reloadQuestions:nil];
}

- (IBAction)reloadQuestions:(id)sender {
    HTTPClient *client = [HTTPClient sharedClient];
    [client GET:@"/myanswers" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        [sender endRefreshing];
        if ([responseObject isKindOfClass:[NSArray class]]) {
            answers = responseObject;
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
        cell.textLabel.numberOfLines = 0;
        cell.detailTextLabel.numberOfLines = 0;
        cell.detailTextLabel.textAlignment = NSTextAlignmentLeft;
        
        NSDictionary *q = [answers objectAtIndex:indexPath.row];
        
        cell.textLabel.text = q[@"question"];
        [AppDelegate adjustLabelHeight:cell.textLabel minHeight:20.0 forSize:self.view.frame.size];
        if (q[@"answer"])
            cell.detailTextLabel.text = q[@"answer"];
        else
            cell.detailTextLabel.text = @"";
        [AppDelegate adjustLabelHeight:cell.detailTextLabel minHeight:20.0 forSize:self.view.frame.size];
    }
    else {
        cell.textLabel.text = @"";
        cell.detailTextLabel.text = @"You have no answers";
        cell.detailTextLabel.frame = self.tableView.frame;
        cell.detailTextLabel.textAlignment = NSTextAlignmentCenter;
    }
    [cell layoutIfNeeded];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([answers count]) {
        CGFloat height;
        NSDictionary *q = [answers objectAtIndex:indexPath.row];

        if (q[@"answer"])
            height = [AppDelegate heightForText:q[@"answer"] andFont:[UIFont systemFontOfSize:14.0] forSize:self.view.frame.size];
        else
            height = 20.0;
        height += [AppDelegate heightForText:q[@"question"] andFont:[UIFont systemFontOfSize:16.0] forSize:self.view.frame.size];
        return MAX(44.0, height + 20.0);
    }
    else {
        return self.tableView.frame.size.height;
    }
}
@end
