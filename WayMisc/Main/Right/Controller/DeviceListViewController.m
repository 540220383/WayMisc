//
//  deviceListViewViewController.m
//  WayMisc
//
//  Created by 钟能 on 16/5/15.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "DeviceListViewController.h"

@interface DeviceListViewController ()<UITableViewDataSource,UITableViewDelegate,UIGestureRecognizerDelegate>

@end

@implementation DeviceListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [[UIView alloc]init];
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath

{
    if (indexPath.row == 0) {
        return UITableViewCellEditingStyleNone;
    }
    
    return UITableViewCellEditingStyleDelete;
    
}



-(NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewRowAction *deleteRoWAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"取消配对" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {//title可自已定义
        NSLog(@"点击删除");
    }];//此处是iOS8.0以后苹果最新推出的api，UITableViewRowAction，Style是划出的标签颜色等状态的定义，这里也可自行定义
    return @[deleteRoWAction];
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];;
    
    cell.backgroundColor = [UIColor blackColor];
    if (indexPath.row == 0) {
        UILabel *newDevice = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, 56)];
        newDevice.backgroundColor = kColorWithRGBA(34, 73, 138, 1);
        newDevice.text = @"连接新设备";
        newDevice.font=[UIFont systemFontOfSize:18];
        newDevice.textColor = [UIColor whiteColor];
        newDevice.textAlignment = NSTextAlignmentCenter;
        
        [cell.contentView addSubview:newDevice];
        return cell;
    }
    cell.textLabel.text = @"dooot 智能蓝牙炫彩版";
    cell.textLabel.textColor = [UIColor whiteColor];

    cell.detailTextLabel.text = @"设备号：2215EE145EE3FWF3";
    cell.detailTextLabel.font=[UIFont systemFontOfSize:14];

    cell.detailTextLabel.textColor = [UIColor whiteColor];

    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 56;
}

#pragma mark - UIGestureRecognizerDelegate

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer.view isKindOfClass:[self.view class]]) {
        return YES;
    }
    return NO;
}
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([gestureRecognizer.view isKindOfClass:[self.view class]]) {
        return YES;
    }
    return NO;
}
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[self.view class]]) {
        return YES;
    }
    return NO;
}


@end
