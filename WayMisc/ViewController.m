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
#import "NoticeViewController.h"
@interface ViewController ()<SlideNavigationControllerDelegate,HMWaterflowLayoutDelegate,UICollectionViewDataSource,UICollectionViewDelegate,UIGestureRecognizerDelegate>
{
    NSInteger _page;
    BOOL isPlay;
    NSIndexPath *tmpIndexPath;
}
@property (weak, nonatomic) IBOutlet UIButton *infoButton;
@property (weak, nonatomic) IBOutlet FlowLayout *flowLayout;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property(assign, nonatomic)NSInteger musicIndex;//当前播放音乐索引
@property(strong,nonatomic) WMPlayer*wmPlayer;
@property(strong,nonatomic) NSArray *musics;//音乐数据
@property(strong,nonatomic) PlayerView*playerView;

@end

@implementation ViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
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
    
    [self loadNetWorkData];

    
    //设置列数
    self.flowLayout.colCount = 2;
    self.flowLayout.delegate = self;
    self.MainCollection.delegate = self;
    self.MainCollection.dataSource = self;
    self.automaticallyAdjustsScrollViewInsets = NO;
}


-(void)loadNetWorkData
{
    NSMutableDictionary *listDictionary = [[NSMutableDictionary alloc]init];
    
    [listDictionary setObject:@"2" forKey:@"apkType"];
    [listDictionary setObject:@"B807B4A298FBABDF129E53EFB7813E01" forKey:@"APIToken"];
    [listDictionary setObject:@"1" forKey:@"pageNo"];
    [listDictionary setObject:@"20" forKey:@"pageSize"];

    
    NSData *listData = [LinkServiceWay getResultDataByPost:listDictionary stringLinkService:@"/music/getMusicList.do"];
    NSLog(@"数据列表：%@",[[NSString alloc]initWithData:listData encoding:NSUTF8StringEncoding]);
    if (listData != nil) {
        NSError *error = nil;
        NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:listData options:NSJSONReadingMutableLeaves error:&error];
        if (error == nil) {
            if ([jsonDictionary[@"bodys"] isKindOfClass:[NSArray class]]) {
                NSArray *dataArray = jsonDictionary[@"bodys"];
                
                if (!_musics) {
                    _musics = [BroadcastingModel mj_objectArrayWithKeyValuesArray:dataArray];
                }
                self.musicIndex = 0;
                [self updateCurrentMusicDetailModel];
                [[_wmPlayer player]pause];
                isPlay = YES;
                
            }else{
                
            }
        }else{
            
        }
    }
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
}

- (void)playOrPause{
    isPlay = !isPlay;
    if (isPlay) {
        [[_wmPlayer player]pause];
        [self.playerView setCoverNormalImage:@"footplayer_pause"];
        
    }else{
        [[_wmPlayer player]play];
        [self.playerView setCoverNormalImage:@"footplayer_play"];
    }
    
}

-(void)Previous
{
    if(self.musicIndex > 0){
        [self refreshUI];
        self.musicIndex--;
        [self updateCurrentMusicDetailModel];
    }

    
}
-(void)next
{
    if(self.musicIndex<_musics.count){
        [self refreshUI];
        self.musicIndex++;
        [self updateCurrentMusicDetailModel];
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
        _wmPlayer = [[WMPlayer alloc]initWithFrame:CGRectZero videoURLStr:nil];
    }
    return _wmPlayer;
}

- (IBAction)showInfo:(UIButton *)sender
{
    NoticeViewController *notice = [[NoticeViewController alloc]init];
    
    [self presentViewController:notice animated:YES completion:nil];
    
    NSLog(@"我日");
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
    cell.backgroundColor = kColorWithRGB(34, 36, 35);
    cell.broad = model;
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
        if(!isPlay){
            isPlay = YES;
            [_wmPlayer play];
            [self.playerView setCoverNormalImage:@"footplayer_pause"];

        }else{
            [[_wmPlayer player] play];
            [self.playerView setCoverNormalImage:@"footplayer_play"];
            
        }
        
        [self refreshUI];
        
        //更改索引
        self.musicIndex = indexPath.row;
        
        [self updateCurrentMusicDetailModel];
    }
    

}

-(void)refreshUI
{
    BroadcastingModel *model = self.musics[self.musicIndex];
    model.isPlay = NO;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.musicIndex inSection:0];
    RadioProgramsCell *cell = (RadioProgramsCell *)[self.MainCollection cellForItemAtIndexPath:indexPath];
    cell.playerStateIcon.image = [UIImage imageNamed:@"playerlist_pause"];

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




@end
