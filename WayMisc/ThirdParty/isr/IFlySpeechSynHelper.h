//
//  IFlySpeechSynHelper.h
//  YuanTeHUD
//
//  Created by chinatsp on 16/6/14.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iflyMSC/iflyMSC.h"
#import "ISRDataHelper.h"
#import "IATConfig.h"
#import "TTSConfig.h"

typedef NS_OPTIONS(NSInteger, Status) {
    NotStart            = 0,
    Playing             = 2, //高异常分析需要的级别
    Paused              = 4,
};

typedef NS_OPTIONS(NSInteger, BroadcastStatu){
    RepickSpeak        ,
    OpenUnderListen    ,
    CloseUnderListen
};

@interface IFlySpeechSynHelper : NSObject<IFlySpeechSynthesizerDelegate>

@property (nonatomic, strong) IFlySpeechSynthesizer * iFlySpeechSynthesizer;//语法合成对象
/**
 *  合成状态
 */
@property (nonatomic, assign) Status statu;

/**
 *  播放完毕后的状态处理事件
 */
@property (nonatomic, assign) BroadcastStatu completedStatu;

/*!
 *  是否正在播放
 */
@property (nonatomic, readonly) BOOL isSpeaking;

+ (instancetype)shareInstance;
/**
 *  销毁对象
 *
 *  @return 成功返回YES,失败返回NO.
 */
+ (BOOL)hf_destroy;

/*!
 *  开始合成(播放)
 *  @param text 合成的文本,最大的字节数为1k
 */
- (void) startSpeaking:(NSString *)text;
/*!
 *  暂停播放
 *   暂停播放之后，合成不会暂停，仍会继续，如果发生错误则会回调错误`onCompleted`
 */
- (void) pauseSpeaking;

/*!
 *  恢复播放
 */
- (void) resumeSpeaking;

/*!
 *  停止播放并停止合成
 */
- (void) stopSpeaking;
@end
