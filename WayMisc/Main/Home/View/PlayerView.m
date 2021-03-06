//
//  PlayerView.m
//  WayMisc
//
//  Created by xinmeiti on 16/5/11.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "PlayerView.h"
#import <QuartzCore/QuartzCore.h>
@implementation PlayerView

-(void)drawRect:(CGRect)rect
{
    self.radioCover.clipsToBounds = YES;
}
-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

- (IBAction)collection:(id)sender {
    
}

-(void)setCoverNormalImage:(NSString *)imageName
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.Cover setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    });
}

-(void)setBroad:(BroadcastingModel *)broad
{
    self.radioCover.image = [UIImage imageNamed:@"Nornal"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.radioCover sd_setImageWithURL:[NSURL URLWithString:broad.img_url] placeholderImage:[UIImage imageNamed:@"Nornal"]];
        self.radioCover.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:broad.img_url]]];
    });
    self.mucName.text = broad.muc_name;
    self.mucDesc.text = broad.user_name;
}


@end
