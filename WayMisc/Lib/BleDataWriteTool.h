//
//  BleDataWriteTool.h
//  WayMisc
//
//  Created by xinmeiti on 16/6/20.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BleDataWriteTool : NSObject

+(void)BleDataWithEventAtPacket:(Byte )packet block:(void (^)(BOOL State))block;
+(void)BleDataWithOrderAtPacket:(Byte )packet block:(void (^)(BOOL State))block;

@end
