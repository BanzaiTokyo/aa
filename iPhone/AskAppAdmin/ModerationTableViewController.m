//
//  ModerationTableViewController.m
//  
//
//  Created by Toxa on 23/09/14.
//
//

#import "ModerationTableViewController.h"
#import "AppDelegate.h"
#import "UserInfoViewController.h"

@interface ModerationTableViewController ()
@property (nonatomic) BOOL allSelected;
@property (weak, nonatomic) IBOutlet UIButton *btnSelectAll;
@property (weak, nonatomic) IBOutlet UILabel *itemsStats;
@end

@implementation ModerationTableViewController {
    NSMutableArray *items;
    NSString *url, *itemKind;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    url = self.workWithAnswers ? @"/moderatea" : @"/moderateq";
    itemKind = self.workWithAnswers ? @"answers" : @"questions";
    if (self.profile)
        url = [NSString stringWithFormat:@"%@?userid=%@", url, [self.profile[@"userid"] stringValue]];
    [self setCountsLabel];
    self.tableView.contentOffset = CGPointMake(0, -64);
    [self.refreshControl beginRefreshing];
    [self reloadItems:self.refreshControl];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)reloadItems:(id)sender {
    HTTPClient *client = [HTTPClient sharedClient];
    [client GET:url parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        [sender endRefreshing];
        if ([responseObject isKindOfClass:[NSArray class]]) {
            items = [NSMutableArray arrayWithCapacity:[responseObject count]];
            for (NSDictionary *q in responseObject)
                [items addObject:[q mutableCopy]];
            [self.tableView reloadData];
            [self checkAllSelected];
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

- (void)setCountsLabel {
    NSInteger approved, rejected;
    approved = [self.profile[itemKind][@"approved"] intValue];
    rejected = [self.profile[itemKind][@"rejected"] intValue];
    self.itemsStats.text = [NSString stringWithFormat:@"New: %d, Approved: %d, Rejected: %d", [self.profile[itemKind][@"total"] intValue]-approved-rejected, approved, rejected];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UITableViewCell *cell = (UITableViewCell *)sender;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    UserInfoViewController *vc = (UserInfoViewController *)segue.destinationViewController;
    if (self.workWithAnswers)
        vc.userid = items[indexPath.row][@"answeredby"];
    else
        vc.userid = items[indexPath.row][@"askedby"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger n = [items count];
    if (!n)
        n = 1;
    return n;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    if ([items count]) {
        NSDictionary *item = [items objectAtIndex:indexPath.row];
        
        if (self.workWithAnswers) {
            cell.textLabel.text = item[@"questionText"];
            cell.textLabel.font = [UIFont systemFontOfSize:11.0];
            cell.detailTextLabel.text = item[@"answer"];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:16.0];
        }
        else {
            cell.textLabel.text = item[@"question"];
            cell.textLabel.font = [UIFont systemFontOfSize:16.0];
            cell.detailTextLabel.text = item[@"askedon"];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:11.0];
        }
        if ([item[@"moderated"] intValue] < 0) {
            cell.textLabel.textColor = [UIColor grayColor];
            cell.detailTextLabel.textColor = [UIColor grayColor];
        }
        else {
            cell.textLabel.textColor = [UIColor blackColor];
            cell.detailTextLabel.textColor = [UIColor blackColor];
        }
        if (self.profile)
            cell.accessoryType = UITableViewCellAccessoryNone;
        else
            cell.accessoryType = UITableViewCellAccessoryDetailButton;
    }
    else {
        if (self.workWithAnswers) {
            cell.detailTextLabel.text = @"No answers to moderate";
            cell.detailTextLabel.font = [UIFont systemFontOfSize:16.0];
            cell.detailTextLabel.textColor = [UIColor blackColor];
            cell.textLabel.text = @"";
        }
        else {
            cell.textLabel.text = @"No questions to moderate";
            cell.textLabel.font = [UIFont systemFontOfSize:16.0];
            cell.textLabel.textColor = [UIColor blackColor];
            cell.detailTextLabel.text = @"";
        }
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    [cell layoutIfNeeded];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([items count]) {
        CGFloat height;
        NSDictionary *item = [items objectAtIndex:indexPath.row];
        
        if (self.workWithAnswers) {
            height = [AppDelegate heightForText:item[@"questionText"] andFont:[UIFont systemFontOfSize:11.0] forSize:self.view.frame.size];
            height += [AppDelegate heightForText:item[@"answer"] andFont:[UIFont systemFontOfSize:16.0] forSize:self.view.frame.size];
            return MAX(44.0, height + 20.0);
        }
        else {
            height = 48.0;
            height += [AppDelegate heightForText:item[@"question"] andFont:[UIFont systemFontOfSize:17.0] forSize:self.view.frame.size];
            return MAX(48.0, height);
        }
    }
    else {
        return self.tableView.frame.size.height;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary *item = items[indexPath.row];
    BOOL state = [item[@"selected"] boolValue];
    item[@"selected"] = [NSNumber numberWithBool:!state];
    
    [self checkAllSelected];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

# pragma mark - Actions

- (void)setAllSelected:(BOOL)allSelected {
    _allSelected = allSelected;
    if (allSelected) {
        [self.btnSelectAll setTitle:NSLocalizedString(@"Unselect All", nil) forState:UIControlStateNormal];
    }
    else {
        [self.btnSelectAll setTitle:NSLocalizedString(@"Select All", nil) forState:UIControlStateNormal];
    }
    
}
- (void)checkAllSelected {
    NSPredicate *selected = [NSPredicate predicateWithFormat:@"selected == YES"];
    NSArray *selectedItems = [items filteredArrayUsingPredicate:selected];
    self.allSelected = selectedItems.count == items.count;
}

- (IBAction)selectAll:(id)sender {
    self.allSelected = !self.allSelected;
    for (NSMutableDictionary *item in items)
        item[@"selected"] = @(self.allSelected);
    NSArray *indexPaths = [self.tableView indexPathsForVisibleRows];
    for (NSIndexPath *idx in indexPaths)
        if (_allSelected)
            [self.tableView selectRowAtIndexPath:idx animated:NO scrollPosition:UITableViewScrollPositionNone];
        else
            [self.tableView deselectRowAtIndexPath:idx animated:NO];
}

- (IBAction)moderateItems:(UIButton *)sender {
    NSPredicate *selected = [NSPredicate predicateWithFormat:@"selected == YES"];
    NSArray *selectedItems = [items filteredArrayUsingPredicate:selected];
    if (!selectedItems.count) {
        NSString *s = [NSString stringWithFormat: @"0 %@ selected to %@", itemKind, [sender titleForState:UIControlStateNormal]];
        [UIAlertView showAlertViewWithTitle: s message:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        return;
    }
    NSMutableArray *ids = [NSMutableArray arrayWithCapacity:selectedItems.count];
    for (NSDictionary *item in selectedItems)
         [ids addObject:item[@"id"]];
    NSString *idString = [ids componentsJoinedByString:@","];
    HTTPClient *client = [HTTPClient sharedClient];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    NSDictionary *params = @{@"ids": idString,
                             @"action": @(sender.tag) //must be set to 1 or -1 in Interface Builder
                            };
    [client POST:url parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        [SVProgressHUD dismiss];
        if (self.profile) {
            NSInteger approved, rejected;
            approved = [self.profile[itemKind][@"approved"] intValue];
            rejected = [self.profile[itemKind][@"rejected"] intValue];
            for (NSMutableDictionary *item in selectedItems) {
                if (sender.tag == -1 && [item[@"moderated"] intValue] >= 0) {
                    if ([item[@"moderated"] intValue] == 1)
                        approved--;
                    rejected++;
                    item[@"moderated"] = @(-1);
                }
                else if (sender.tag == 1 && [item[@"moderated"] intValue] < 1) {
                    if ([item[@"moderated"] intValue] == -1)
                        rejected--;
                    approved++;
                    item[@"moderated"] = @(1);
                }
                item[@"selected"] = @(NO);
            }
            self.profile[itemKind][@"approved"] = @(approved);
            self.profile[itemKind][@"rejected"] = @(rejected);
            
            [self setCountsLabel];
        }
        else {
            for (NSInteger i = items.count-1; i >= 0; i--) {
                if (![items[i][@"selected"] boolValue])
                    continue;
                [items removeObjectAtIndex:i];
                NSIndexPath *idx = [NSIndexPath indexPathForRow:i inSection:0];
                [self.tableView deselectRowAtIndexPath:idx animated:NO];
            }
        }
        [self.tableView reloadData];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [SVProgressHUD dismiss];
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        if (response.statusCode == 403) {
            [[AppDelegate sharedApp] handle403];
        }
        else
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"HTTP error code %ld", (long)response.statusCode]];
    }];
}

@end
