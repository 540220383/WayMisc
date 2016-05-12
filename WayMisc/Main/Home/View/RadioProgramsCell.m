//
//  RadioProgramsCell.m
//  WayMisc
//
//  Created by chinatsp on 16/5/9.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "RadioProgramsCell.h"
@interface RadioProgramsCell ()
@property (weak, nonatomic) IBOutlet UIImageView *coverImageView;
@property (weak, nonatomic) IBOutlet UILabel *programDescLabel;
@property (weak, nonatomic) IBOutlet UILabel *menuNameLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *DescHeightConstraint;


@end
@implementation RadioProgramsCell
- (void)setBroad:(BroadcastingModel *)broad
{
    _broad = broad;
    //设置图片
    [self.coverImageView sd_setImageWithURL:[NSURL URLWithString:broad.img_url] placeholderImage:[UIImage imageNamed:@"tear"]];
    //设置节目描述
    NSString *subStr = broad.muc_name.length > 36?[broad.muc_name substringToIndex:36]:broad.muc_name;
    self.programDescLabel.text = subStr;
    CGFloat width = self.frame.size.width;
    self.DescHeightConstraint.constant = [self.programDescLabel.text heightWithFont:[UIFont systemFontOfSize:18.0f] withinWidth:width];
    //设置节目名称
    self.menuNameLabel.text = broad.user_name;
    
    if (broad.isPlay) {
        self.playerStateIcon.image = [UIImage imageNamed:@"playerlist_play"];
    }else{
        self.playerStateIcon.image = [UIImage imageNamed:@"playerlist_pause"];
    }
    
}
@end
