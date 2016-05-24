//
//  VoiceDialViewController.m
//  WayMisc
//
//  Created by xinmeiti on 16/5/19.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "VoiceDialViewController.h"
#import <AddressBook/AddressBook.h>
#import "PopupView.h"
#import "ISRDataHelper.h"
#import "IATConfig.h"
#import "Person.h"

typedef enum{
    SpeakPlaying = 0,
    SpeakPAUSE = 1,
    SpeakFinish = 2,
} currentState;
@interface VoiceDialViewController ()
{
   NSInteger searchIndex;
    NSString *tel;
}

@property (nonatomic ,strong) NSMutableArray*PersonArray;
@property (nonatomic,assign) NSInteger State; //操作类型

@end

@implementation VoiceDialViewController

-(NSMutableArray *)PersonArray
{
    if (_PersonArray == nil) {
        _PersonArray = [NSMutableArray array];
    }
    return _PersonArray;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    searchIndex = 0;//查询次数，默认为0
    
    _textView.layer.borderWidth = 0.5f;
    _textView.layer.borderColor = [[UIColor whiteColor] CGColor];
    [_textView.layer setCornerRadius:7.0f];
    
    CGFloat posY = self.textView.frame.origin.y+self.textView.frame.size.height/6;
    _popUpView = [[PopupView alloc] initWithFrame:CGRectMake(100, posY+64, 0, 0) withParentView:self.view];
    
    [self.view addSubview:_popUpView];
    
    self.uploader = [[IFlyDataUploader alloc] init];
    
    //demo录音文件保存路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [paths objectAtIndex:0];
    _pcmFilePath = [[NSString alloc] initWithFormat:@"%@",[cachePath stringByAppendingPathComponent:@"asr.pcm"]];

    
//    [self upContactBtnHandler:nil];
    
}

-(void)AddressBookResult:(NSString *)str
{
    // 1.获取用户的授权状态
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    
    // 2.如果授权状态是授权成功
    if (status != kABAuthorizationStatusAuthorized)  return;
    
    // 3.获取通信录对象
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    // 4.获取到所有联系人记录
    CFArrayRef peopleArray = ABAddressBookCopyArrayOfAllPeople(addressBook);
    
    
    
    // 5.遍历所有的联系人记录
    CFIndex peopleCount = CFArrayGetCount(peopleArray);
    for (CFIndex i = 0; i < peopleCount; i++) {
        Person *per = [[Person alloc]init];

        // 5.1.获取到具体的联系人
        ABRecordRef person = CFArrayGetValueAtIndex(peopleArray, i);
        
        
        
        // 5.2.获取联系人的姓名
        NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
        NSLog(@"%@---%@", firstName, lastName);
        NSString *fullName = [NSString stringWithFormat:@"%@%@",lastName,firstName];
        fullName = [fullName stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
        if ([str isEqualToString:fullName]) {
            [self.PersonArray removeAllObjects];
            per.fullName = fullName;
            
            NSMutableArray *numbers = [NSMutableArray array];
            
            // 5.3.获取联系人的电话
            ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
            CFIndex phoneCount = ABMultiValueGetCount(phones);
            
            for (CFIndex i = 0; i < phoneCount; i++) {
                NSString *phoneLabel = (__bridge_transfer NSString *)ABMultiValueCopyLabelAtIndex(phones, i);
                
                NSString *phoneValue = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phones, i);
                
                [numbers addObject:phoneValue];
                NSLog(@"%@---%@",phoneLabel, phoneValue);
            }
            per.numbers = numbers;
            
            // 5.4.释放该释放的对象
            CFRelease(phones);
            [self.PersonArray addObject:per];

        }
        
    }
    
    // 6.释放该释放的对象
    CFRelease(addressBook);
    CFRelease(peopleArray);

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = @"语音通话";
    self.view.backgroundColor = [UIColor blackColor];
    //    self.navigationController.navigationBar.barStyle    = UIBarStyleBlack;
    //    self.navigationController.navigationBar.translucent = NO;
    //    self.navigationController.toolbar.barStyle          = UIBarStyleBlack;
    //    self.navigationController.toolbar.translucent       = NO;
    //    self.navigationController.toolbarHidden             = NO;
    
    //    [self initToolBar];
    
    
    [self initIFlySpeech];//初始化识别对象
    [self initRecognizer];

    [self setContactPerson];
    

    
    
}

-(void)setContactPerson
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [_iFlySpeechSynthesizer startSpeaking:@"请问您呼叫谁"];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
        
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            // code to be executed on the main queue after delay
//            [self startBtnHandler:nil];
            [self onlinRecBtnHandler:nil];
            
        });
    });
    
    
}

#pragma mark - iFlySpeechSynthesizer Delegate

- (void)onCompleted:(IFlySpeechError *)error
{
    if(self.State == SpeakPlaying){
        self.State = SpeakFinish;

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
        NSLog(@"听写结果(json)：%@测试",  self.result);
        if ([resultFromJson rangeOfString:@"呼叫"].location !=NSNotFound) {
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC);
            
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                // code to be executed on the main queue after delay
                
                NSMutableString * str=[[NSMutableString alloc] initWithFormat:@"tel://%@",tel];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:str]];
            });

        }else if([resultFromJson rangeOfString:@"取消"].location !=NSNotFound){
            [self cancelBtnHandler:nil];
            [self stopBtnHandler:nil];

        }else{
            
            [self cancelBtnHandler:nil];
            [self stopBtnHandler:nil];
            
            
            [self AddressBookResult:@"东风"];
            
            NSMutableString *strResult = [[NSMutableString alloc]init];

            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC);
            
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                // code to be executed on the main queue after delay
                //            [self startBtnHandler:nil];
                
                if(self.PersonArray.count>0){
                    
                    if (self.PersonArray.count != 1) {
                        //不唯一
                        for (int i = 0; i<self.PersonArray.count; i++) {
                            Person*per = self.PersonArray[i];
                            NSString *fullName = per.fullName;
                            NSString *num = per.numbers[0];
                            [strResult appendString:[NSString stringWithFormat:@"第%i位%@%@;",i+1,fullName,[num substringToIndex:3]]];
                            self.State = SpeakPlaying;
                        }
                        
                    }else{
                        //唯一

                        Person*per = self.PersonArray[0];
                        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                        });
                        if (per.numbers.count>1) {
                            [strResult appendString:@"呼叫以下哪个联系人："];
                            for (int i = 0; i<per.numbers.count; i++) {
                                NSString *fullName = per.fullName;
                                NSString *num = per.numbers[i];
                                
                                [strResult appendString:[NSString stringWithFormat:@"第%i位%@%@;",i+1,fullName,[num substringToIndex:3]]];
                                    
                            }
                            
                        }else{
                            [strResult appendString:[NSString stringWithFormat:@"为您找到%@%@",per.fullName,[per.numbers[0] substringToIndex:3]]];
                        }
                        
                    }
                    if (self.State == SpeakFinish) {
                        self.State = SpeakPlaying;
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                            [_iFlySpeechSynthesizer startSpeaking:strResult];
                            
                        });
                        
                    }

                    
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (0.3*strResult.length) * NSEC_PER_SEC);
                    
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        if (self.State == SpeakFinish) {
                            [self startBtnHandler:nil];
                        }
                    });
                    
                }else{
                    NSString *str;
                    if (searchIndex <3) {
                        str = @"没听清楚，再说一遍";
                    }else{
                        searchIndex ++;
                        str = @"呼叫失败，请稍后再试";
                    }
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                        [_iFlySpeechSynthesizer startSpeaking:str];
                    });
                    
                    
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (0.3*str.length) * NSEC_PER_SEC);
                    
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        if (self.State == SpeakFinish) {
                            [self startBtnHandler:nil];
                        }
                    });
                }

            });

        }

    }
    
        

    
    NSLog(@"_result=%@",_result);
    NSLog(@"resultFromJson=%@",resultFromJson);
    
    
    
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



- (void)initIFlySpeech
{
    NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@,timeout=%@",@"56e5080e",@"20000"];
    [IFlySpeechUtility createUtility:initString];
    
    if (self.iFlySpeechUnderstander == nil) {
        _iFlySpeechUnderstander = [IFlySpeechUnderstander sharedInstance];
        _iFlySpeechUnderstander.delegate = self;

    }
    
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
/**
 设置识别参数
 ****/
-(void)initRecognizer
{
    
    //语义理解单例
    if (_iFlySpeechUnderstander == nil) {
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


- (void)onlinRecBtnHandler:(id)sender {
    [_textView setText:@""];
    [_textView resignFirstResponder];
    
    //设置为麦克风输入语音
    [_iFlySpeechUnderstander setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];
    
    bool ret = [_iFlySpeechUnderstander startListening];
    
    if (ret) {
        
        
        self.isCanceled = NO;
    }
    else
    {
        [_popUpView showText: @"启动识别服务失败，请稍后重试"];//可能是上次请求未结束
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [_iFlySpeechRecognizer cancel]; //取消识别
    [_iFlySpeechRecognizer setDelegate:nil];
    [_iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
    
    [_iFlySpeechUnderstander cancel];//终止语义
    [_iFlySpeechUnderstander setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
    [super viewWillDisappear:animated];
    
    [_iFlySpeechUnderstander destroy];

    
    [_iFlySpeechSynthesizer stopSpeaking];
    
    _iFlySpeechSynthesizer.delegate = nil;

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
