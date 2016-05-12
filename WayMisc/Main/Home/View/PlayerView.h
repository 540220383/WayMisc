//
//  PlayerView.h
//  WayMisc
//
//  Created by xinmeiti on 16/5/11.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BroadcastingModel.h"

@protocol PlayerViewDelegate <NSObject>



@end

@interface PlayerView : UIView
@property (weak, nonatomic) IBOutlet UIImageView *radioCover;

@property (weak, nonatomic) IBOutlet UIButton *Cover;
@property (weak, nonatomic) IBOutlet UILabel *mucName;
@property (weak, nonatomic) IBOutlet UILabel *mucDesc;
- (IBAction)collection:(id)sender;
@property (nonatomic, strong) UISwipeGestureRecognizer *leftSwipeGestureRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *rightSwipeGestureRecognizer;
- (void)setCoverNormalImage:(NSString *)imageName;
@property (nonatomic ,strong)BroadcastingModel *broad;
@end
