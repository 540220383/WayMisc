//
//  ContactHelper.m
//  YuanTeHUD
//
//  Created by chinatsp on 16/6/17.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "ContactHelper.h"

#import "FilterContact.h"

@implementation ContactHelper

+ (NSArray *)contactsLoadAllPersonNameAndPhoneNumbers
{
    CNContactStore *contactStore = [[CNContactStore alloc] init];
    // 定义所有打算获取的属性对应的key值，此处获取姓名，手机号，头像
    NSArray *keys = @[CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey];
    // 创建CNContactFetchRequest对象
    CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];
    // 初始化一个数组，用来存放遍历到的所有联系人
    NSMutableArray *contactarray = [NSMutableArray array];
    //转化为pinyin参数设置
   HanyuPinyinOutputFormat * outputFormat=[[HanyuPinyinOutputFormat alloc] init];
    [outputFormat setToneType:ToneTypeWithoutTone];
    [outputFormat setVCharType:VCharTypeWithV];
    [outputFormat setCaseType:CaseTypeLowercase];
    // 5.遍历所有的联系人并把遍历到的联系人添加到contactarray
    [contactStore enumerateContactsWithFetchRequest:request error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
        
        FilterContact *con = [[FilterContact alloc] init];
        NSString *fullName = [contact.familyName stringByAppendingString:contact.givenName];
        con.fullName = fullName.length? fullName:@"";
        con.pyName = [PinyinHelper toHanyuPinyinStringWithNSString:con.fullName withHanyuPinyinOutputFormat:outputFormat withNSString:@" "];
        NSLog(@"名字%@拼音%@",con.fullName,con.pyName);
        //获取电话
        NSMutableArray *arr = [NSMutableArray array];
        for (int j = 0; j < contact.phoneNumbers.count; j ++) {
            CNLabeledValue *phone = [contact.phoneNumbers objectAtIndex:j];
            CNPhoneNumber *num  = phone.value;
            NSString * phoneNumber = [ContactHelper getPhoneNumberFomat:num.stringValue];
            NSLog(@"电话----%@",phoneNumber);
            [arr addObject:phoneNumber];

        }
        con.PhoneNumbers = arr;
        
        [contactarray addObject:con];

    }];
    return contactarray;
}

+ (NSArray *)addressBookLoadAllPersonNameAndPhoneNumbers
{
    // 1.获取用户的授权状态
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    
    // 2.如果授权状态是授权成功
    if (status != kABAuthorizationStatusAuthorized) return nil;
    
    // 3.获取通信录对象
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    // 4.获取到所有联系人记录
    CFArrayRef peopleArray = ABAddressBookCopyArrayOfAllPeople(addressBook);
    NSMutableArray *array = [NSMutableArray array];
    // 5.遍历所有的联系人记录
    //设置转换参数
    HanyuPinyinOutputFormat * outputFormat=[[HanyuPinyinOutputFormat alloc] init];
    [outputFormat setToneType:ToneTypeWithoutTone];
    [outputFormat setVCharType:VCharTypeWithV];
    [outputFormat setCaseType:CaseTypeLowercase];
    
    CFIndex peopleCount = CFArrayGetCount(peopleArray);
    for (CFIndex i = 0; i < peopleCount; i++) {
        
        // 5.1.获取到具体的联系人
        ABRecordRef person = CFArrayGetValueAtIndex(peopleArray, i);
        
        // 5.2.获取联系人的姓名
        NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
        //        NSLog(@"%@---%@", firstName, lastName);
        
        NSString *fullName = [NSString stringWithFormat:@"%@%@",lastName,firstName];
        fullName = [fullName stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
        
        //        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        
        FilterContact  *con = [[FilterContact alloc] init];
        con.fullName = fullName;
        con.pyName = [PinyinHelper toHanyuPinyinStringWithNSString:con.fullName withHanyuPinyinOutputFormat:outputFormat withNSString:@" "];
        NSLog(@"名字%@拼音%@",fullName,con.pyName);
        
        //        [dict setValue:fullName forKey:@"fullName"];
        
        //        NSMutableArray *numbers = [NSMutableArray array];
        
        // 5.3.获取联系人的电话
        ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
        CFIndex phoneCount = ABMultiValueGetCount(phones);
        NSMutableArray *arr = [NSMutableArray array];
        for (CFIndex i = 0; i < phoneCount; i++) {
            
            NSString *phoneValue = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phones, i);
            if(phoneValue.length)
            {
                
                NSString *phoneNumber = [ContactHelper getPhoneNumberFomat:phoneValue];
                NSLog(@"电话-----%@",phoneNumber);
                [arr addObject:phoneNumber];
            }
        }
        con.PhoneNumbers = arr;
        [array addObject:con];
        // 5.4.释放该释放的对象
        CFRelease(phones);
    }
    
    // 6.释放该释放的对象
    CFRelease(addressBook);
    CFRelease(peopleArray);
    return array;
    




}


//检测字符
+ (BOOL)doesStringContain:(NSString* )string Withstr:(NSString*)charcter{
    if([string length] < 1)
        return FALSE;
    for (int i=0; i<[string length]; i++) {
        NSString* chr = [string substringWithRange:NSMakeRange(i, 1)];
        if([chr isEqualToString:charcter])
            return TRUE;
    }
    return FALSE;
}
+ (NSString *)getPhoneNumberFomat:(NSString *)phone{
    if([phone length] <1)
        return nil;
    NSString* telNumber = @"";
    for (int i=0; i<[phone length]; i++) {
        NSString* chr = [phone substringWithRange:NSMakeRange(i, 1)];
        if([ContactHelper doesStringContain:@"0123456789" Withstr:chr]) {
            
            telNumber = [telNumber stringByAppendingFormat:@"%@", chr];
        }
    }
    return telNumber;
}
+ (NSString *)changeHanZiToPinYinWith:(NSString *)hanzi
{
    //转化为pinyin参数设置
    HanyuPinyinOutputFormat * outputFormat=[[HanyuPinyinOutputFormat alloc] init];
    [outputFormat setToneType:ToneTypeWithoutTone];
    [outputFormat setVCharType:VCharTypeWithV];
    [outputFormat setCaseType:CaseTypeLowercase];
    NSString *pinyin = [PinyinHelper toHanyuPinyinStringWithNSString:hanzi withHanyuPinyinOutputFormat:outputFormat withNSString:@" "];

    return pinyin;
}
+ (NSString *)fuzzyQueryMothedsWith:(NSString *)string
{
    //    NSString *searchText = @"zhang zhan fang";
    NSString *resultString = string.copy;
    NSError *error = NULL;
    
    //匹配翘舌
    NSRegularExpression *regex1 = [NSRegularExpression regularExpressionWithPattern:@"(zh|ch|sh)" options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSArray *results = [regex1 matchesInString:string options:0 range:NSMakeRange(0, [string length])];
    
    for(NSTextCheckingResult * result in results) {
        //匹配到的字符
        NSString *re = [string substringWithRange:result.range];
        
        //这里将匹配到的字符替换成前1个加 %
        resultString  =  [resultString stringByReplacingOccurrencesOfString:re withString:[NSString stringWithFormat:@"%@%%",[re substringWithRange:NSMakeRange(0, 1)]]];
        NSLog(@"%@\n", [string substringWithRange:result.range]);
    }
    
    //匹配平舌
    regex1 = [NSRegularExpression regularExpressionWithPattern:@"(z|c|s)" options:NSRegularExpressionCaseInsensitive error:&error];
    
    results = [regex1 matchesInString:string options:0 range:NSMakeRange(0, [string length])];
    
    for(NSTextCheckingResult * result in results) {
        //匹配到的字符
        NSString *re = [string substringWithRange:result.range];
        
        //这里将匹配到的字符替换成前1个加%
        resultString  =  [resultString stringByReplacingOccurrencesOfString:re withString:[NSString stringWithFormat:@"%@%%",[re substringWithRange:NSMakeRange(0, 1)]]];
        NSLog(@"%@\n", [string substringWithRange:result.range]);
    }
    
    NSString *resultString2 = resultString.copy;
    
    //匹配后鼻音
    NSRegularExpression *regex2 = [NSRegularExpression regularExpressionWithPattern:@"(ong|ang|eng)" options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *results2 = [regex2 matchesInString:resultString options:0 range:NSMakeRange(0, [resultString length])];
    for(NSTextCheckingResult * result in results2) {
        //匹配到的字符
        NSString *re = [resultString substringWithRange:result.range];
        NSLog(@"%@",re);
        //这里将匹配到的字符替换成前2个加 %
        resultString2  =  [resultString2 stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@",re] withString:[NSString stringWithFormat:@"%@%%",[re substringWithRange:NSMakeRange(0, 2)]]];
    }
    
    //匹配前鼻音
    regex2 = [NSRegularExpression regularExpressionWithPattern:@"(on|an|en)" options:NSRegularExpressionCaseInsensitive error:&error];
    results2 = [regex2 matchesInString:resultString options:0 range:NSMakeRange(0, [resultString length])];
    for(NSTextCheckingResult * result in results2) {
        //匹配到的字符
        NSString *re = [resultString substringWithRange:result.range];
        NSLog(@"%@",re);
        //这里将匹配到的字符替换成前2个加 %
        resultString2  =  [resultString2 stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@",re] withString:[NSString stringWithFormat:@"%@%%",[re substringWithRange:NSMakeRange(0, 2)]]];
    }
    
    //去重
    resultString2 = [resultString2 stringByReplacingOccurrencesOfString:@"%\{3}" withString:@"%" options:NSRegularExpressionSearch range:NSMakeRange(0, resultString2.length)];
    resultString2 = [resultString2 stringByReplacingOccurrencesOfString:@"%\{2}" withString:@"%" options:NSRegularExpressionSearch range:NSMakeRange(0, resultString2.length)];
    
    
    NSString *sql = [NSString stringWithFormat:@"select * from t_contact WHERE pyName like '%@'",resultString2];
//
    NSLog(@"%@",sql);
    return sql;
}

@end
