//
//  VoiceDialViewController.m
//  WayMisc
//
//  Created by xinmeiti on 16/5/19.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "VoiceDialViewController.h"
#import <AddressBook/AddressBook.h>
@interface VoiceDialViewController ()

@end

@implementation VoiceDialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 1.获取用户的授权状态
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    
    // 2.如果授权状态是授权成功
    if (status != kABAuthorizationStatusAuthorized)  return;
    
    // 3.获取通信录对象
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    // 4.获取到所有联系人记录
    CFArrayRef peopleArray = ABAddressBookCopyArrayOfAllPeople(addressBook);
    
    
    // 5.遍历所有的联系人记录
    CFIndex peopleCount = CFArrayGetCount(peopleArray);
    for (CFIndex i = 0; i < peopleCount; i++) {
        // 5.1.获取到具体的联系人
        ABRecordRef person = CFArrayGetValueAtIndex(peopleArray, i);
        
        // 5.2.获取联系人的姓名
        NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
        NSLog(@"%@---%@", firstName, lastName);
        
        
        
        // 5.3.获取联系人的电话
        ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
        CFIndex phoneCount = ABMultiValueGetCount(phones);
        for (CFIndex i = 0; i < phoneCount; i++) {
            NSString *phoneLabel = (__bridge_transfer NSString *)ABMultiValueCopyLabelAtIndex(phones, i);
            
            NSString *phoneValue = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phones, i);
            NSLog(@"%@---%@",phoneLabel, phoneValue);
        }
        
        // 5.4.释放该释放的对象
        CFRelease(phones);
    }
    
    // 6.释放该释放的对象
    CFRelease(addressBook);
    CFRelease(peopleArray);
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
