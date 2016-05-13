//
//  UIViewController+PageHandle.h
//  WayMisc
//
//  Created by xinmeiti on 16/5/13.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (PageHandle)
- (void)backOrClose;//左按钮的触发事件返回上一个界面
- (void)setLeftBarButtonItemAsBackButton;
- (void)setLeftBarButtonItemAsBackButtonToRoot;
- (void)setLeftBarButtonItemAsBackButton:(NSString *)titlel;
-(void)closePage;
@end
