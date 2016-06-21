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

#import "ContactHelper.h"
#import "FilterContact.h"
#define GRAMMAR_TYPE_ABNF    @"abnf"


typedef NS_ENUM(NSInteger, ChooseType){
    CHOOSE_NAV,//导航
    CHOOSE_CONTACT,//通讯录
    CHOOSE_PHONENUMBER//电话
};
@interface SpeechViewController ()<IFlySpeechRecognizerDelegate,UITableViewDataSource,UITableViewDelegate>
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

//是否正在上传
@property (nonatomic, assign) BOOL isUploading;

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
    //开始poi搜索
    
}
- (void)callSomeOne:(NSNotification *)notify
{
    self.choosetype = CHOOSE_CONTACT;
    NSLog(@"接收到的数据是:%@",notify.object);
    NSString * name = (NSString *)notify.object;
    
    NSString *pinyin = [ContactHelper changeHanZiToPinYinWith:name];
    NSString *fuzzyPY = [ContactHelper fuzzyQueryMothedsWith:pinyin];
    //开始搜索数据库模糊匹配
    _matchingArray =[_dataHelper queryContactWithFuzzyName:fuzzyPY];
    if(_matchingArray.count == 0)
    {
        if(![_synHelper isSpeaking])
        {   _synHelper.completedStatu = CloseUnderListen;
            [_synHelper startSpeaking:@"没有为你找到匹配的联系人"];
        }
    }
    else if (_matchingArray.count == 1)
    {
        _matchContact = _matchingArray[0];
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

- (void)chooseList:(NSNotification *)notify
{
    NSLog(@"接收到的数据是:%@",notify.object);
    NSInteger index = [notify.object integerValue];
    if(self.choosetype == CHOOSE_NAV)
    {
        if( [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]])
        {
        
        }
        NSLog(@"########################################");
        //链接百度HUD
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            
        });
        
        
    }
    else if(self.choosetype == CHOOSE_CONTACT)
    {
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


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
