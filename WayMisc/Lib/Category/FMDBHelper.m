//
//  FMDBHelper.m
//  YuanTeHUD
//
//  Created by chinatsp on 16/6/20.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "FMDBHelper.h"
#import "FilterContact.h"

@implementation FMDBHelper
{
    FMDatabase *_db;
}

+ (instancetype)shareFMDB
{
    static FMDBHelper *helper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [[self alloc] init];
    });
    return helper;

}
- (id)init
{
    self = [super init];
    if (self)
    {
        //1.创建数据库
        NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        
        NSString *db = [document stringByAppendingString:@"/hud.db"];
        
        NSLog(@"%@", db);
        //2.打开数据库
        _db = [FMDatabase databaseWithPath:db];
        
        if ([_db open])
        {
            //3.创建表
            NSString *sql = @"create table if not exists t_contact (id integer primary key autoincrement,fullName text,pyName text,phoneNumbers blob)";
            
            [_db executeUpdate:sql];
            [_db executeUpdate:@"DELETE FROM t_contact"];
            [_db executeUpdate:@"update sqlite_sequence SET seq = 0 where name ='t_contact'"];
        }
        
    }
    return self;
}
- (BOOL)insertContact:(FilterContact *)contact
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:contact.PhoneNumbers];
    if ([_db open])
    {
        
     BOOL success = [_db executeUpdate:@"INSERT INTO t_contact (fullName, pyName,phoneNumbers) VALUES (?, ? ,?);",contact.fullName,contact.pyName,data];
        NSLog(@"是否成功%d",success);
        return success;
    }
    return NO;

}

- (NSArray *)queryContactWithFuzzyName:(NSString *)fuzzyName
{
    NSMutableArray *arr = [NSMutableArray array];
    if ([_db open])
    {
        FMResultSet *set = [_db executeQuery:fuzzyName];
        // 遍历查询结果
        while ([set next]) {
            NSData *statusDictData = [set objectForColumnName:@"phoneNumbers"];
            NSArray *phoneNumbers = [NSKeyedUnarchiver unarchiveObjectWithData:statusDictData];
            NSString *fullName = [set objectForColumnName:@"fullName"];
            NSString *pyName = [set objectForColumnName:@"pyName"];
            
            //保存为对象
            FilterContact *contact = [[FilterContact alloc] init];
            contact.fullName = fullName;
            contact.pyName = pyName;
            contact.PhoneNumbers = phoneNumbers;
            NSLog(@"电话号码:%@",contact.PhoneNumbers);
            [arr addObject:contact];
        }
    }
     return arr;
}


@end
