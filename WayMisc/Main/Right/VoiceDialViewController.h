//
//  VoiceDialViewController.h
//  WayMisc
//
//  Created by xinmeiti on 16/5/19.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iflyMSC/iflyMSC.h"

@class PopupView;

@class IFlyDataUploader;
@class IFlySpeechRecognizer;

@interface VoiceDialViewController : UIViewController<IFlySpeechSynthesizerDelegate,IFlySpeechRecognizerDelegate>

@property (nonatomic, strong) IFlySpeechSynthesizer *iFlySpeechSynthesizer;


@property (nonatomic, strong) IFlySpeechRecognizer *iFlySpeechRecognizer;//语法识别对象

@property (nonatomic, strong) IFlyDataUploader *uploader;//数据上传对象

//语音语义理解对象
@property (nonatomic,strong) IFlySpeechUnderstander *iFlySpeechUnderstander;
//文本语义理解对象
@property (nonatomic,strong) IFlyTextUnderstander *iFlyUnderStand;

@property (nonatomic, strong) NSString *pcmFilePath;//音频文件路径

@property (nonatomic, strong) NSString * result;
@property (nonatomic, assign) BOOL isCanceled;

@property (nonatomic, strong) PopupView *popUpView;

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end
