//
//  SpeechViewController.h
//  WayMisc
//
//  Created by xinmeiti on 16/6/21.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AMapNaviKit/MAMapKit.h>
#import <AMapNaviKit/AMapNaviKit.h>
#import <AMapSearchKit/AMapSearchAPI.h>
@interface SpeechViewController : UIViewController<MAMapViewDelegate,AMapSearchDelegate,AMapNaviManagerDelegate>

@property (nonatomic, strong) MAMapView *mapView;

@property (nonatomic, strong) AMapSearchAPI *search;

@property (nonatomic, strong) AMapNaviManager *naviManager;





@end
