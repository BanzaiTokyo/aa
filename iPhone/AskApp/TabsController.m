//
//  TabsController.m
//  AskApp
//
//  Created by Toxa on 18/08/14.
//
//

#import "TabsController.h"

@interface TabsController ()

@end

@implementation TabsController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (BOOL)tabBarController:(UITabBarController *)tbController shouldSelectViewController:(UIViewController *)viewController {
    if (viewController == self.viewControllers[1]) {
        if ([[AppDelegate sharedApp].profile[@"points"] intValue] < POINTS_TO_ASK) {
            [UIAlertView showAlertViewWithTitle:@"Insufficient points" message:@"Not enough points to ask a question. Please, answer some questions to get more points" cancelButtonTitle:@"OK" otherButtonTitles:nil];
            return NO;
        }
    }
    return YES;
}

@end
