//
//  DeviceInfo.m
//  WayMisc
//
//  Created by xinmeiti on 16/6/15.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "DeviceInfo.h"

@implementation DeviceInfo
static DeviceInfo *instance = nil;

+(DeviceInfo *)Instance
{
    @synchronized(self)
    {
        if(nil == instance)
        {
            [self new];
        }
    }
    
    return instance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self)
    {
        if(instance == nil)
        {
            instance = [super allocWithZone:zone];
            return instance;
        }
    }
    return nil;
}

-(BOOL)getSoftwareOpen
{
    
    return nil;
}

-(NSString *)getVersion
{
    
    return [[NSUserDefaults standardUserDefaults]objectForKey:@"version"];
}

-(void)saveVersion:(NSString *)version
{
    NSUserDefaults *verNum = [NSUserDefaults standardUserDefaults];
    
    [verNum removeObjectForKey:@"version"];
    [verNum setObject:version forKey:@"version"];
    [verNum synchronize];
    
}
-(void)saveLinkState:(BOOL)isLink
{
    NSUserDefaults *isLinkState = [NSUserDefaults standardUserDefaults];
    [isLinkState removeObjectForKey:@"linkState"];
    [isLinkState setBool:isLink forKey:@"linkState"];
    [isLinkState synchronize];
    
}
-(BOOL)getLinkState
{
    return [[NSUserDefaults standardUserDefaults]boolForKey:@"linkState"];
}

-(void)saveDeviceNumber:(NSString *)number
{
    NSUserDefaults *devNum = [NSUserDefaults standardUserDefaults];
    [devNum removeObjectForKey:@"deviceNumber"];
    [devNum setObject:number forKey:@"deviceNumber"];
    [devNum synchronize];
}

-(NSString *)getDeviceNumber
{
    return [[NSUserDefaults standardUserDefaults]objectForKey:@"deviceNumber"];
}

-(void)saveFMchannel:(NSString *)channel
{
    NSUserDefaults *channelNum = [NSUserDefaults standardUserDefaults];
    [channelNum removeObjectForKey:@"channel"];
    [channelNum setObject:channel forKey:@"channel"];
    [channelNum synchronize];
}

-(NSString *)getFMchannel
{
    return [[NSUserDefaults standardUserDefaults]objectForKey:@"channel"];
}

-(void)saveFMState:(BOOL)isLink
{
    NSUserDefaults *isFMState = [NSUserDefaults standardUserDefaults];
    [isFMState removeObjectForKey:@"FMState"];
    [isFMState setBool:isLink forKey:@"FMState"];
    [isFMState synchronize];
}

-(BOOL)getFMState
{
    return [[NSUserDefaults standardUserDefaults]boolForKey:@"FMState"];
}

@end
