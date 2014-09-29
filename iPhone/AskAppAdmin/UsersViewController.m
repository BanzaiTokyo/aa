//
//  UsersViewController.m
//  AskAppAdmin
//
//  Created by Toxa on 29/09/14.
//  Copyright (c) 2014 BanzaiTokyo. All rights reserved.
//

#import "UsersViewController.h"
#import "AppDelegate.h"
#import "UserInfoViewController.h"

@interface UsersViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation UsersViewController {
    UIRefreshControl *refreshControl;
    NSMutableArray *users;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    refreshControl = [[UIRefreshControl alloc] init];
    [self.tableView addSubview:refreshControl];
    [refreshControl addTarget:self action:@selector(reloadUsers:) forControlEvents:UIControlEventValueChanged];
    [refreshControl beginRefreshing];
    [self reloadUsers:refreshControl];
    self.tableView.contentOffset = CGPointMake(0, -64);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UITableViewCell *cell = (UITableViewCell *)sender;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    UserInfoViewController *vc = (UserInfoViewController *)segue.destinationViewController;
    vc.userid = users[indexPath.row][@"id"];
}

#pragma mark - Data source

- (void)reloadUsers:(UIRefreshControl *)sender {
    HTTPClient *client = [HTTPClient sharedClient];
    [client GET:@"/userlist" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        [sender endRefreshing];
        if ([responseObject isKindOfClass:[NSArray class]]) {
            users = [NSMutableArray arrayWithCapacity:[responseObject count]];
            for (NSDictionary *q in responseObject)
                [users addObject:[q mutableCopy]];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSDictionary *user = users[indexPath.row];
    cell.textLabel.text = user[@"email"];
    cell.detailTextLabel.text = user[@"registeredon"];
    return cell;
}
@end
