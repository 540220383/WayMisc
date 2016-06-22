//
//  IFlySpeechUnderHelper.m
//  YuanTeHUD
//
//  Created by chinatsp on 16/6/14.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "IFlySpeechUnderHelper.h"
#import "SemanticHelper.h"

@implementation IFlySpeechUnderHelper

+ (instancetype)shareInstance
{
    static IFlySpeechUnderHelper *stander = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        stander = [[self alloc] init];
    });
    return stander;
}

- (instancetype)init
{
    if(self = [super init])
    {
        if(!_iFlySpeechUnderstander)
        {
            _iFlySpeechUnderstander = [IFlySpeechUnderstander sharedInstance];
        }
        _iFlySpeechUnderstander.delegate = self;
        
        if (_iFlySpeechUnderstander != nil) {
            IATConfig *instance = [IATConfig sharedInstance];
            
            //参数意义与IATViewController保持一致，详情可以参照其解释
            [_iFlySpeechUnderstander setParameter:instance.speechTimeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
            [_iFlySpeechUnderstander setParameter:instance.vadEos forKey:[IFlySpeechConstant VAD_EOS]];
            [_iFlySpeechUnderstander setParameter:instance.vadBos forKey:[IFlySpeechConstant VAD_BOS]];
            [_iFlySpeechUnderstander setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
            
            if ([instance.language isEqualToString:[IATConfig chinese]]) {
                [_iFlySpeechUnderstander setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
                [_iFlySpeechUnderstander setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
            }else if ([instance.language isEqualToString:[IATConfig english]]) {
                [_iFlySpeechUnderstander setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
            }
            [_iFlySpeechUnderstander setParameter:instance.dot forKey:[IFlySpeechConstant ASR_PTT]];
        }
    }
    return self;
}


- (BOOL)startListening
{
    //设置输入源为麦克风
    [_iFlySpeechUnderstander setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];

    return [_iFlySpeechUnderstander startListening];
}
- (void)stopListening
{
    [_iFlySpeechUnderstander stopListening];
}

- (void)cancel
{
    _iFlySpeechUnderstander.delegate = nil;
    [_iFlySpeechUnderstander cancel];
}


#pragma mark - IFlySpeechRecognizerDelegate

/**
 * 音量变化回调
 * volume   录音的音量，音量范围0~30
 ****/
- (void) onVolumeChanged: (int)volume
{
    NSString * vol = [NSString stringWithFormat:@"音量：%d",volume];
    NSLog(@"%@",vol);
}

/**
 开始识别回调
 ****/
- (void) onBeginOfSpeech
{
    
}

/**
 停止识别回调
 ****/
- (void) onEndOfSpeech
{
    
}



/**
 识别结果回调（注：无论是否正确都会回调）
 error.errorCode =
 0     听写正确
 other 听写出错
 ****/
- (void) onError:(IFlySpeechError *) error
{
//    NSLog(@"error=%d",[error errorCode]);
    if (error.errorCode ==0 ) {

    }
    else
    {
        //发送错误码,提示用户
        [self notificationWithNotificationName:@"error" object:[NSNumber numberWithInt:error.errorCode]];
    }
    
}

/**
 识别结果回调
 result 识别结果，NSArray的第一个元素为NSDictionary，
 NSDictionary的key为识别结果，value为置信度
 isLast：表示最后一次
 ****/
- (void) onResults:(NSArray *) results isLast:(BOOL)isLast
{
    /*
     {"semantic":{"slots":{"name":"谭祖香"}},"rc":0,"operation":"CALL","service":"telephone","text":"打电话给谭祖香。"}
     )
     
     {"semantic":{"slots":{"endLoc":{"type":"LOC_POI","poi":"深圳北站","city":"深圳市","cityAddr":"深圳"},"startLoc":{"type":"LOC_POI","city":"CURRENT_CITY","poi":"CURRENT_POI"}}},"rc":0,"operation":"ROUTE","service":"map","text":"导航到深圳北站。"}
     
     {"text":"发微信给大敏。","rc":4}
     
     {"rc":0,"operation":"ANSWER","service":"openQA","answer":{"type":"T","text":"4"},"text":"第五个。"}
     
     {"text":"下一页。","rc":4}
     
     */
    if (isLast) {
        if(results.count>0)
        {
            [SemanticHelper semanticWithSpeechRecognizerResults:results complete:^(NSString *type, NSString *keyWord) {
                NSLog(@"block返回的数据%@----%@",type,keyWord);
                [self notificationWithNotificationName:type object:keyWord];
            }];
        }
      
    }
}

/**
 取消识别回调
 ****/
- (void) onCancel
{
    
}

#pragma mark----通知
- (void)notificationWithNotificationName:(NSString *)identify object:(id)obj
{
    [[NSNotificationCenter defaultCenter] postNotificationName:identify object:obj];
}


@end
