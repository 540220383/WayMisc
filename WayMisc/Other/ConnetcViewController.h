//
//  ConnetcViewController.h
//  WayMisc
//
//  Created by xinmeiti on 16/6/8.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BabyBluetooth.h"

@protocol ConnetcDelegate <NSObject>

-(void)setBabyDelegate;

@end

@interface ConnetcViewController : UIViewController

@property (nonatomic,weak) id <ConnetcDelegate> delegate;
@property(strong,nonatomic)CBPeripheral *currPeripheral;
@property (nonatomic,strong)CBCharacteristic *characteristic;

-(void)startBle;
@end
