//
//  NaviViewController.m
//  WayMisc
//
//  Created by xinmeiti on 16/5/13.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//
//
//  ViewController.m
//  QuickStart
//
//  Created by 刘博 on 15/6/11.
//  Copyright (c) 2015年 AutoNavi. All rights reserved.
//

#import "NaviViewController.h"
#import <AudioToolbox/AudioToolbox.h>

#import "APIKey.h"
#import "MANaviAnnotationView.h"
#import "WMPlayer.h"


#import <QuartzCore/QuartzCore.h>
#import "Definition.h"
#import "PopupView.h"
#import "ISRDataHelper.h"
#import "IATConfig.h"

#import "NaviBottomView.h"

#define NAME        @"userwords"
#define USERWORDS   @"{\"userword\":[{\"name\":\"我的常用词\",\"words\":[\"佳晨实业\",\"蜀南庭苑\",\"高兰路\",\"复联二\"]},{\"name\":\"我的好友\",\"words\":[\"李馨琪\",\"鹿晓雷\",\"张集栋\",\"周家莉\",\"叶震珂\",\"熊泽萌\"]}]}"



@interface NaviViewController() <AMapNaviViewControllerDelegate,IFlySpeechRecognizerDelegate>
{
    AMapNaviPoint *_endPoint;
    
    MAUserLocation *_userLocation;
    
    NSMutableArray *_poiAnnotations;
}

@property (nonatomic, strong) AMapNaviViewController *naviViewController;

@end


@implementation NaviViewController


#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _textView.layer.borderWidth = 0.5f;
    _textView.layer.borderColor = [[UIColor whiteColor] CGColor];
    [_textView.layer setCornerRadius:7.0f];
    
    CGFloat posY = self.textView.frame.origin.y+self.textView.frame.size.height/6;
    _popUpView = [[PopupView alloc] initWithFrame:CGRectMake(100, posY, 0, 0) withParentView:self.view];

    
    [self initProperties];
    
    [self initSearch];
    
    [self initNaviManager];
    
    
    
    self.uploader = [[IFlyDataUploader alloc] init];
    
    //demo录音文件保存路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [paths objectAtIndex:0];
    _pcmFilePath = [[NSString alloc] initWithFormat:@"%@",[cachePath stringByAppendingPathComponent:@"asr.pcm"]];

    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = @"语音导航";
    self.view.backgroundColor = [UIColor blackColor];
//    self.navigationController.navigationBar.barStyle    = UIBarStyleBlack;
//    self.navigationController.navigationBar.translucent = NO;
//    self.navigationController.toolbar.barStyle          = UIBarStyleBlack;
//    self.navigationController.toolbar.translucent       = NO;
//    self.navigationController.toolbarHidden             = NO;
    
//    [self initToolBar];
    
    [self initbottomBar];
    
    [self initMapView];
    
    [self initIFlySpeech];//初始化识别对象
    
    [self startBtnHandler:nil];

}

-(void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.toolbarHidden             = YES;
    [_iFlySpeechRecognizer cancel]; //取消识别
    [_iFlySpeechRecognizer setDelegate:nil];
    [_iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
    
}

#pragma mark - Initalization

-(void)initbottomBar
{
    NaviBottomView *bottomBar = [[NSBundle mainBundle]loadNibNamed:@"NaviBottomView" owner:nil options:nil][0];
    bottomBar.frame = CGRectMake(0, kScreenHeight-84, kScreenWidth, 84);
    
    [self.view addSubview:bottomBar];
}

- (void)initToolBar
{
    UIBarButtonItem *flexbleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                 target:self
                                                                                 action:nil];
    
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:
                                            [NSArray arrayWithObjects:
                                             @"民治天虹商场",
                                             @"大中华交易广场",
                                             @"国贸大厦",
                                             nil]];
    
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    [segmentedControl addTarget:self action:@selector(searchAction:) forControlEvents:UIControlEventValueChanged];
    
    UIBarButtonItem *searchTypeItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
    
    self.toolbarItems = [NSArray arrayWithObjects:flexbleItem, searchTypeItem, flexbleItem, nil];
}

- (void)initProperties
{
    _poiAnnotations = [[NSMutableArray alloc] init];
}

- (void)initSearch
{
    if (self.search == nil)
    {
        self.search = [[AMapSearchAPI alloc] init];
        self.search.delegate = self;
    }
}

- (void)initNaviManager
{
    if (self.naviManager == nil)
    {
        self.naviManager = [[AMapNaviManager alloc] init];
    }
    
    [self.naviManager setDelegate:self];
}

- (void)initNaviViewController
{
    if (self.naviViewController == nil)
    {
        self.naviViewController = [[AMapNaviViewController alloc] initWithDelegate:self];
    }
    
    [self.naviViewController setDelegate:self];
}

- (void)initMapView
{
    if (_mapView == nil)
    {
        _mapView = [[MAMapView alloc] initWithFrame:CGRectMake(20, 20, kScreenWidth-40, kScreenHeight-104)];
    }
    
    [self.mapView setDelegate:self];
    [self.mapView setShowsUserLocation:YES];
    [self.mapView setZoomLevel:14];
    [self.view addSubview:self.mapView];
}

- (void)initIFlySpeech
{
    
    if (self.iFlySpeechSynthesizer == nil)
    {
        _iFlySpeechSynthesizer = [IFlySpeechSynthesizer sharedInstance];
    }
    
    _iFlySpeechSynthesizer.delegate = self;

    
    //单例模式，无UI的实例
    if (_iFlySpeechRecognizer == nil) {
        _iFlySpeechRecognizer = [IFlySpeechRecognizer sharedInstance];
        
        [_iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
        
        //设置听写模式
        [_iFlySpeechRecognizer setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
    }
    _iFlySpeechRecognizer.delegate = self;
    
    if (_iFlySpeechRecognizer != nil) {
        IATConfig *instance = [IATConfig sharedInstance];
        
        //设置最长录音时间
        [_iFlySpeechRecognizer setParameter:instance.speechTimeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
        //设置后端点
        [_iFlySpeechRecognizer setParameter:instance.vadEos forKey:[IFlySpeechConstant VAD_EOS]];
        //设置前端点
        [_iFlySpeechRecognizer setParameter:instance.vadBos forKey:[IFlySpeechConstant VAD_BOS]];
        //网络等待时间
        [_iFlySpeechRecognizer setParameter:@"20000" forKey:[IFlySpeechConstant NET_TIMEOUT]];
        
        //设置采样率，推荐使用16K
        [_iFlySpeechRecognizer setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
        
        if ([instance.language isEqualToString:[IATConfig chinese]]) {
            //设置语言
            [_iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
            //设置方言
            [_iFlySpeechRecognizer setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
        }else if ([instance.language isEqualToString:[IATConfig english]]) {
            [_iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
        }
        //设置是否返回标点符号
        [_iFlySpeechRecognizer setParameter:instance.dot forKey:[IFlySpeechConstant ASR_PTT]];
        
    }
}

#pragma mark - Search

-(void)searchDestination:(NSString*)Destinationstr{
    AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest alloc] init];
    
    if (_userLocation)
    {
        request.location = [AMapGeoPoint locationWithLatitude:_userLocation.location.coordinate.latitude
                                                    longitude:_userLocation.location.coordinate.longitude];
    }
    else
    {
        request.location = [AMapGeoPoint locationWithLatitude:39.990459 longitude:116.471476];
    }
    request.keywords            = Destinationstr;
    request.sortrule            = 1;
    request.radius = 50000;
    request.requireExtension    = NO;
    
    [self.search AMapPOIAroundSearch:request];

}

- (void)searchAction:(UISegmentedControl *)segmentedControl
{
    AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest alloc] init];
    
    if (_userLocation)
    {
                request.location = [AMapGeoPoint locationWithLatitude:_userLocation.location.coordinate.latitude
                                                            longitude:_userLocation.location.coordinate.longitude];
    }
    else
    {
                request.location = [AMapGeoPoint locationWithLatitude:39.990459 longitude:116.471476];
    }
    request.keywords            = [segmentedControl titleForSegmentAtIndex:segmentedControl.selectedSegmentIndex];
    request.sortrule            = 1;
    request.radius = 50000;
    request.requireExtension    = NO;
    
    [self.search AMapPOIAroundSearch:request];
}

#pragma mark - Actions

- (void)startEmulatorNavi
{
    [self calculateRoute];
}

- (void)calculateRoute
{
    NSArray *endPoints = @[_endPoint];
    
    [self.naviManager calculateDriveRouteWithEndPoints:endPoints wayPoints:nil drivingStrategy:0];
}


#pragma mark - MapView Delegate

- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    if (updatingLocation)
    {
        _userLocation = userLocation;
        self.mapView.centerCoordinate = self.mapView.userLocation.location.coordinate;
    }
}

- (void)mapView:(MAMapView *)mapView annotationView:(MAAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if ([view.annotation isKindOfClass:[MAPointAnnotation class]])
    {
        MAPointAnnotation *annotation = (MAPointAnnotation *)view.annotation;
        
        _endPoint = [AMapNaviPoint locationWithLatitude:annotation.coordinate.latitude
                                              longitude:annotation.coordinate.longitude];
        
        [self startEmulatorNavi];
    }
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MAPointAnnotation class]])
    {
        static NSString *pointReuseIndetifier = @"poiIdentifier";
        MANaviAnnotationView *annotationView = (MANaviAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndetifier];
        
        if (annotationView == nil)
        {
            annotationView = [[MANaviAnnotationView alloc] initWithAnnotation:annotation
                                                              reuseIdentifier:pointReuseIndetifier];
        }
        
        annotationView.canShowCallout = YES;
        annotationView.draggable = NO;
        
        return annotationView;
    }
    
    return nil;
}


#pragma mark - Search Delegate

- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error
{
    NSLog(@"SearchError:{%@}", error.localizedDescription);
}

- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response
{
    if (response.pois.count == 0)
    {
        return;
    }
    
    [self.mapView removeAnnotations:_poiAnnotations];
    [_poiAnnotations removeAllObjects];
    
//    [response.pois enumerateObjectsUsingBlock:^(AMapPOI *obj, NSUInteger idx, BOOL *stop) {
//        
//        MAPointAnnotation *annotation = [[MAPointAnnotation alloc] init];
//        [annotation setCoordinate:CLLocationCoordinate2DMake(obj.location.latitude, obj.location.longitude)];
//        [annotation setTitle:obj.name];
//        [annotation setSubtitle:obj.address];
//        
//        [_poiAnnotations addObject:annotation];
//    }];
//    
//    [self showPOIAnnotations];
    
    AMapPOI*obj = response.pois[0];
    
    MAPointAnnotation *annotation = [[MAPointAnnotation alloc] init];
    [annotation setCoordinate:CLLocationCoordinate2DMake(obj.location.latitude, obj.location.longitude)];
    [annotation setTitle:obj.name];
    [annotation setSubtitle:obj.address];
    
    _endPoint = [AMapNaviPoint locationWithLatitude:annotation.coordinate.latitude
                                          longitude:annotation.coordinate.longitude];
    
    [self startEmulatorNavi];

    
    
}

- (void)showPOIAnnotations
{
    [self.mapView addAnnotations:_poiAnnotations];
    
    if (_poiAnnotations.count == 1)
    {
        self.mapView.centerCoordinate = [(MAPointAnnotation *)_poiAnnotations[0] coordinate];
        
    }
    else
    {
        [self.mapView showAnnotations:_poiAnnotations animated:NO];
    }
}

#pragma mark - AMapNaviManager Delegate

- (void)naviManager:(AMapNaviManager *)naviManager error:(NSError *)error
{
    NSLog(@"error:{%@}",error.localizedDescription);
}

- (void)naviManager:(AMapNaviManager *)naviManager didPresentNaviViewController:(UIViewController *)naviViewController
{
    NSLog(@"didPresentNaviViewController");
    [self.naviManager startEmulatorNavi];
    //    [self.naviManager startGPSNavi];
}

- (void)naviManager:(AMapNaviManager *)naviManager didDismissNaviViewController:(UIViewController *)naviViewController
{
    NSLog(@"didDismissNaviViewController");
}

- (void)naviManagerOnCalculateRouteSuccess:(AMapNaviManager *)naviManager
{
    NSLog(@"OnCalculateRouteSuccess");
    
    if (self.naviViewController == nil)
    {
        [self initNaviViewController];
        [_naviManager  setAllowsBackgroundLocationUpdates:YES];
    }
    
    [self.naviManager presentNaviViewController:self.naviViewController animated:YES];
    
    
}

- (void)naviManager:(AMapNaviManager *)naviManager onCalculateRouteFailure:(NSError *)error
{
    NSLog(@"onCalculateRouteFailure");
}

- (void)naviManagerNeedRecalculateRouteForYaw:(AMapNaviManager *)naviManager
{
    NSLog(@"NeedReCalculateRouteForYaw");
}

- (void)naviManager:(AMapNaviManager *)naviManager didStartNavi:(AMapNaviMode)naviMode
{
    NSLog(@"didStartNavi");
}

- (void)naviManagerDidEndEmulatorNavi:(AMapNaviManager *)naviManager
{
    NSLog(@"DidEndEmulatorNavi");
    
}

- (void)naviManagerOnArrivedDestination:(AMapNaviManager *)naviManager
{
    NSLog(@"OnArrivedDestination");
}

- (void)naviManager:(AMapNaviManager *)naviManager onArrivedWayPoint:(int)wayPointIndex
{
    NSLog(@"onArrivedWayPoint");
}

- (void)naviManager:(AMapNaviManager *)naviManager didUpdateNaviLocation:(AMapNaviLocation *)naviLocation
{
    //    NSLog(@"didUpdateNaviLocation");
}

- (void)naviManager:(AMapNaviManager *)naviManager didUpdateNaviInfo:(AMapNaviInfo *)naviInfo
{
    //    NSLog(@"didUpdateNaviInfo");
}

- (BOOL)naviManagerGetSoundPlayState:(AMapNaviManager *)naviManager
{
    return 0;
}

- (void)naviManager:(AMapNaviManager *)naviManager playNaviSoundString:(NSString *)soundString soundStringType:(AMapNaviSoundType)soundStringType
{
    NSLog(@"playNaviSoundString:{%ld:%@}", (long)soundStringType, soundString);
    
    if (soundStringType == AMapNaviSoundTypePassedReminder)
    {
        //用系统自带的声音做简单例子，播放其他提示音需要另外配置
        AudioServicesPlaySystemSound(1009);
    }
    else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [_iFlySpeechSynthesizer startSpeaking:soundString];
        });
    }
}

- (void)naviManagerDidUpdateTrafficStatuses:(AMapNaviManager *)naviManager
{
    NSLog(@"DidUpdateTrafficStatuses");
}

#pragma mark - AManNaviViewController Delegate

- (void)naviViewControllerCloseButtonClicked:(AMapNaviViewController *)naviViewController
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [_iFlySpeechSynthesizer stopSpeaking];
    });
    
    [self.naviManager stopNavi];
    
    [self.naviManager dismissNaviViewControllerAnimated:YES];
}

- (void)naviViewControllerMoreButtonClicked:(AMapNaviViewController *)naviViewController
{
    if (self.naviViewController.viewShowMode == AMapNaviViewShowModeCarNorthDirection)
    {
        self.naviViewController.viewShowMode = AMapNaviViewShowModeMapNorthDirection;
    }
    else
    {
        self.naviViewController.viewShowMode = AMapNaviViewShowModeCarNorthDirection;
    }
}

- (void)naviViewControllerTurnIndicatorViewTapped:(AMapNaviViewController *)naviViewController
{
    [self.naviManager readNaviInfoManual];
}

#pragma mark - iFlySpeechSynthesizer Delegate

- (void)onCompleted:(IFlySpeechError *)error
{
    NSLog(@"Speak Error:{%d:%@}", error.errorCode, error.errorDesc);

}
/**
 启动听写
 *****/
- (void)startBtnHandler:(id)sender {
    
    NSLog(@"%s[IN]",__func__);
    
    if ([IATConfig sharedInstance].haveView == NO) {//无界面
        
        [_textView setText:@""];
        [_textView resignFirstResponder];
        self.isCanceled = NO;
        
        if(_iFlySpeechRecognizer == nil)
        {
            [self initIFlySpeech];
        }
        
        [_iFlySpeechRecognizer cancel];
        
        //设置音频来源为麦克风
        [_iFlySpeechRecognizer setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];
        
        //设置听写结果格式为json
        [_iFlySpeechRecognizer setParameter:@"json" forKey:[IFlySpeechConstant RESULT_TYPE]];
        
        //保存录音文件，保存在sdk工作路径中，如未设置工作路径，则默认保存在library/cache下
        [_iFlySpeechRecognizer setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
        
        [_iFlySpeechRecognizer setDelegate:self];
        
        BOOL ret = [_iFlySpeechRecognizer startListening];
        
        if (ret) {
           
        }else{
            [_popUpView showText: @"启动识别服务失败，请稍后重试"];//可能是上次请求未结束，暂不支持多路并发
        }
    }
}

/**
 停止录音
 *****/
- (void)stopBtnHandler:(id)sender {
    
    [_iFlySpeechRecognizer stopListening];
    [_textView resignFirstResponder];
}

/**
 取消听写
 *****/
- (void)cancelBtnHandler:(id)sender {
    self.isCanceled = YES;
    
    [_iFlySpeechRecognizer cancel];
    
    [_popUpView removeFromSuperview];
    [_textView resignFirstResponder];
}
/**
 上传联系人
 *****/
- (void)upContactBtnHandler:(id)sender {
    //确保识别是终止状态
    [_iFlySpeechRecognizer stopListening];
    
    
    
    [self showPopup];
    
    // 获取联系人
    IFlyContact *iFlyContact = [[IFlyContact alloc] init];
    NSString *contact = [iFlyContact contact];
    
    _textView.text = contact;
    
    [_uploader setParameter:@"uup" forKey:[IFlySpeechConstant SUBJECT]];
    [_uploader setParameter:@"contact" forKey:[IFlySpeechConstant DATA_TYPE]];
    [_uploader uploadDataWithCompletionHandler:
     ^(NSString * grammerID, IFlySpeechError *error)
     {
         [self onUploadFinished:error];
     } name:@"contact" data: _textView.text];
}
/**
 写入音频流线程
 ****/
- (void)sendAudioThread
{
    NSLog(@"%s[IN]",__func__);
    NSData *data = [NSData dataWithContentsOfFile:_pcmFilePath];    //从文件中读取音频
    
    int count = 10;
    unsigned long audioLen = data.length/count;
    
    
    for (int i =0 ; i< count-1; i++) {    //分割音频
        char * part1Bytes = malloc(audioLen);
        NSRange range = NSMakeRange(audioLen*i, audioLen);
        [data getBytes:part1Bytes range:range];
        NSData * part1 = [NSData dataWithBytes:part1Bytes length:audioLen];
        
        int ret = [self.iFlySpeechRecognizer writeAudio:part1];//写入音频，让SDK识别
        free(part1Bytes);
        
        
        if(!ret) {     //检测数据发送是否正常
            NSLog(@"%s[ERROR]",__func__);
            [self.iFlySpeechRecognizer stopListening];
            
           
            return;
        }
    }
    
    //处理最后一部分
    unsigned long writtenLen = audioLen * (count-1);
    char * part3Bytes = malloc(data.length-writtenLen);
    NSRange range = NSMakeRange(writtenLen, data.length-writtenLen);
    [data getBytes:part3Bytes range:range];
    NSData * part3 = [NSData dataWithBytes:part3Bytes length:data.length-writtenLen];
    
    [_iFlySpeechRecognizer writeAudio:part3];
    free(part3Bytes);
    [_iFlySpeechRecognizer stopListening];//音频数据写入完成，进入等待状态
    NSLog(@"%s[OUT]",__func__);
}


#pragma mark - IFlySpeechRecognizerDelegate

/**
 音量回调函数
 volume 0－30
 ****/
- (void) onVolumeChanged: (int)volume
{
    if (self.isCanceled) {
        [_popUpView removeFromSuperview];
        return;
    }
    
    NSString * vol = [NSString stringWithFormat:@"音量：%d",volume];
    [_popUpView showText: vol];
}



/**
 开始识别回调
 ****/
- (void) onBeginOfSpeech
{
    NSLog(@"onBeginOfSpeech");
    [_popUpView showText: @"正在录音"];
}

/**
 停止录音回调
 ****/
- (void) onEndOfSpeech
{
    NSLog(@"onEndOfSpeech");
    
    [_popUpView showText: @"停止录音"];
}
-(void) showPopup
{
    [_popUpView showText: @"正在上传..."];
}

/**
 听写结束回调（注：无论听写是否正确都会回调）
 error.errorCode =
 0     听写正确
 other 听写出错
 ****/
- (void) onError:(IFlySpeechError *) error
{
    NSLog(@"%s",__func__);
    
    if ([IATConfig sharedInstance].haveView == NO ) {
        NSString *text ;
        
        if (self.isCanceled) {
            text = @"识别取消";
            
        } else if (error.errorCode == 0 ) {
            if (_result.length == 0) {
                text = @"无识别结果";
            }else {
                text = @"识别成功";
            }
        }else {
            text = [NSString stringWithFormat:@"发生错误：%d %@", error.errorCode,error.errorDesc];
            NSLog(@"%@",text);
        }
        
        [_popUpView showText: text];
        
    }else {
        [_popUpView showText:@"识别结束"];
        NSLog(@"errorCode:%d",[error errorCode]);
    }
    
}



/**
 听写取消回调
 ****/
- (void) onCancel
{
    NSLog(@"识别取消");
}

/**
 无界面，听写结果回调
 results：听写结果
 isLast：表示最后一次
 ****/
- (void) onResults:(NSArray *) results isLast:(BOOL)isLast
{
    
    NSMutableString *resultString = [[NSMutableString alloc] init];
    NSDictionary *dic = results[0];
    for (NSString *key in dic) {
        [resultString appendFormat:@"%@",key];
    }
    _result =[NSString stringWithFormat:@"%@%@", _textView.text,resultString];
    NSString * resultFromJson =  [ISRDataHelper stringFromJson:resultString];
    _textView.text = [NSString stringWithFormat:@"%@%@", _textView.text,resultFromJson];
    
    if (isLast){
        NSLog(@"听写结果(json)：%@测试",  self.result);
        
    }
    NSLog(@"_result=%@",_result);
    NSLog(@"resultFromJson=%@",resultFromJson);
    NSString* Reg=@"^[\u4E00-\u9FA5]*$";
    NSPredicate *textPre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",Reg];
    if([textPre evaluateWithObject:resultFromJson]){
        [self searchDestination:resultFromJson];
    }
    NSLog(@"isLast=%d,_textView.text=%@",isLast,_textView.text);
}


#pragma mark - IFlyDataUploaderDelegate

/**
 上传联系人和词表的结果回调
 error ，错误码
 ****/

- (void) onUploadFinished:(IFlySpeechError *)error
{
    NSLog(@"%d",[error errorCode]);
    
    if ([error errorCode] == 0) {
        [_popUpView showText: @"上传成功"];
    }
    else {
        [_popUpView showText: [NSString stringWithFormat:@"上传失败，错误码:%d",error.errorCode]];
        
    }
    
}


@end


