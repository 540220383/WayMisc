//
//  LinkServiceWay.m
//  WayMisc
//
//  Created by chinatsp on 16/5/9.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "LinkServiceWay.h"

@implementation LinkServiceWay

+ (NSString *)createPostURL:(NSMutableDictionary *)params
{
    NSString *postString=@"";
    for(NSString *key in [params allKeys])
    {
        NSString *value=[params objectForKey:key];
        postString=[postString stringByAppendingFormat:@"%@=%@&",key,value];
    }
    if([postString length]>1)
    {
        postString=[postString substringToIndex:[postString length]-1];
    }
    return postString;
}

+ (NSData *)getResultDataByPost:(NSMutableDictionary *)params stringLinkService:(NSString *)urlSerVice
{
    NSString *postURL=[self createPostURL:params];
    NSLog(@"URL:%@",postURL);
    NSError *error;
    NSURLResponse *theResponse;
    NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:[LinkServiceURL  stringByAppendingString:urlSerVice]]];//apyoujinku.nat123.net
    
    NSLog(@"=====%@",theRequest);
    [theRequest setHTTPMethod:@"POST"];
    [theRequest setTimeoutInterval:10.0];
    [theRequest setHTTPBody:[postURL dataUsingEncoding:NSUTF8StringEncoding]];
    return [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&theResponse error:&error];
    if (error != nil) {
//        NSLog(@"获取服务器出错了啊：%@",error);
    }
}
@end
