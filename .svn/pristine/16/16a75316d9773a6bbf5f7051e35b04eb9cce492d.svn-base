//
//  CZMusicTool.m
//  A01_传智音乐
//
//  Created by apple on 15-3-2.
//  Copyright (c) 2015年 apple. All rights reserved.
//

#import "CZMusicTool.h"

#import "BroadcastingModel.h"

@interface CZMusicTool()



@end

@implementation CZMusicTool
singleton_implementation(CZMusicTool)

-(void)prepareToPlayWithMusic:(BroadcastingModel *)music{
    //创建播放器
    self.queue = [[NSOperationQueue alloc] init];
    self.player = [[AVAudioPlayer alloc] initWithData:self.audioData error:nil];
    
    NSBlockOperation *operation1 = [NSBlockOperation blockOperationWithBlock:^(){
        [self.queue cancelAllOperations];
        NSURL *musicURL = [NSURL URLWithString:music.muc_url];
        self.audioData = [NSData dataWithContentsOfURL:musicURL];
        NSLog(@"执行第1次操作，线程：%@", [NSThread currentThread]);
    }];
    
    
    [self.queue addOperation:operation1];
    
    
    //准备
    [self.player prepareToPlay];
}


-(void)play{
    [self.player play];
}


-(void)pause{
    [self.player pause];
}
@end
