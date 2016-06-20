//
//  BleDataWriteTool.m
//  WayMisc
//
//  Created by xinmeiti on 16/6/20.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "BleDataWriteTool.h"

@implementation BleDataWriteTool
+(void)BleDataWithEventAtPacket:(Byte)packet block:(void (^)(BOOL))block
{
        NSData *data = [NSData dataWithBytes:&packet length:sizeof(packet)];
//    NSData *data = [@"nihao123321" dataUsingEncoding:NSASCIIStringEncoding];
    //    NSData*d = [[NSString stringWithFo   rmat:@"nihao"] dataUsingEncoding:NSASCIIStringEncoding];
    [[SlideNavigationController sharedInstance].currPeripheral writeValue:data forCharacteristic:[SlideNavigationController sharedInstance].characteristic type:CBCharacteristicWriteWithResponse];
    
    [[SlideNavigationController sharedInstance].baby readValueForCharacteristic];
    
    
}

+(void)BleDataWithOrderAtPacket:(Byte)packet block:(void (^)(BOOL))block
{
    
}

@end
