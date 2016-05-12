//
//  FirstViewController.m
//  WayMisc
//
//  Created by 钟能 on 16/5/9.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "FirstViewController.h"
#import "SlideNavigationController.h"
@interface FirstViewController ()

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}
- (IBAction)NextPage:(id)sender {
    SlideNavigationController *vc = [SlideNavigationController sharedInstance];
    // 切换控制器
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    window.rootViewController = vc;


}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
