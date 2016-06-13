//
//  PlayerAnimation.m
//  WayMisc
//
//  Created by xinmeiti on 16/6/13.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "PlayerAnimation.h"

@implementation PlayerAnimation
+(CAKeyframeAnimation *)initMoveLayer:(CGPoint)point
{
    
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    
    animation.keyPath = @"position";
    
    NSValue *value1=[NSValue valueWithCGPoint:CGPointMake(point.x, point.y)];
    

    
    NSValue *value2=[NSValue valueWithCGPoint:CGPointMake(kPlayImageW, kScreenHeight-kPlayImageW)];
    
    animation.values=@[value1,value2];
    animation.repeatCount=1;
    
    animation.removedOnCompletion = NO;
    
    animation.fillMode = kCAFillModeForwards;
    
    animation.duration = 1.5f;
    
    animation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    
    animation.delegate=self;
    
      
    return animation;
    //    [self performSelector:@selector(removePlayerLayer) withObject:nil/*可传任意类型参数*/ afterDelay:2.0];
    
}

@end
