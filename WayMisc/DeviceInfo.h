//
//  DeviceInfo.h
//  WayMisc
//
//  Created by xinmeiti on 16/6/15.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeviceInfo : NSObject
+(DeviceInfo *)Instance;
+(instancetype)allocWithZone:(struct _NSZone *)zone;

-(void)saveVersion:(NSString *)version;
-(NSString *)getVersion;
- (BOOL)getSoftwareOpen;


-(void)saveDeviceNumber:(NSString *)number;
-(NSString *)getDeviceNumber;

-(void)saveLinkState:(BOOL)isLink;
-(BOOL)getLinkState;

-(void)saveFMchannel:(NSString *)channel;
-(NSString *)getFMchannel;

-(void)saveFMState:(BOOL)isLink;
-(BOOL)getFMState;
@end
