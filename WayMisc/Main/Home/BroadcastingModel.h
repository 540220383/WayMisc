//
//  BroadcastingModel.h
//  WayMisc
//
//  Created by chinatsp on 16/5/9.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BroadcastingModel : NSObject

@property (nonatomic, copy)   NSString *create_date;
@property (nonatomic, copy)   NSString *special_name;
@property (nonatomic, copy)   NSString *cid;
@property (nonatomic, copy)   NSString *muc_id;
/**
 *  节目简介
 */
@property (nonatomic, copy)   NSString *muc_name;
@property (nonatomic, copy)   NSString *muc_type;
/**
 *  节目名称
 */
@property (nonatomic, copy)   NSString *user_name;
@property (nonatomic, copy)   NSString *special_id;
@property (nonatomic, copy)   NSString *come_from;
@property (nonatomic, copy)   NSString *come_from_id;
/**
 *  节目播放链接
 */
@property (nonatomic, copy)   NSString *muc_url;
/**
 *  节目封面
 */
@property (nonatomic, copy)   NSString *img_url;
@property (nonatomic, assign) NSInteger muc_long;
@property (nonatomic, assign) NSInteger muc_sort;
@property (nonatomic, assign) NSInteger dup_num;
@property (nonatomic, copy)   NSString *tags;

@property (nonatomic,assign)  BOOL isPlay;

@end
