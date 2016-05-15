//
//  NaviViewController.h
//  WayMisc
//
//  Created by xinmeiti on 16/5/13.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AMapNaviKit/MAMapKit.h>
#import <AMapNaviKit/AMapNaviKit.h>
#import <AMapSearchKit/AMapSearchAPI.h>


#import "iflyMSC/iflyMSC.h"

@class PopupView;

@class IFlyDataUploader;
@class IFlySpeechRecognizer;
@interface NaviViewController : UIViewController<MAMapViewDelegate,AMapSearchDelegate,AMapNaviManagerDelegate,IFlySpeechSynthesizerDelegate>

@property (nonatomic, strong) MAMapView *mapView;

@property (nonatomic, strong) AMapSearchAPI *search;

@property (nonatomic, strong) AMapNaviManager *naviManager;

@property (nonatomic, strong) IFlySpeechSynthesizer *iFlySpeechSynthesizer;


@property (nonatomic, strong) IFlySpeechRecognizer *iFlySpeechRecognizer;//语法识别对象

@property (nonatomic, strong) IFlyDataUploader *uploader;//数据上传对象

@property (nonatomic, strong) NSString *pcmFilePath;//音频文件路径

@property (nonatomic, strong) NSString * result;
@property (nonatomic, assign) BOOL isCanceled;

@property (nonatomic, strong) PopupView *popUpView;

@property (weak, nonatomic) IBOutlet UITextView *textView;



@end
