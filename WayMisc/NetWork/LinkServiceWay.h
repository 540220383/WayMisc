//
//  LinkServiceWay.h
//  WayMisc
//
//  Created by chinatsp on 16/5/9.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LinkServiceWay : NSObject
+(NSString *)createPostURL:(NSMutableDictionary *)params;
+ (NSData *)getResultDataByPost:(NSMutableDictionary *)params stringLinkService:(NSString *)urlSerVice;
@end
