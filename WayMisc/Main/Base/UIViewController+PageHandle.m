//
//  UIViewController+PageHandle.m
//  WayMisc
//
//  Created by xinmeiti on 16/5/13.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "UIViewController+PageHandle.h"

@implementation UIViewController (PageHandle)
- (void)setLeftBarButtonItemAsBackButton
{
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(0, 0, 16, 40);
    [backBtn setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backOrClose) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:backBtn];
}
- (void)setLeftBarButtonItemAsBackButton:(NSString *)title
{
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(0, 0, 16, 80);
    [backBtn setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    //    [backBtn setTitle:title forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backOrClose) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:backBtn];
}

- (void)backOrClose
{
    if (self.navigationController.viewControllers[0] != self) {
        [self.navigationController popViewControllerAnimated:YES];
    }else if (self.navigationController.presentationController){
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)setLeftBarButtonItemAsBackButtonToRoot
{
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(0, 0, 50, 40);
    [backBtn addTarget:self action:@selector(backOrCloseToRoot) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:backBtn];
}

- (void)backOrCloseToRoot
{
    if (self.navigationController.viewControllers[0] != self) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else if (self.navigationController.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

-(void)closePage
{
    [self dismissViewControllerAnimated:YES completion:nil];

}

@end
