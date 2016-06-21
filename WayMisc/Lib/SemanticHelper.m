//
//  SemanticHelper.m
//  YuanTeHUD
//
//  Created by chinatsp on 16/6/14.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//
/*
 {"semantic":{"slots":{"name":"谭祖香"}},"rc":0,"operation":"CALL","service":"telephone","text":"打电话给谭祖香。"}
 )
 
 {"semantic":{"slots":{"endLoc":{"type":"LOC_POI","poi":"深圳北站","city":"深圳市","cityAddr":"深圳"},"startLoc":{"type":"LOC_POI","city":"CURRENT_CITY","poi":"CURRENT_POI"}}},"rc":0,"operation":"ROUTE","service":"map","text":"导航到深圳北站。"}
 
 {"text":"发微信给大敏。","rc":4}
 
 {"rc":0,"operation":"ANSWER","service":"openQA","answer":{"type":"T","text":"4"},"text":"第五个。"}
 
 {"text":"下一页。","rc":4}
 
 */


#import "SemanticHelper.h"

@implementation SemanticHelper

+ (void)semanticWithSpeechRecognizerResults:(NSArray *)results complete:(semanticBlock)completed
{
    NSDictionary *dic = results[0];
    NSData *semanticData = [[[dic allKeys] firstObject] dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *semanticResult = [NSJSONSerialization JSONObjectWithData:semanticData options:NSJSONReadingMutableLeaves error:nil];
    //处理语义逻辑
    if([semanticResult[@"rc"] integerValue]==0)
    {
        if([semanticResult[@"service"] isEqualToString:@"map"])
        {
            completed(@"ROUTE",semanticResult[@"semantic"][@"slots"][@"endLoc"][@"poi"]);
        }
        
        else if ([semanticResult[@"service"] isEqualToString:@"telephone"])
        {
            completed(@"CALL",semanticResult[@"semantic"][@"slots"][@"name"]);
        }
        else if ([semanticResult[@"service"] isEqualToString:@"openQA"])
        {
            completed(@"ANSWER",semanticResult[@"answer"][@"text"]);
        }
    
    }
    //无法语义的逻辑
    else if ([semanticResult[@"rc"] integerValue] ==4)
    {
        completed(@"UNSemantic",semanticResult[@"text"]);
    }
    

}

@end
