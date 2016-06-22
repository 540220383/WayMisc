//
//  ViewController.m
//  WayMisc
//
//  Created by chinatsp on 16/5/9.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "ViewController.h"
#import "FlowLayout.h"
#import "BroadcastingModel.h"
#import "RadioProgramsCell.h"
#import "LinkServiceWay.h"
#import "MJExtension.h"
#import "WMPlayer.h"
#import "PlayerView.h"
#import "MJRefresh.h"
#import "FoldTableViewController.h"
#import "DeviceListViewController.h"
#import "BabyBluetooth.h"
#import "ConnetcViewController.h"
#import "NaviViewController.h"
#import "VoiceDialViewController.h"
#import "PlayerAnimation.h"
#import "SVProgressHUD.h"
#import "BleDataWriteTool.h"
#import "AFNetworking.h"
@interface ViewController ()<SlideNavigationControllerDelegate,HMWaterflowLayoutDelegate,UICollectionViewDataSource,UICollectionViewDelegate,UIGestureRecognizerDelegate,ConnetcDelegate>
{
    NSInteger _page;
    BOOL isPlay;
    NSIndexPath *tmpIndexPath;
    UIImageView *moveImg;
}
@property (weak, nonatomic) IBOutlet UIButton *infoButton;
@property (weak, nonatomic) IBOutlet FlowLayout *flowLayout;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property(assign, nonatomic)NSInteger musicIndex;//当前播放音乐索引
@property(strong,nonatomic) WMPlayer*wmPlayer;
@property(strong,nonatomic) NSMutableArray *musics;//音乐数据
@property(strong,nonatomic) PlayerView*playerView;

@property(nonatomic ,strong) NSMutableDictionary *listDictionary;

@end

@implementation ViewController

-(void)setBabyDelegate
{

    if ([SlideNavigationController sharedInstance].currPeripheral) {
        [self setNotiWith:[SlideNavigationController sharedInstance].baby];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [SlideNavigationController sharedInstance].FMLinkView.hidden = ![[DeviceInfo Instance]getFMState];
    
    //默认page
    _page = 1;
    
    self.playerView = [[NSBundle mainBundle]loadNibNamed:@"PlayerView" owner:nil options:nil][0];
    
    [self.playerView.Cover addTarget:self action:@selector(playOrPause) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.playerView];
    
    self.playerView.leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)];
    self.playerView.rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)];
    self.playerView.leftSwipeGestureRecognizer.delegate = self;
    self.playerView.rightSwipeGestureRecognizer.delegate = self;
    self.playerView.leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    self.playerView.rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    
    [self.playerView addGestureRecognizer:self.playerView.leftSwipeGestureRecognizer];
    [self.playerView addGestureRecognizer:self.playerView.rightSwipeGestureRecognizer];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(autoPlayNetx:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    
    self.listDictionary = [[NSMutableDictionary alloc]init];
    [self.listDictionary setObject:[NSString stringWithFormat:@"%d",_page] forKey:@"pageNo"];
    [self loadNetWorkData:@"old"];
    
    
    //设置列数
    self.flowLayout.colCount = 2;
    self.flowLayout.delegate = self;
    self.MainCollection.delegate = self;
    self.MainCollection.dataSource = self;
    
    self.MainCollection.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewData)];
    self.MainCollection.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadOldData)];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self performSelector:@selector(setBabyDelegate) withObject:nil/*可传任意类型参数*/ afterDelay:2.0];
    [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(isConnect) userInfo:nil repeats:YES];
    
    
}


-(void)loadNetWorkData:(NSString*)type
{
    
    
    [self.listDictionary setObject:@"2" forKey:@"apkType"];
    [self.listDictionary setObject:@"B807B4A298FBABDF129E53EFB7813E01" forKey:@"APIToken"];
    
    [self.listDictionary setObject:@"20" forKey:@"pageSize"];
    
    [[AFHTTPSessionManager manager]POST:[LinkServiceURL  stringByAppendingString:@"/music/getMusicList.do"] parameters:self.listDictionary progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        NSLog(@"%@",responseObject);
        if ([responseObject[@"bodys"] isKindOfClass:[NSArray class]]) {
            NSArray *dataArray = responseObject[@"bodys"];
            
            NSArray *tmp = [BroadcastingModel mj_objectArrayWithKeyValuesArray:dataArray];
            
            if ([type isEqualToString:@"New"]) {
                [self.musics removeAllObjects];
                
                [self.MainCollection.mj_header endRefreshing];
            }else{
                
                [self.MainCollection.mj_footer endRefreshing];
            }
            [self.musics addObjectsFromArray:tmp];
            [self.MainCollection reloadData];
            
            
            static dispatch_once_t predicate;
            dispatch_once(&predicate, ^{
                self.musicIndex = 0;
                _wmPlayer.state = WMPlayerStatePause;
                [self updateCurrentMusicDetailModel];
                [self.playerView setCoverNormalImage:@"footplayer_pause"];
                
                [[_wmPlayer player]pause];
                
            });
            
            
        }else{
            
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@",error);
        
    }];
}

-(void)loadNewData
{
    
    [self.listDictionary setObject:@"1" forKey:@"pageNo"];
    
    [self loadNetWorkData:@"New"];
    
}

-(void)loadOldData
{
    _page++;
    
    [self.listDictionary setObject:[NSString stringWithFormat:@"%d",_page] forKey:@"pageNo"];
    
    [self loadNetWorkData:@"old"];
    
}
-(NSMutableArray *)musics
{
    if (_musics == nil) {
        _musics = [[NSMutableArray alloc]init];
    }
    
    return _musics;
}

//更新当前将要播放的音乐模型
-(void)updateCurrentMusicDetailModel
{
    
    [self.wmPlayer.player replaceCurrentItemWithPlayerItem:nil];
    BroadcastingModel*model = _musics[self.musicIndex];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.playerView.broad = model;
        [self.wmPlayer setVideoURLStr:model.muc_url];
        
    });
    NSUInteger section = 0;
    NSUInteger row = self.musicIndex;
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    RadioProgramsCell * cell = (RadioProgramsCell *)[self.MainCollection cellForItemAtIndexPath:indexPath];
    
    cell.playerStateIcon.image = [UIImage imageNamed:@"playerlist_play"];
    [self.playerView setCoverNormalImage:@"footplayer_play"];
    [[_wmPlayer player] play];
    
    cell.playerStateIcon.hidden = NO;
}

-(void)removePlayerLayer
{
    [moveImg.layer removeAllAnimations];
    [moveImg removeFromSuperview];
    moveImg = nil;
}

- (void)playOrPause{
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.musicIndex inSection:0];
    RadioProgramsCell *cell = (RadioProgramsCell *)[self.MainCollection cellForItemAtIndexPath:indexPath];
    
    
    if (_wmPlayer.state == WMPlayerStatePlaying) {
        _wmPlayer.state = WMPlayerStatePause;
        [[_wmPlayer player]pause];
        [self.playerView setCoverNormalImage:@"footplayer_pause"];
        cell.playerStateIcon.image = [UIImage imageNamed:@"playerlist_pause"];

        
    }else{
        _wmPlayer.state = WMPlayerStatePlaying;
        [[_wmPlayer player]play];
        [self.playerView setCoverNormalImage:@"footplayer_play"];
        cell.playerStateIcon.image = [UIImage imageNamed:@"playerlist_play"];
        
    }
    
}

-(void)Previous
{
    if(self.musicIndex > 0){
        [self refreshUI];
        self.musicIndex--;
        [self updateCurrentMusicDetailModel];
        
        [UIView animateWithDuration:0.35 animations:^{
            CGPoint labelPosition = CGPointMake(self.playerView.frame.origin.x + (kScreenWidth*0.5), self.playerView.frame.origin.y);
            self.playerView.frame = CGRectMake( labelPosition.x , labelPosition.y , self.playerView.frame.size.width, self.playerView.frame.size.height);
        } completion:^(BOOL finished) {
            
            self.playerView.frame = CGRectMake( 0 , 0 , self.playerView.frame.size.width, self.playerView.frame.size.height);
        }];

    }
    
}
-(void)next
{
    if(self.musicIndex<_musics.count){
        [self refreshUI];
        self.musicIndex++;
        [self updateCurrentMusicDetailModel];

        
        [UIView animateWithDuration:0.35 animations:^{
            CGPoint labelPosition = CGPointMake(self.playerView.frame.origin.x - (kScreenWidth*0.5), self.playerView.frame.origin.y);
            self.playerView.frame = CGRectMake( labelPosition.x , labelPosition.y , self.playerView.frame.size.width, self.playerView.frame.size.height);
        } completion:^(BOOL finished) {
            self.playerView.frame = CGRectMake( 0 , 0 , self.playerView.frame.size.width, self.playerView.frame.size.height);
        }];
    }
    
}

-(void)autoPlayNetx:(NSNotification *)notification {
    [self next];
    
}


- (void)handleSwipes:(UISwipeGestureRecognizer *)sender
{
    if (sender.direction == UISwipeGestureRecognizerDirectionLeft) {
        [self next];
    }
    
    if (sender.direction == UISwipeGestureRecognizerDirectionRight) {
        [self Previous];
    }
}

#pragma mark ----- SlideNavigationControllerDelegate
- (BOOL)slideNavigationControllerShouldDisplayRightMenu
{
    return YES;
}

-(WMPlayer *)wmPlayer{
    if (!_wmPlayer) {
        _wmPlayer = [SlideNavigationController sharedInstance].wmPlayer;
    }
    return _wmPlayer;
}

- (IBAction)showInfo:(UIButton *)sender
{
    FoldTableViewController *notice = [[FoldTableViewController alloc]init];
    
    [self presentViewController:notice animated:YES completion:nil];
    
}



#pragma mark
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.musics.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    RadioProgramsCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    BroadcastingModel *model = self.musics[indexPath.row];
    cell.backgroundColor = kColorWithRGBA(34, 36, 35,1);
    cell.broad = model;
   
    if (indexPath.row == self.musicIndex) {
        cell.playerStateIcon.image = _wmPlayer.state == WMPlayerStatePlaying? [UIImage imageNamed:@"playerlist_play"]: [UIImage imageNamed:@"playerlist_pause"];
               model.isPlay = YES;
    }
    cell.playerStateIcon.hidden = model.isPlay?NO:YES;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (indexPath.row == 0) {
            cell.playerStateIcon.image = [UIImage imageNamed:@"playerlist_pause"];
            cell.playerStateIcon.hidden = NO;
        }
    });
   
    return cell;
}


-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    BroadcastingModel *model = self.musics[indexPath.row];
    model.isPlay = YES;
    
    self.playerView.broad = model;
    
    if (self.musicIndex == indexPath.row){
        [self playOrPause];
    }else{
        _wmPlayer.state = WMPlayerStatePlaying;
         RadioProgramsCell *cell = (RadioProgramsCell *)[collectionView cellForItemAtIndexPath:indexPath];
        cell.playerStateIcon.hidden = NO;
    
        
        [self refreshUI];
        
        //更改索引
        self.musicIndex = indexPath.row;
        
        [self updateCurrentMusicDetailModel];
        
        if (moveImg == nil) {
             moveImg = [[UIImageView alloc]initWithImage:cell.coverImageView.image];
        }
        moveImg.frame = CGRectMake(0, 0, kPlayImageW*2, kPlayImageW*2);
        moveImg.layer.cornerRadius = kPlayImageW;
        moveImg.clipsToBounds = YES;
        CGPoint startPoint = CGPointMake(cell.center.x, cell.center.y - collectionView.contentOffset.y);
        
        CAKeyframeAnimation *showAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
        showAnimation.additive = YES; // Make the values relative to the current value
        showAnimation.values = @[[NSNumber numberWithFloat:0], [NSNumber numberWithFloat:2*M_PI]];
        showAnimation.duration = 1.5;
        showAnimation.delegate = self;
        
        //开演
        [moveImg.layer addAnimation:[PlayerAnimation initMoveLayer:startPoint] forKey:@"moveAnimation"];
        [moveImg.layer addAnimation:showAnimation forKey:@"rotateAnimation"];
      

        [self.view addSubview:moveImg];
        
        [self performSelector:@selector(removePlayerLayer) withObject:nil/*可传任意类型参数*/ afterDelay:2.0];

    }
    
    
}

-(void)refreshUI
{
    BroadcastingModel *model = self.musics[self.musicIndex];
    model.isPlay = NO;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.musicIndex inSection:0];
    RadioProgramsCell *cell = (RadioProgramsCell *)[self.MainCollection cellForItemAtIndexPath:indexPath];
    cell.playerStateIcon.hidden = YES;
    
    
}

- (CGFloat)waterflowLayout:(FlowLayout *)waterflowLayout heightForWidth:(CGFloat)width atIndexPath:(NSIndexPath *)indexPath
{
    BroadcastingModel *broad = self.musics[indexPath.item];
    CGFloat height = [broad.muc_name heightWithFont:[UIFont systemFontOfSize:13] withinWidth:width-25];
    
    CGFloat totalHeight = height + (kScreenWidth-25)/2+30;
    
    return totalHeight;
}




#pragma mark - UIGestureRecognizerDelegate

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer.view isKindOfClass:[PlayerView class]]) {
        return YES;
    }
    return NO;
}
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([gestureRecognizer.view isKindOfClass:[PlayerView class]]) {
        return YES;
    }
    return NO;
}
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[PlayerView class]]) {
        return YES;
    }
    return NO;

}
-(void)setNotiWith:(BabyBluetooth *)ble
{
    
    __weak typeof(self)weakSelf = self;
    
    
    BabyRhythm *rhythm = [[BabyRhythm alloc]init];
    
    [rhythm beats];
    
    //设置设备连接成功的委托,同一个baby对象，使用不同的channel切换委托回调
    [ble setBlockOnConnectedAtChannel:channelOnPeropheralView block:^(CBCentralManager *central, CBPeripheral *peripheral) {
        [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"设备：%@--连接成功",peripheral.name]];
    }];
    
    //设置设备连接失败的委托
    [ble setBlockOnFailToConnectAtChannel:channelOnPeropheralView block:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备：%@--连接失败",peripheral.name);
        [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"设备：%@--连接失败",peripheral.name]];
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"连接失败" message:[NSString stringWithFormat:@"%ld",central.state] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
        
    }];
    
    
    //设置读取characteristics的委托
    
    [ble setBlockOnReadValueForCharacteristicAtChannel:channelOnCharacteristicView block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
            NSLog(@"CharacteristicViewController===characteristic name:%@ value is:%@",characteristics.UUID,characteristics.value);
    }];
    //设置发现characteristics的descriptors的委托
    [ble setBlockOnDiscoverDescriptorsForCharacteristicAtChannel:channelOnCharacteristicView block:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        //        NSLog(@"CharacteristicViewController===characteristic name:%@",characteristic.service.UUID);
        for (CBDescriptor *d in characteristic.descriptors) {
            //            NSLog(@"CharacteristicViewController CBDescriptor name is :%@",d.UUID);
            //            [weakSelf insertDescriptor:d];
        }
    }];
    //设置读取Descriptor的委托
    [ble setBlockOnReadValueForDescriptorsAtChannel:channelOnCharacteristicView block:^(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) {
        //        for (int i =0 ; i<descriptors.count; i++) {
        //            if (descriptors[i]==descriptor) {
        //                UITableViewCell *cell = [weakSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:2]];
        //                //                NSString *valueStr = [[NSString alloc]initWithData:descriptor.value encoding:NSUTF8StringEncoding];
        //                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",descriptor.value];
        //            }
        //        }
        NSLog(@"CharacteristicViewController Descriptor name:%@ value is:%@",descriptor.characteristic.UUID, descriptor.value);
    }];
    
    //设置写数据成功的block
    [ble setBlockOnDidWriteValueForCharacteristicAtChannel:channelOnCharacteristicView block:^(CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"setBlockOnDidWriteValueForCharacteristicAtChannel characteristic:%@ and new value:%@",characteristic.UUID, [[NSString alloc]initWithData:characteristic.value encoding:NSASCIIStringEncoding]);
    }];
    
    //设置通知状态改变的block
    [ble setBlockOnDidUpdateNotificationStateForCharacteristicAtChannel:channelOnCharacteristicView block:^(CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"uid:%@,isNotifying:%@",characteristic.UUID,characteristic.isNotifying?@"on":@"off");
    }];
    
    [[SlideNavigationController sharedInstance].currPeripheral setNotifyValue:YES forCharacteristic:[SlideNavigationController sharedInstance].characteristic];
    
    
    
    [ble notify:[SlideNavigationController sharedInstance].currPeripheral characteristic:[SlideNavigationController sharedInstance].characteristic
           block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
               NSLog(@"notify block");
               
               NSString *value =[[NSString alloc]initWithData:characteristics.value encoding:NSASCIIStringEncoding];
               
               NSLog(@"new value %@",value);
               
        
               if ([value isEqualToString:@"next"]) {
                   [self next];
               }else if ([value isEqualToString:@"previ"]){
                   [self Previous];
               }else if ([value isEqualToString:@"play"]){
                   [self playOrPause];
               }else if ([value isEqualToString:@"dh"]){
                   NaviViewController *navi = [[NaviViewController alloc]init];
                   
                   
                   [[SlideNavigationController sharedInstance] pushViewController:navi animated:YES];
                   [[[SlideNavigationController sharedInstance].wmPlayer player]pause];
               }else if ([value isEqualToString:@"bh"]){
                   VoiceDialViewController *voiceDial = [[VoiceDialViewController alloc]init];
                   
                   
                   [[SlideNavigationController sharedInstance] pushViewController:voiceDial animated:YES];
                   //        [self presentViewController:navi animated:YES completion:nil];
                   [[[SlideNavigationController sharedInstance].wmPlayer player]pause];
               }
               
           }];
    
    [ble setBlockOnCentralManagerDidUpdateStateAtChannel:channelOnCharacteristicView block:^(CBCentralManager *central) {
        NSLog(@"%ld",central.state);
        
        
      
    }];
    
    ble.channel(channelOnCharacteristicView).characteristicDetails([SlideNavigationController sharedInstance].currPeripheral,[SlideNavigationController sharedInstance].characteristic);
    
    ble.channel(channelOnPeropheralView).characteristicDetails([SlideNavigationController sharedInstance].currPeripheral,[SlideNavigationController sharedInstance].characteristic);
    
    [weakSelf writeValue];
    
}

-(void)isConnect
{
    if ([SlideNavigationController sharedInstance].baby!=nil&&[SlideNavigationController sharedInstance].currPeripheral.state!= CBPeripheralStateConnected) {
        
        [SlideNavigationController sharedInstance].baby.having([SlideNavigationController sharedInstance].currPeripheral).and.channel(channelOnPeropheralView).then.connectToPeripherals().discoverServices().discoverCharacteristics().readValueForCharacteristic().discoverDescriptorsForCharacteristic().readValueForDescriptors().begin();
     
        [self performSelector:@selector(setBabyDelegate) withObject:nil/*可传任意类型参数*/ afterDelay:2.0];
    }
    
}

-(void)writeValue{
    //    int i = 10;
//    Byte b[] = {0x03,3,5};
    //    NSData *data = [NSData dataWithBytes:&b length:sizeof(b)];
    NSData *data = [@"nihao123321" dataUsingEncoding:NSASCIIStringEncoding];
    //    NSData*d = [[NSString stringWithFo   rmat:@"nihao"] dataUsingEncoding:NSASCIIStringEncoding];
    [[SlideNavigationController sharedInstance].currPeripheral writeValue:data forCharacteristic:[SlideNavigationController sharedInstance].characteristic type:CBCharacteristicWriteWithResponse];
    
    NSLog(@"%@",[[SlideNavigationController sharedInstance].baby readValueForCharacteristic]);
}





@end
