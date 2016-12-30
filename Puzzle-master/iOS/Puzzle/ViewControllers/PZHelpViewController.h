//
//  PZHelpViewController.h
//  Puzzle
//
//  Created by Eugene But on 10/10/12.
//
//

////////////////////////////////////////////////////////////////////////////////
@import UIKit;

////////////////////////////////////////////////////////////////////////////////
@protocol PZHelpViewControllerDelegate;

////////////////////////////////////////////////////////////////////////////////
@interface PZHelpViewController : UIViewController

@property (nonatomic, assign) id<PZHelpViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *hideButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

- (IBAction)hide;
- (IBAction)beginTutorial:(UIButton *)sender;

@end

////////////////////////////////////////////////////////////////////////////////
@protocol PZHelpViewControllerDelegate

- (void)helpViewControllerWantsHide:(PZHelpViewController *)aController;
- (void)helpViewControllerSolvePuzzle:(PZHelpViewController *)aController
                    completionHandler:(void(^)(void))aHandler;
- (void)helpViewControllerShuflePuzzle:(PZHelpViewController *)aController
                     completionHandler:(void(^)(void))aHandler;
- (void)helpViewControllerLearnTap:(PZHelpViewController *)aController
                 completionHandler:(void(^)(void))aHandler;
- (void)helpViewControllerLearnPan:(PZHelpViewController *)aController
                 completionHandler:(void(^)(void))aHandler;
- (void)helpViewControllerLearnMoveAll:(PZHelpViewController *)aController
                     completionHandler:(void(^)(void))aHandler;

@end