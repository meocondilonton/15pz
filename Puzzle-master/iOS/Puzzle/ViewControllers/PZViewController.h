//
//  PZViewController.h
//  Puzzle

////////////////////////////////////////////////////////////////////////////////
#import "PZStopWatch.h"
#import "PZHelpViewController.h"
@import UIKit;

////////////////////////////////////////////////////////////////////////////////
@class PZPuzzle;

////////////////////////////////////////////////////////////////////////////////
@interface PZViewController : UIViewController {
@private
    PZStopWatch *_stopWatch;
    PZPuzzle *_puzzle;
}

@property (nonatomic, weak) IBOutlet UIView *layersView;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel;
@property (nonatomic, weak) IBOutlet UILabel *movesLabel;
@property (nonatomic, weak) IBOutlet UIButton *highScoresButton;
@property (weak, nonatomic) IBOutlet UIButton *helpButton;
@property (nonatomic, strong) NSString *tilesImageFile;

- (IBAction)showHighscores:(UIButton *)aSender;
- (IBAction)showHelp:(UIButton *)aSender;

@end
