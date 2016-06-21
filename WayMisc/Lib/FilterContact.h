//
//  FilterContact.h
//  YuanTeHUD
//   本数据模型用于存储Realm数据库用,如不需要,直接设置成NSObjct类型,并改为自己模型
//  Created by chinatsp on 16/6/17.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FilterContact : NSObject
@property(nonatomic,copy)  NSString *fullName;
@property(nonatomic,copy)  NSString  *pyName;
@property (nonatomic,strong) NSArray *PhoneNumbers;
@end