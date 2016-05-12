//
//  RadioProgramsCell.h
//  WayMisc
//
//  Created by chinatsp on 16/5/9.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BroadcastingModel.h"
@interface RadioProgramsCell : UICollectionViewCell
@property (nonatomic , strong) BroadcastingModel *broad;
@property (weak, nonatomic) IBOutlet UIImageView *playerStateIcon;

@end
