//
//  NSString+CZ.m
//  D02-音乐播放
//
//  Created by Vincent_Guo on 14-6-28.
//  Copyright (c) 2014年 vgios. All rights reserved.
//

#import "NSString+CZ.h"

@implementation NSString (CZ)

+(NSString *)getMinuteSecondWithSecond:(NSTimeInterval)time{
    
    int minute = (int)time / 60;
    int second = (int)time % 60;
    
    if (second > 9) { //2:10
        return [NSString stringWithFormat:@"%d:%d",minute,second];
    }
    
    //2:09
    return [NSString stringWithFormat:@"%d:0%d",minute,second];
}
+(NSString *)handelWithOnlyOneNum:(NSMutableString *)num
{
    for (int j =1; j<num.length; j++) {
        [num insertString:@"," atIndex:j++];
    }
    
    return num;
}
+(NSString *)handelWithNum:(NSMutableString *)num
{
    
    for (int j =1; j<5; j++) {
        [num insertString:@"," atIndex:j++];
        
    }
    if(num.length>=5){
        return  [num substringToIndex:5];
    }
    return num;
}

+ (NSString *)fuzzyQueryMothedsWith:(NSString *)string
{
    //    NSString *searchText = @"zhang zhan fang";
    NSString *resultString = string.copy;
    NSError *error = NULL;
    
    //匹配翘舌
    NSRegularExpression *regex1 = [NSRegularExpression regularExpressionWithPattern:@"(zh|ch|sh)" options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSArray *results = [regex1 matchesInString:string options:0 range:NSMakeRange(0, [string length])];
    
    for(NSTextCheckingResult * result in results) {
        //匹配到的字符
        NSString *re = [string substringWithRange:result.range];
        
        //这里将匹配到的字符替换成前1个加 %
        resultString  =  [resultString stringByReplacingOccurrencesOfString:re withString:[NSString stringWithFormat:@"%@%%",[re substringWithRange:NSMakeRange(0, 1)]]];
        NSLog(@"%@\n", [string substringWithRange:result.range]);
    }
    
    //匹配平舌
    regex1 = [NSRegularExpression regularExpressionWithPattern:@"(z|c|s)" options:NSRegularExpressionCaseInsensitive error:&error];
    
    results = [regex1 matchesInString:string options:0 range:NSMakeRange(0, [string length])];
    
    for(NSTextCheckingResult * result in results) {
        //匹配到的字符
        NSString *re = [string substringWithRange:result.range];
        
        //这里将匹配到的字符替换成前1个加%
        resultString  =  [resultString stringByReplacingOccurrencesOfString:re withString:[NSString stringWithFormat:@"%@%%",[re substringWithRange:NSMakeRange(0, 1)]]];
        NSLog(@"%@\n", [string substringWithRange:result.range]);
    }
    
    NSString *resultString2 = resultString.copy;
    
    //匹配后鼻音
    NSRegularExpression *regex2 = [NSRegularExpression regularExpressionWithPattern:@"(ong|ang|eng)" options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *results2 = [regex2 matchesInString:resultString options:0 range:NSMakeRange(0, [resultString length])];
    for(NSTextCheckingResult * result in results2) {
        //匹配到的字符
        NSString *re = [resultString substringWithRange:result.range];
        NSLog(@"%@",re);
        //这里将匹配到的字符替换成前2个加 %
        resultString2  =  [resultString2 stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@",re] withString:[NSString stringWithFormat:@"%@%%",[re substringWithRange:NSMakeRange(0, 2)]]];
    }
    
    //匹配前鼻音
    regex2 = [NSRegularExpression regularExpressionWithPattern:@"(on|an|en)" options:NSRegularExpressionCaseInsensitive error:&error];
    results2 = [regex2 matchesInString:resultString options:0 range:NSMakeRange(0, [resultString length])];
    for(NSTextCheckingResult * result in results2) {
        //匹配到的字符
        NSString *re = [resultString substringWithRange:result.range];
        NSLog(@"%@",re);
        //这里将匹配到的字符替换成前2个加 %
        resultString2  =  [resultString2 stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@",re] withString:[NSString stringWithFormat:@"%@%%",[re substringWithRange:NSMakeRange(0, 2)]]];
    }
    
    //去重
    resultString2 = [resultString2 stringByReplacingOccurrencesOfString:@"%\{3}" withString:@"%" options:NSRegularExpressionSearch range:NSMakeRange(0, resultString2.length)];
    resultString2 = [resultString2 stringByReplacingOccurrencesOfString:@"%\{2}" withString:@"%" options:NSRegularExpressionSearch range:NSMakeRange(0, resultString2.length)];
    
    NSString *sql = [NSString stringWithFormat:@"select * from t_contact WHERE pyname like '%@'",resultString2];
    
    NSLog(@"%@",sql);
    return sql;
}
@end
