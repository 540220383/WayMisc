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
#import "ConnetcViewController.h"
@interface FirstViewController ()
@property (weak, nonatomic) IBOutlet UILabel *RemindLabel;

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    NSMutableAttributedString *AttributedStr = [[NSMutableAttributedString alloc]initWithString:self.RemindLabel.text];
    [AttributedStr addAttribute:NSForegroundColorAttributeName value:kColorWithRGBA(64, 64, 64, 1) range:NSMakeRange(0, self.RemindLabel.text.length)];
    
    [AttributedStr addAttribute:NSForegroundColorAttributeName value:kColorWithRGBA(5, 81, 252, 1) range:[self.RemindLabel.text rangeOfString:@"系统信任程序"]];
    
    [AttributedStr addAttribute:NSForegroundColorAttributeName value:kColorWithRGBA(5, 81, 252, 1) range:[self.RemindLabel.text rangeOfString:@"允许后台（自动）运行"]];
    
    [AttributedStr addAttribute:NSForegroundColorAttributeName value:kColorWithRGBA(5, 81, 252, 1) range:[self.RemindLabel.text rangeOfString:@"必要的系统权限"]];

    
    self.RemindLabel.attributedText = AttributedStr;
    
    
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
    
    ConnetcViewController *connetc = [[ConnetcViewController alloc]init];

    // 切换控制器
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    window.rootViewController = connetc;


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
