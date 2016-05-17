//
//  DeviceCell.h
//  WayMisc
//
//  Created by xinmeiti on 16/5/17.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DeviceCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *deviceName;
@property (weak, nonatomic) IBOutlet UILabel *deviceUUID;
@property (weak, nonatomic) IBOutlet UILabel *deviceState;

@end
