//
//  RightMenuController.m
//  WayMisc
//
//  Created by chinatsp on 16/5/9.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "RightMenuController.h"
#import "NaviViewController.h"
#import "AboutView.h"
#import "DeviceListViewController.h"
#import "VoiceDialViewController.h"
@interface RightMenuController ()<UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *linkState;

@end

@implementation RightMenuController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView.delegate = self;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        DeviceListViewController *deviceList = [[DeviceListViewController alloc]init];
        [[SlideNavigationController sharedInstance] pushViewController:deviceList animated:YES];
    }else if(indexPath.row == 1) {
        
        
        [UIView animateWithDuration:.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             CGRect rect = [SlideNavigationController sharedInstance].view.frame;
                             rect.origin.x = 0;
                             [SlideNavigationController sharedInstance].view.frame = rect;
                         }
                         completion:^(BOOL finished) {
                             
                         }];

        
    }else if(indexPath.row == 3) {
        AboutView *about = [[NSBundle mainBundle]loadNibNamed:@"AboutView" owner:nil options:nil][0];
        about.center = CGPointMake(kScreenWidth/2, (kScreenHeight-20)/2);
        [self.view addSubview:about];
        
        
    }else if(indexPath.row == 4) {
        VoiceDialViewController *voiceDial = [[VoiceDialViewController alloc]init];
        
        
        [[SlideNavigationController sharedInstance] pushViewController:voiceDial animated:YES];
        //        [self presentViewController:navi animated:YES completion:nil];
    }else if(indexPath.row == 5) {
        NaviViewController *navi = [[NaviViewController alloc]init];
        
        
        [[SlideNavigationController sharedInstance] pushViewController:navi animated:YES];
//        [self presentViewController:navi animated:YES completion:nil];
    }
    
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
