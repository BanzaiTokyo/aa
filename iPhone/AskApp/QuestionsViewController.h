//
//  QuestionsViewController.h
//  AskApp
//
//  Created by Toxa on 11/09/14.
//
//

#import <UIKit/UIKit.h>

@interface QuestionsViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *btnAnswer;
@property (weak, nonatomic) IBOutlet UIButton *btnReport;
@property (weak, nonatomic) IBOutlet UIButton *btnRemove;
@property (weak, nonatomic) IBOutlet UIProgressView *pgsTime;
@property (nonatomic) BOOL needReloadAfterLogin;
- (void)showQuestion;
@end
