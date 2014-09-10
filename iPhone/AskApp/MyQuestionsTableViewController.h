//
//  MyQuestionsTableViewController.h
//  AskApp
//
//  Created by Toxa on 19/08/14.
//
//

#import <UIKit/UIKit.h>

@interface MyQuestionCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *labelDate;
@property (weak, nonatomic) IBOutlet UILabel *labelNumAnswers;
@property (weak, nonatomic) IBOutlet UILabel *labelQuestion;
@end

@interface MyQuestionsTableViewController : UITableViewController

@end
