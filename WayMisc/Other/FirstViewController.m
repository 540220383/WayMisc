//
//  FirstViewController.m
//  WayMisc
//
//  Created by 钟能 on 16/5/9.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "FirstViewController.h"
#import "SlideNavigationController.h"
#import <AddressBook/AddressBook.h>
#import <AVFoundation/AVFoundation.h>
@interface FirstViewController ()

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 1.获取用户的授权状态
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    
    // 2.如果授权状态是未决定的,则请求授权
    if (status == kABAuthorizationStatusNotDetermined) {
        // 2.1.获取通信录对象
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        
        // 2.2.请求授权
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) {
                NSLog(@"通讯录授权成功");
            } else {
                NSLog(@"通讯录授权失败");
            }
        });
    }
    
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending)
    {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                if (granted) {
                    
                } else {
                    
                }
            }];
        }
    }


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
