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

typedef enum{
    SpeakPlaying = 0,
    SpeakPAUSE = 1,
    SpeakFinish = 2,
} currentState;


@interface NaviViewController() <AMapNaviViewControllerDelegate,IFlySpeechRecognizerDelegate,UITableViewDelegate,UITableViewDataSource>
{
    AMapNaviPoint *_endPoint;
    
    MAUserLocation *_userLocation;
    
    NSMutableArray *_poiAnnotations;
    
    NSString *addressStr;
}

@property (nonatomic, strong) AMapNaviViewController *naviViewController;
@property (nonatomic, strong) NaviBottomView *bottomBar;
@property (nonatomic ,strong) NSMutableArray *objArry;
@property (nonatomic ,strong) UITableView *tableView;
@property (nonatomic ,strong) NSURL *startUrl;
@property (nonatomic ,strong) NSURL *overUrl;

@property (nonatomic,assign) NSInteger State; //操作类型

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
    _popUpView = [[PopupView alloc] initWithFrame:CGRectMake(100, posY+64, 0, 0) withParentView:self.view];
    
    [self.view addSubview:_popUpView];
    
    [self initProperties];
    
    [self initSearch];
    
    [self initNaviManager];
    
    self.uploader = [[IFlyDataUploader alloc] init];
    
    //demo录音文件保存路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [paths objectAtIndex:0];
    _pcmFilePath = [[NSString alloc] initWithFormat:@"%@",[cachePath stringByAppendingPathComponent:@"asr.pcm"]];

    
    self.startUrl=[[NSBundle mainBundle]URLForResource:@"start_record.wav" withExtension:nil];
    
    self.overUrl=[[NSBundle mainBundle]URLForResource:@"record_over.wav" withExtension:nil];

    
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
    
    UITableView *tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, kScreenHeight*0.5) style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:tableView];
    self.tableView = tableView;
}

-(void)viewDidAppear:(BOOL)animated
{
    self.State = SpeakFinish;
    
//    [self Speaking:@""];
    [_iFlySpeechSynthesizer startSpeaking:@"请问您想去哪里？"];
    self.mapView.centerCoordinate = self.mapView.userLocation.location.coordinate;  
    [super viewDidAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [_iFlySpeechSynthesizer stopSpeaking];
    _iFlySpeechRecognizer = nil;
    _iFlySpeechSynthesizer = nil;
    
    [self stopBtnHandler:nil];
    [self.naviManager stopNavi];
    
    


    self.navigationController.toolbarHidden             = YES;
    [_iFlySpeechRecognizer cancel]; //取消识别
    [_iFlySpeechRecognizer setDelegate:nil];
    [_iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];

    
    
    [_iFlySpeechSynthesizer setDelegate:nil];
    [_iFlySpeechRecognizer destroy];
    

//    [super viewWillDisappear:animated];

}

#pragma mark - Initalization

-(void)Speaking:(NSString *)str{
    addressStr = str;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [_iFlySpeechSynthesizer startSpeaking:str];
    });

}

-(void)setDestination
{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [_iFlySpeechSynthesizer startSpeaking:@"请问您想去哪里？"];
    });
}

-(NSMutableArray *)objArry
{
    if (_objArry == nil) {
        _objArry = [NSMutableArray array];
    }
    
    return _objArry;
}

-(void)initbottomBar
{
    if (self.bottomBar == nil) {
        _bottomBar = [[NSBundle mainBundle]loadNibNamed:@"NaviBottomView" owner:nil options:nil][0];
        _bottomBar.frame = CGRectMake(0, kScreenHeight-84, kScreenWidth, 84);
        
        [_bottomBar.destinationBtn addTarget:self action:@selector(startEmulatorNavi) forControlEvents:UIControlEventTouchUpInside];
        
        [_bottomBar.showList addTarget:self action:@selector(showResult) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_bottomBar];
        
    }
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
        _mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight-84)];
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
        [_iFlySpeechRecognizer setParameter:@"10000" forKey:[IFlySpeechConstant NET_TIMEOUT]];
        
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

-(void)showResult
{
//    [self showPOIAnnotations];
    [self.tableView reloadData];
    self.bottomBar.hidden = YES;
    [UIView animateWithDuration:0.3 animations:^{
        self.tableView.center = CGPointMake(kScreenWidth*0.5, kScreenHeight*0.75);
    }];
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
    request.requireExtension    = YES;
    request.offset = 10;
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

- (void)mapView:(MAMapView *)mapView didFailToLocateUserWithError:(NSError *)error
{
    self.mapView.centerCoordinate = self.mapView.userLocation.location.coordinate;
}
- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    if (updatingLocation)
    {
        _userLocation = userLocation;
        
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
    
    [self cancelBtnHandler:nil];
    [self stopBtnHandler:nil];
    
    [response.pois enumerateObjectsUsingBlock:^(AMapPOI *obj, NSUInteger idx, BOOL *stop) {
        
        MAPointAnnotation *annotation = [[MAPointAnnotation alloc] init];
        [annotation setCoordinate:CLLocationCoordinate2DMake(obj.location.latitude, obj.location.longitude)];
        [annotation setTitle:obj.name];
        [annotation setSubtitle:obj.address];
        
        [_poiAnnotations addObject:annotation];
    }];
    
    _objArry = response.pois;

//    [self showPOIAnnotations];
    
    AMapPOI*obj = response.pois[0];
    
    MAPointAnnotation *annotation = [[MAPointAnnotation alloc] init];
    [annotation setCoordinate:CLLocationCoordinate2DMake(obj.location.latitude, obj.location.longitude)];
    [annotation setTitle:obj.name];
    [annotation setSubtitle:obj.address];
    
    _endPoint = [AMapNaviPoint locationWithLatitude:annotation.coordinate.latitude
                                          longitude:annotation.coordinate.longitude];
    
    self.bottomBar.area.text = [NSString stringWithFormat:@"%@%@",obj.city,obj.district];
    
    self.bottomBar.destination.text = obj.name;
    [self.mapView addAnnotation:annotation];
    self.mapView.centerCoordinate = annotation.coordinate;
    
    addressStr = [NSString stringWithFormat:@"您即将到达的目的地为：%@%@%@。请问导航还是取消",obj.city,obj.district,obj.name];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [_iFlySpeechSynthesizer startSpeaking:addressStr];

    });
    
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
    [self stopBtnHandler:nil];
    [self cancelBtnHandler:nil];
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
            
            [self.naviManager getNaviGuideList];
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
    if(self.State == SpeakPlaying){
//        self.State = SpeakFinish;
        
        return;
    }
    
    SystemSoundID soundStartID=0;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)self.startUrl, &soundStartID);
    AudioServicesPlaySystemSound(soundStartID);
    if (_iFlySpeechRecognizer) {
        [self startBtnHandler:nil];
    }
    
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
    
        SystemSoundID soundOverID=0;
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)self.startUrl, &soundOverID);
        AudioServicesPlaySystemSound(soundOverID);
        
        if (self.isCanceled) {
            text = @"识别取消";
            
        } else if (error.errorCode == 0 ) {
            if (_result.length == 0) {
                text = @"无识别结果";
//                [self setDestination];
            }else {
                text = @"识别成功";
            }
        }else {
            text = [NSString stringWithFormat:@"发生错误：%d %@", error.errorCode,error.errorDesc];
            NSLog(@"%@",text);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

                [_iFlySpeechSynthesizer startSpeaking:addressStr];
                
            });
        }
        
        [_popUpView showText: text];
        
    }else {
        [_popUpView showText:@"识别结束"];
        [_iFlySpeechSynthesizer startSpeaking:@"无网络连接提示，请检查手机网络"];

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

#warning 返回结果
- (void) onResults:(NSArray *) results isLast:(BOOL)isLast
{
    
    NSMutableString *resultString = [[NSMutableString alloc] init];
    NSDictionary *dic = results[0];
    for (NSString *key in dic) {
        [resultString appendFormat:@"%@",key];
    }
    _result =[NSString stringWithFormat:@"%@",resultString];
    NSString * resultFromJson =  [ISRDataHelper stringFromJson:resultString];
    _textView.text = [NSString stringWithFormat:@"%@%@", _textView.text,resultFromJson];
    
    if (!isLast){
        [self stopBtnHandler:nil];
        [self cancelBtnHandler:nil];

        if([resultFromJson rangeOfString:@"导航"].location !=NSNotFound){
            self.State = SpeakPlaying;
            [self startEmulatorNavi];
        }else if ([resultFromJson rangeOfString:@"取消"].location !=NSNotFound){
            
            [self stopBtnHandler:nil];
            [self cancelBtnHandler:nil];
            [self Speaking:@"已经为您取消,请问您想去哪里？"];
//            [self setDestination];
        }else{
            NSString* Reg=@"^[\u4e00-\u9fa5_a-zA-Z0-9]+$";
            NSPredicate *textPre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",Reg];
            if([textPre evaluateWithObject:resultFromJson]){
                
                [self searchDestination:resultFromJson];
                return;
                
            }
            [self stopBtnHandler:nil];
            [self cancelBtnHandler:nil];
            [self Speaking:@"没听清楚，请再说一遍。"];
            
            NSLog(@"_result=%@",_result);
            NSLog(@"resultFromJson=%@",resultFromJson);
            NSLog(@"isLast=%d,_textView.text=%@",isLast,_textView.text);
            return ;

            
        }
        NSLog(@"听写结果(json)：%@测试",  self.result);
       
    }else{
        
        [self stopBtnHandler:nil];
        [self cancelBtnHandler:nil];
        [self Speaking:@"没听清楚，请再说一遍。"];
        
        return ;
        
    }
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

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    NaviBottomView *cellView = [[NSBundle mainBundle]loadNibNamed:@"NaviBottomView" owner:nil options:nil][0];
    cellView.frame = CGRectMake(0, 0, kScreenWidth, 84);
    AMapPOI *obj = _objArry[indexPath.row];
    
    cellView.area.text = [NSString stringWithFormat:@"%@%@",obj.city,obj.district];
    cellView.destinationBtn.tag = 100+indexPath.row;
    cellView.destination.text = obj.name;
    [cellView.destinationBtn addTarget:self action:@selector(didSelectListButton:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:cellView];
    
    return cell;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objArry.count;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];// 取消选中
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 84;
}

-(void)didSelectListButton:(UIButton *)btn
{
    [self.naviManager stopNavi];
    
    AMapPOI*obj = _objArry[btn.tag-100];
    self.bottomBar.area.text = [NSString stringWithFormat:@"%@%@",obj.city,obj.district];
    
    self.bottomBar.destination.text = obj.name;
    
    MAPointAnnotation *annotation = _poiAnnotations[btn.tag-100];
    [annotation setCoordinate:CLLocationCoordinate2DMake(obj.location.latitude, obj.location.longitude)];
    [annotation setTitle:obj.name];
    [annotation setSubtitle:obj.address];
    
    [self.mapView addAnnotation:annotation];
    self.mapView.centerCoordinate = annotation.coordinate;
    
    _endPoint = [AMapNaviPoint locationWithLatitude:annotation.coordinate.latitude
                                          longitude:annotation.coordinate.longitude];
    
    [self startEmulatorNavi];

}

@end


