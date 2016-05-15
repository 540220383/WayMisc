//
//  deviceListViewViewController.m
//  WayMisc
//
//  Created by 钟能 on 16/5/15.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "DeviceListViewController.h"

@interface DeviceListViewController ()<UITableViewDataSource,UITableViewDelegate>

@end

@implementation DeviceListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [[UIView alloc]init];
    self.tableView.backgroundColor = [UIColor blackColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        
        [cell addSubview:newDevice];
        return cell;
    }
    cell.textLabel.text = @"dooot 智能蓝牙炫彩版";
    cell.textLabel.textColor = [UIColor whiteColor];

    cell.detailTextLabel.text = @"设备号：2215EE145EE3FWF3";
    cell.detailTextLabel.font=[UIFont systemFontOfSize:14];

    cell.detailTextLabel.textColor = [UIColor whiteColor];

    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return @"取消配对";
}
-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle==UITableViewCellEditingStyleDelete) {
        //        获取选中删除行索引值
        NSInteger row = [indexPath row];
        //        通过获取的索引值删除数组中的值
        //        [self.listData removeObjectAtIndex:row];
        //        删除单元格的某一行时，在用动画效果实现删除过程
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 56;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
