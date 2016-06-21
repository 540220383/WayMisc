//
//  FMDBHelper.h
//  YuanTeHUD
//
//  Created by chinatsp on 16/6/20.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"
@class FilterContact;
@interface FMDBHelper : NSObject
+ (instancetype)shareFMDB;
- (BOOL)insertContact:(FilterContact *)contact;
- (NSArray *)queryContactWithFuzzyName:(NSString *)fuzzyName;
@end
