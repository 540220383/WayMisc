//
//  deviceListViewViewController.m
//  WayMisc
//
//  Created by 钟能 on 16/5/15.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "DeviceListViewController.h"
#import "DeviceCell.h"
#import "ConnetcViewController.h"

@interface DeviceListViewController ()<UITableViewDataSource,UITableViewDelegate,UIGestureRecognizerDelegate>

@end

@implementation DeviceListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [[UIView alloc]init];
    self.tableView.backgroundColor = [UIColor blackColor];
    [self.tableView registerNib:[UINib nibWithNibName:@"DeviceCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"cell"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)];
    panGesture.delegate = self;
    [self.view addGestureRecognizer:panGesture];
}

-(void)panGestureRecognized:(UIPanGestureRecognizer *)pan
{
    
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
    DeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.backgroundColor = kColorWithRGBA(47, 48, 49, 1);
    if (indexPath.row == 0) {
        UITableViewCell *cell = [[UITableViewCell alloc]init];
        UILabel *newDevice = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, 56)];
        newDevice.backgroundColor = kColorWithRGBA(34, 73, 138, 1);
        newDevice.text = @"连接新设备";
        newDevice.font=[UIFont systemFontOfSize:18];
        newDevice.textColor = [UIColor whiteColor];
        newDevice.textAlignment = NSTextAlignmentCenter;
        
        [cell.contentView addSubview:newDevice];
        return cell;
    }
    cell.deviceName.text = @"dooot 智能蓝牙炫彩版";
    cell.deviceUUID.text = @"设备号：2215EE145EE3FWF3";
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 56;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 0){
        ConnetcViewController *con = [[ConnetcViewController alloc]init];
        [self presentViewController:con animated:YES completion:nil];
    }
     [tableView deselectRowAtIndexPath:indexPath animated:NO];// 取消选中
    
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
    
    
    if ([[otherGestureRecognizer.view class] isSubclassOfClass:[UITableView class]]) {
        return NO;
    }
    
    if( [[otherGestureRecognizer.view class] isSubclassOfClass:[UITableViewCell class]] ||
       [NSStringFromClass([otherGestureRecognizer.view class]) isEqualToString:@"UITableViewCellScrollView"] ||
       [NSStringFromClass([otherGestureRecognizer.view class]) isEqualToString:@"UITableViewWrapperView"]) {
        
        return YES;
    }
    return YES;
}
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[DeviceCell class]]) {
        return YES;
    }
    return NO;
}


@end
