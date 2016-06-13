//
//  PlayerAnimation.h
//  WayMisc
//
//  Created by xinmeiti on 16/6/13.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface PlayerAnimation : CALayer


+ (CAKeyframeAnimation*)initMoveLayer:(CGPoint )point;
@end
