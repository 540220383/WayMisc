//
//  IFlySpeechSynHelper.m
//  YuanTeHUD
//
//  Created by chinatsp on 16/6/14.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "IFlySpeechSynHelper.h"

@implementation IFlySpeechSynHelper
+ (instancetype)shareInstance
{
    static IFlySpeechSynHelper *synHelper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        synHelper = [[self alloc] init];
    });
    return synHelper;
}
- (instancetype)init
{
    if(self = [super init])
    {
        //合成服务单例
        if (_iFlySpeechSynthesizer == nil) {
            _iFlySpeechSynthesizer = [IFlySpeechSynthesizer sharedInstance];
        }
        _iFlySpeechSynthesizer.delegate = self;
        //配置参数
         TTSConfig *instance = [TTSConfig sharedInstance];
        //设置语速1-100
        [_iFlySpeechSynthesizer setParameter:instance.speed forKey:[IFlySpeechConstant SPEED]];
        
        //设置音量1-100
        [_iFlySpeechSynthesizer setParameter:instance.volume forKey:[IFlySpeechConstant VOLUME]];
        
        //设置音调1-100
        [_iFlySpeechSynthesizer setParameter:instance.pitch forKey:[IFlySpeechConstant PITCH]];
        
        //设置采样率
        [_iFlySpeechSynthesizer setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
        
        //设置发音人
        [_iFlySpeechSynthesizer setParameter:instance.vcnName forKey:[IFlySpeechConstant VOICE_NAME]];
        
        //设置文本编码格式
        [_iFlySpeechSynthesizer setParameter:@"unicode" forKey:[IFlySpeechConstant TEXT_ENCODING]];
        
        
        NSDictionary* languageDic=@{@"Guli":@"text_uighur", //维语
                                    @"XiaoYun":@"text_vietnam",//越南语
                                    @"Abha":@"text_hindi",//印地语
                                    @"Gabriela":@"text_spanish",//西班牙语
                                    @"Allabent":@"text_russian",//俄语
                                    @"Mariane":@"text_french"};//法语
        
        NSString* textNameKey=[languageDic valueForKey:instance.vcnName];
        NSString* textSample=nil;
        
        if(textNameKey && [textNameKey length]>0){
            textSample=NSLocalizedStringFromTable(textNameKey, @"tts/tts", nil);
        }else{
            textSample=NSLocalizedStringFromTable(@"text_chinese", @"tts/tts", nil);
        }
        
        self.startUrl=[[NSBundle mainBundle]URLForResource:@"start_record.wav" withExtension:nil];
    }
    return self;
}
- (void)startSpeaking:(NSString *)text
{   _iFlySpeechSynthesizer.delegate = self;
    [_iFlySpeechSynthesizer startSpeaking:text];
}

- (void)stopSpeaking
{
    _iFlySpeechSynthesizer.delegate = nil;
    [_iFlySpeechSynthesizer stopSpeaking];
}
- (void)pauseSpeaking
{
    [_iFlySpeechSynthesizer pauseSpeaking];
}
- (void)resumeSpeaking
{
    [_iFlySpeechSynthesizer resumeSpeaking];
}
- (BOOL)isSpeaking
{
    return [_iFlySpeechSynthesizer isSpeaking];
}
+ (BOOL)hf_destroy
{
    return [IFlySpeechSynthesizer destroy];
}
#pragma mark - 合成回调 IFlySpeechSynthesizerDelegate

/**
 开始播放回调
 注：
 对通用合成方式有效，
 对uri合成无效
 ****/
- (void)onSpeakBegin
{
    self.statu = Playing;
}

/**
 缓冲进度回调
 
 progress 缓冲进度
 msg 附加信息
 注：
 对通用合成方式有效，
 对uri合成无效
 ****/
- (void)onBufferProgress:(int) progress message:(NSString *)msg
{
    NSLog(@"buffer progress %2d%%. msg: %@.", progress, msg);
}

/**
 播放进度回调
 
 progress 缓冲进度
 
 注：
 对通用合成方式有效，
 对uri合成无效
 ****/
- (void)onSpeakProgress:(int) progress
{
    NSLog(@"speak progress %2d%%.", progress);
}

/**
 合成暂停回调
 注：
 对通用合成方式有效，
 对uri合成无效
 ****/
- (void)onSpeakPaused
{
    self.statu = Paused;
}

/**
 恢复合成回调
 注：
 对通用合成方式有效，
 对uri合成无效
 ****/
- (void)onSpeakResumed
{
    self.statu = Playing;
}

/**
 合成结束（完成）回调
 
 对uri合成添加播放的功能
 ****/
- (void)onCompleted:(IFlySpeechError *) error
{
    if (error.errorCode != 0) {
        [SVProgressHUD showErrorWithStatus:@"启动语音失败"];

        return;
    }
    else if (error.errorCode == 0)
    {
        self.statu = NotStart;
        switch (self.completedStatu) {
            case OpenUnderListen:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SpeakingFinished" object:nil];
                
                SystemSoundID soundStartID=0;
                AudioServicesCreateSystemSoundID((__bridge CFURLRef)self.startUrl, &soundStartID);
                AudioServicesPlaySystemSound(soundStartID);

                break;
            case CloseUnderListen:
                NSLog(@"不开启Listen理解");
                break;
            case RepickSpeak:
                
                break;
                
            default:
                break;
        }
    
    }
    
    
  
    
}
/**
 取消合成回调
 ****/
- (void)onSpeakCancel
{
    
}



@end
