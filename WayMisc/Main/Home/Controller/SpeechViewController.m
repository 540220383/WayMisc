//
//  SpeechViewController.m
//  WayMisc
//
//  Created by xinmeiti on 16/6/21.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "SpeechViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioSession.h>

//讯飞
#import "iflyMSC/iflyMSC.h"
#import "ISRDataHelper.h"
#import "IATConfig.h"
#import "TTSConfig.h"
//工具类
#import "SemanticHelper.h"
#import "IFlySpeechUnderHelper.h"
#import "IFlySpeechSynHelper.h"
#import "FMDBHelper.h"
#import "NSString+CZ.h"

#import "APIKey.h"
#import "MANaviAnnotationView.h"
#import "NaviBottomView.h"


#import "ContactHelper.h"
#import "FilterContact.h"
#define GRAMMAR_TYPE_ABNF    @"abnf"


typedef NS_ENUM(NSInteger, ChooseType){
    CHOOSE_NAV,//导航
    CHOOSE_CONTACT,//通讯录
    CHOOSE_PHONENUMBER//电话
};
@interface SpeechViewController ()<IFlySpeechRecognizerDelegate,UITableViewDataSource,UITableViewDelegate,AMapNaviViewControllerDelegate>
{
    AMapNaviPoint *_endPoint;
    
    MAUserLocation *_userLocation;
    
    NSMutableArray *_poiAnnotations;
    
    NSString *addressStr;
}
@property (nonatomic, strong) IFlySpeechRecognizer *iFlySpeechRecognizer;//语法识别对象
/**
 *  语义理解对象
 */
@property (nonatomic, strong)IFlySpeechUnderHelper *underHelper;
/**
 *  语音合成对象
 */
@property (nonatomic, strong)IFlySpeechSynHelper *synHelper;

//合成语音的状态
@property (nonatomic, assign) Status state;
/**
 *  匹配的数组
 */
@property (nonatomic, strong) NSArray *matchingArray;
/**
 *  匹配的联系人
 */
@property (nonatomic, strong) FilterContact *matchContact;

@property (nonatomic, strong) IFlyDataUploader *uploader;//数据上传对象

@property (nonatomic, strong) NSString *grammarType; //语法类型

@property (nonatomic, strong) NSMutableString *curResult;//当前session的结果

@property (nonatomic, strong)FMDBHelper *dataHelper;
/**
 *  选择列表状态
 */
@property (nonatomic, assign) ChooseType choosetype;

@property (nonatomic, copy) FilterContact *readyContact;

//是否正在上传
@property (nonatomic, assign) BOOL isUploading;

@property (nonatomic, strong) AMapNaviViewController *naviViewController;

@property (nonatomic, strong) NaviBottomView *bottomBar;//底部状态栏

@property (nonatomic ,strong) NSMutableArray *objArry; //结果数组

@property (nonatomic ,strong) UITableView *tableView; //结果列表

@property (nonatomic ,strong) NSURL *startUrl;//开始录音

@property (nonatomic ,strong) NSURL *overUrl;//结束录音


@end

@implementation SpeechViewController

static NSString * _cloudGrammerid =nil;//在线语法grammerID
#pragma mark----通讯录匹配处理
- (BOOL)saveContactBookToRealmForQuery
{
    NSArray *array = nil;
    if([[UIDevice currentDevice].systemVersion floatValue] >= 9.0)
    {
        array = [ContactHelper contactsLoadAllPersonNameAndPhoneNumbers];
    }
    else
    {
        array = [ContactHelper addressBookLoadAllPersonNameAndPhoneNumbers];
    }
    _dataHelper =[FMDBHelper shareFMDB];
    BOOL saveStatu = NO;
    for (FilterContact *contact in array) {
        saveStatu =[_dataHelper insertContact:contact];
    }
    
    return saveStatu;
}

#pragma mark------通知回调处理
- (void)navInfo:(NSNotification *)notify
{
    self.choosetype = CHOOSE_NAV;
    NSLog(@"接收到的数据是:%@",notify.object);
    
    NSString * result = (NSString *)notify.object;


    [self initProperties];
    
    [self initSearch];
    
    [self initNaviManager];
    
    [self initbottomBar];
    
//    [self initMapView];
    [self.view addSubview:self.mapView];

    [self initTableView];

    
    //开始poi搜索
    

    [self searchDestination:result];
    
}
- (void)callSomeOne:(NSNotification *)notify
{
    self.choosetype = CHOOSE_CONTACT;
    NSLog(@"接收到的数据是:%@",notify.object);
    NSString * name = (NSString *)notify.object;
    
    NSString *pinyin = [ContactHelper changeHanZiToPinYinWith:name];
    NSString *fuzzyPY = [ContactHelper fuzzyQueryMothedsWith:pinyin];
    NSMutableString *strResult = [[NSMutableString alloc]init];
    //开始搜索数据库模糊匹配
    _matchingArray =[_dataHelper queryContactWithFuzzyName:fuzzyPY];
    if(_matchingArray.count == 0)
    {
        if(![_synHelper isSpeaking])
        {   _synHelper.completedStatu = OpenUnderListen;
            [_synHelper startSpeaking:@"没听清楚，再说一遍!"];
        }
    }
    else if (_matchingArray.count == 1)
    {
        _matchContact = _matchingArray[0];
        if(_matchContact.PhoneNumbers.count > 1)
        {
            [strResult appendString:@"呼叫以下哪个联系人："];
            
            if(![_synHelper isSpeaking])
            {   _synHelper.completedStatu = OpenUnderListen;
                self.choosetype = CHOOSE_PHONENUMBER;
                
                for (NSInteger j = 0; j<_matchContact.PhoneNumbers.count; j++) {
                    [strResult appendString:[NSString stringWithFormat:@"第%ld位%@%@;",j+1,_matchContact.fullName,[NSString handelWithNum:_matchContact.PhoneNumbers[j]]]];
                }

                [_synHelper startSpeaking:strResult];
            }
        }
        else
        {
            
          
            
            _readyContact = _matchContact;

            [strResult appendString:[NSString stringWithFormat:@"为您找到%@%@",_matchContact.fullName,[_matchContact.PhoneNumbers firstObject]]];
            
            [strResult appendString:@";呼叫还是取消"];
            
            if(![_synHelper isSpeaking])
            {   _synHelper.completedStatu = OpenUnderListen;
                [_synHelper startSpeaking:strResult];
                
            }
            
           
        }
        
    }else if ([name rangeOfString:@"呼叫"].location !=NSNotFound){
        
         [_synHelper startSpeaking:[NSString stringWithFormat:@"正在为您呼叫%@",_readyContact.fullName]];
        
        if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://10086"]])
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@",[_readyContact.PhoneNumbers firstObject]]]];
        }
    }else if ([name rangeOfString:@"取消"].location !=NSNotFound){
        _readyContact = nil;
        if(![_synHelper isSpeaking])
        {   _synHelper.completedStatu = CloseUnderListen;
            [_synHelper startSpeaking:@"已经为您取消"];
            
        }
    }
    else
    {
        NSMutableString *names = [NSMutableString string];
        for (FilterContact *contact in _matchingArray) {
            [names appendFormat:@"%@ ",contact.fullName];
        }
        [names appendString:@"请选择第几个?"];
        if(![_synHelper isSpeaking])
        {   _synHelper.completedStatu = OpenUnderListen;
            self.choosetype = CHOOSE_CONTACT;
            [_synHelper startSpeaking:names];
        }
    }
    
    
}


- (void)customSemantic:(NSNotification *)notify
{
    NSLog(@"接收到的数据是:%@",notify.object);
    NSString * name = (NSString *)notify.object;
    
    if(self.choosetype == CHOOSE_NAV){
        NSString * result = (NSString *)notify.object;

        if ([result rangeOfString:@"导航"].location !=NSNotFound){
            [self startEmulatorNavi];
            
        }else if ([result rangeOfString:@"取消"].location !=NSNotFound){
            
            if(![_synHelper isSpeaking])
            {   _synHelper.completedStatu = CloseUnderListen;
                [_synHelper startSpeaking:@"已经为您取消"];
                return;
            }
        }

    }
    
    if ([name isEqualToString:@"呼叫"]){
        
        [_synHelper startSpeaking:[NSString stringWithFormat:@"正在为您呼叫%@",_readyContact.fullName]];
        
        if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://10086"]])
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@",[_readyContact.PhoneNumbers firstObject]]]];
        }
    }else if ([name isEqualToString:@"取消"]){
        _readyContact = nil;
        if(![_synHelper isSpeaking])
        {   _synHelper.completedStatu = CloseUnderListen;
            [_synHelper startSpeaking:@"已经为您取消"];
            
        }
    }

    
}

- (void)chooseList:(NSNotification *)notify
{
    NSLog(@"接收到的数据是:%@",notify.object);
    
    NSInteger index = [notify.object integerValue];
    if(self.choosetype == CHOOSE_NAV)
    {
        NSString * result = (NSString *)notify.object;
        if( [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]])
        {
        
        }
        
        if ([result rangeOfString:@"导航"].location !=NSNotFound){
            [self startEmulatorNavi];
            
        }else if ([result rangeOfString:@"取消"].location !=NSNotFound){
            
            if(![_synHelper isSpeaking])
            {   _synHelper.completedStatu = CloseUnderListen;
                [_synHelper startSpeaking:@"已经为您取消"];
                return;
            }
        }

        NSLog(@"########################################");
        //链接百度HUD
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            
        });
        
        
    }
    else if(self.choosetype == CHOOSE_CONTACT)
    {
        NSString * name = (NSString *)notify.object;

        if(0 <= index < self.matchingArray.count)
        {
            _matchContact = self.matchingArray[index];
            if(_matchContact.PhoneNumbers.count > 1)
            {
                if(![_synHelper isSpeaking])
                {   _synHelper.completedStatu = OpenUnderListen;
                    self.choosetype = CHOOSE_PHONENUMBER;
                    [_synHelper startSpeaking:[NSString stringWithFormat:@"为你找到联系人%@,请选择第几个号码?",_matchContact.fullName]];
                }
            }
            else
            {
                if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://10086"]])
                {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@",[_matchContact.PhoneNumbers firstObject]]]];
                }
            }
            
        }else if ([name rangeOfString:@"呼叫"].location !=NSNotFound){
            
            [_synHelper startSpeaking:[NSString stringWithFormat:@"正在为您呼叫%@",_readyContact.fullName]];
            
            if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://10086"]])
            {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@",[_readyContact.PhoneNumbers firstObject]]]];
            }
        }else if ([name rangeOfString:@"取消"].location !=NSNotFound){
            _readyContact = nil;
            if(![_synHelper isSpeaking])
            {   _synHelper.completedStatu = CloseUnderListen;
                [_synHelper startSpeaking:@"已经为您取消"];
                
            }
        }
        
    }
    else if (self.choosetype == CHOOSE_PHONENUMBER)
    {
        NSArray *phones = _matchContact.PhoneNumbers;
        if(0 <= index< phones.count)
        {
            if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://10086"]])
            {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@",phones[index]]]];
            }
            
        }
        
    }
}

- (void)underStanderStartListen
{
    [_underHelper startListening];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self saveContactBookToRealmForQuery];
    self.curResult = [[NSMutableString alloc]init];
    self.grammarType = GRAMMAR_TYPE_ABNF;
    _isUploading = YES;
    self.uploader = [[IFlyDataUploader alloc] init];
    
    
    //设置语义单例
    _underHelper = [IFlySpeechUnderHelper shareInstance];
    //设置语音合成单例
    _synHelper = [IFlySpeechSynHelper shareInstance];
    //设置监听语义理解返回的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(navInfo:) name:@"ROUTE" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callSomeOne:) name:@"CALL" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chooseList:) name:@"ANSWER" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(customSemantic:) name:@"UNSemantic" object:nil];
    //设置监听合成语音返回的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(underStanderStartListen) name:@"SpeakingFinished" object:nil];
    
    
    self.startUrl=[[NSBundle mainBundle]URLForResource:@"start_record.wav" withExtension:nil];
    
    self.overUrl=[[NSBundle mainBundle]URLForResource:@"record_over.wav" withExtension:nil];

    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    
    
    btn.frame = CGRectMake(100, 100, 100, 100);
    [btn setTitle:@"播报" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(startRecBtn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    //    [self performSelector:@selector(startRecBtn) withObject:nil/*可传任意类型参数*/ afterDelay:2.0];
    
    
}
- (void)startRecBtn
{
    
    //保存录音文件，保存在sdk工作路径中，如未设置工作路径，则默认保存在library/cache下
    [_iFlySpeechRecognizer setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
    
    [_synHelper startSpeaking:@"请问有什么帮你"];
    if (_synHelper.isSpeaking) {
        
        _synHelper.completedStatu = OpenUnderListen;
    }
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //        [self initRecognizer];
    //        [self initSynthesizer];
    [self initMapView];
    
}

-(void)viewDidAppear:(BOOL)animated
{
    
    self.mapView.centerCoordinate = self.mapView.userLocation.location.coordinate;


}

- (void)viewWillDisappear:(BOOL)animated
{
    [_iFlySpeechRecognizer cancel];//终止识别
    [_iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
    [_synHelper stopSpeaking];
    [_underHelper cancel];
    [super viewWillDisappear:animated];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
#pragma mark----------讯飞相关方法

/**
 设置识别参数
 ****/
-(void)initRecognizer
{
    //语法识别实例
    
    //单例模式，无UI的实例
    if (_iFlySpeechRecognizer == nil) {
        _iFlySpeechRecognizer = [IFlySpeechRecognizer sharedInstance];
    }
    _iFlySpeechRecognizer.delegate = self;
    
    if (_iFlySpeechRecognizer != nil) {
        IATConfig *instance = [IATConfig sharedInstance];
        
        //设置听写模式
        [_iFlySpeechRecognizer setParameter:@"asr" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
        //设置听写结果格式为json
        [_iFlySpeechRecognizer setParameter:@"json" forKey:[IFlySpeechConstant RESULT_TYPE]];
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
    }
}

- (void)uploadGrammar
{
    _isUploading = YES;
    [_iFlySpeechRecognizer stopListening];
    NSString *grammarContent = nil;
    //设置字符编码
    [_iFlySpeechRecognizer setParameter:@"utf-8" forKey:[IFlySpeechConstant TEXT_ENCODING]];
    //设置识别模式
    [_iFlySpeechRecognizer setParameter:@"asr" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
    
    //根据type去获取联系人列表(微信or通讯录)
    grammarContent = [self buildGrammar];
    //    grammarContent = @"#ABNF 1.0 UTF-8;\nlanguage zh-CN;\nmode voice;\nroot $main;\n$main = $callstart 给 $contact;\n$callstart = 发微信|打电话;\n$contact = BellKate|HigginsDaniel|AppleseedJohn|HaroAnna|ZakroffHank|TaylorDavid|似水流年|章守江|cam|刁大璋|小罗|Rice|Yj|DO|gloomy|mona|谭灵辉||杰|胡书波|TK|风|悠悠沐|康夺|Kyle|lxz|MrMiu|樊建国|认识你真好|周周|刘耀|KVO|刘鹏|晚安|杨鸥|高飞|冯斯托洛夫斯基|井中鱿鱼|小宝贝|亮|海伦||gavin|Yuen|志|胡豆豆|michael|文刀三吉|李鹏飞|樊波音|淀Rebecca|A丑男|luorong|Silence|何金灿|Alen|A緋聞男友|青栀|小惠|姓钟名能|操作操作杆的操作杆|other|TomWong|UNCLE明|热血康诚|LS|邓日娜|刘祯Rina|桃桃籽|森|苏非|聪聪|穷得瑟|Hubery|Ron|John|MrY|任鸿祥|For丨丶Tomorrow|kody|延|露露|Lotus|Alan斌|三朵金花|令狐绯;\n";
    NSLog(@"#############语法文件%@",grammarContent);
    
    //上传
    //开始构建
    [_iFlySpeechRecognizer buildGrammarCompletionHandler:^(NSString * grammerID, IFlySpeechError *error){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (![error errorCode]) {
                
                NSLog(@"errorCode=%d",[error errorCode]);
                
                NSLog(@"上传成功");
                [SVProgressHUD showSuccessWithStatus:@"联系人初始成功,欢迎使用"];
                _isUploading = NO;
            }
            else {
                
                NSLog(@"上传失败%d",[error errorCode]);
                _isUploading = NO;
            }
            
            _cloudGrammerid = grammerID;
            
            //设置grammarid
            [_iFlySpeechRecognizer setParameter:_cloudGrammerid forKey:[IFlySpeechConstant CLOUD_GRAMMAR]];
        });
        
    }grammarType:self.grammarType grammarContent:grammarContent];
}

- (NSString *)buildGrammar{
    NSMutableString *abnf = [NSMutableString string];
    
    
    NSString *gramer = @"#ABNF 1.0 UTF-8;\nlanguage zh-CN;\nmode voice;\nroot $main;\n$main = $callstart 给 $contact;\n$callstart = 发微信|打电话;\n";
    
    //处理通讯录联系人非法字符
    
    IFlyContact *iFlyContact = [[IFlyContact alloc] init];
    NSString *contacts = [iFlyContact contact];
    [abnf appendString:gramer];
    [abnf appendString:@"$contact ="];
    //   //处理非法字符
    NSArray * arr = [contacts componentsSeparatedByString:@"\n"];
    NSMutableArray *contactArray = [NSMutableArray arrayWithArray:arr];
   
    NSString *conact = [[abnf substringToIndex:abnf.length-1] stringByAppendingString:@";\n"];
    return conact;
    
}

-(BOOL) isCommitted
{
    if (_cloudGrammerid == nil || _cloudGrammerid.length == 0) {
        return NO;
    }
    
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(NSMutableArray *)objArry
{
    if (_objArry == nil) {
        _objArry = [NSMutableArray array];
    }
    
    return _objArry;
}

-(void)initTableView
{
    UITableView *tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, kScreenHeight*0.5) style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:tableView];
    self.tableView = tableView;

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
    
    addressStr = [NSString stringWithFormat:@"您即将到达的目的地位于：%@%@%@。请问导航还是取消",obj.city,obj.district,obj.name];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [_synHelper startSpeaking:addressStr];
        
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
            [_synHelper startSpeaking:soundString];
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
        [_synHelper stopSpeaking];
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


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
