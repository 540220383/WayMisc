//
//  IFlySpeechUnderHelper.h
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

@interface IFlySpeechUnderHelper : NSObject<IFlySpeechRecognizerDelegate>
@property (nonatomic,strong) IFlySpeechUnderstander *iFlySpeechUnderstander;
@property (nonatomic,readonly) BOOL isUnderstanding;;

+ (instancetype)shareInstance;

/*!
 *  开始义理解
 *    同时只能进行一路会话，这次会话没有结束不能进行下一路会话，否则会报错。若有需要多次回话，请在onError回调返回后请求下一路回话。
 *
 *  @return 成功返回YES，失败返回NO
 */
- (BOOL) startListening;

/*!
 *  停止录音
 *    调用此函数会停止录音，并开始进行语义理解
 */
- (void) stopListening;

/*!
 *  取消本次会话
 */
- (void) cancel;


@end
