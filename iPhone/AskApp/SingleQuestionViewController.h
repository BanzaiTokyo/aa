//
//  SingleQuestionViewController.h
//  AskApp
//
//  Created by Toxa on 19/08/14.
//
//

#import <UIKit/UIKit.h>

@interface SingleQuestionViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSDictionary *question;
@end
