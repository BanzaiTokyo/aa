//
//  QuestionsTableViewController.h
//  AskApp
//
//  Created by Toxa on 13/08/14.
//
//

#import <UIKit/UIKit.h>

@interface QuestionCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *question;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textHeight;
@property (weak, nonatomic) IBOutlet UIButton *btnAnswer;
@property (weak, nonatomic) IBOutlet UIButton *btnReport;
@property (weak, nonatomic) IBOutlet UIButton *btnRemove;
@property (weak, nonatomic) IBOutlet UIProgressView *pgsTime;

@end

@interface QuestionsTableViewController : UITableViewController
@property (nonatomic) BOOL needReloadAfterLogin;
@end
