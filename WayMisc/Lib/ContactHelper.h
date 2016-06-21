//
//  ContactHelper.h
//  YuanTeHUD
//
//  Created by chinatsp on 16/6/17.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Contacts/Contacts.h>
#import <AddressBook/AddressBook.h>

#import "PinYin4Objc.h"
@interface ContactHelper : NSObject
/**
 *  获取过滤后只有名字和电话的联系人数组  iOS9.0以上调用此函数
 *
 *  @return 联系人数组
 */
+ (NSArray *)contactsLoadAllPersonNameAndPhoneNumbers;
/**
 *  获取过滤后只有名字和电话的联系人数组  iOS9.0以下调用此函数

 *
 *  @return 联系人数组
 */
+ (NSArray *)addressBookLoadAllPersonNameAndPhoneNumbers;
/**
 *  检测是否包含需要的字符
 *
 *  @param string   要包含的字符
 *  @param charcter 元字符
 *
 *  @return YES/NO
 */
+ (BOOL)doesStringContain:(NSString* )string Withstr:(NSString*)charcter;
/**
 *  过滤电话里的()和-
 *
 *  @param phone 电话号码
 *
 *  @return 拨号号码
 */
+ (NSString *)getPhoneNumberFomat:(NSString *)phone;
/**
 *  汉字转拼音
 *
 *  @param hanzi 字符串
 *
 *  @return 汉字拼音字符串
 */
+ (NSString *)changeHanZiToPinYinWith:(NSString *)hanzi;
/**
 *  模糊查询
 *
 *  @param string 传入字符串
 *
 *  @return 模糊查询字符串
 */
+ (NSString *)fuzzyQueryMothedsWith:(NSString *)string;
@end
