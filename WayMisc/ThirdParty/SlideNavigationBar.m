//
//  SlideNavigationBar.m
//  WayMisc
//
//  Created by xinmeiti on 16/5/19.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "SlideNavigationBar.h"

@implementation SlideNavigationBar

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    for (UIButton*button in self.subviews) {
        if (![button isKindOfClass:[UIButton class]]) continue;
        
        if (button.center.x<kScreenWidth*0.5) {
            button.frame =CGRectMake(0, 0, 44, 44);
            [button setBackgroundImage:[UIImage imageNamed:@"notice_girl"] forState:UIControlStateNormal];
        }
    }
}


@end
