//
//  NoticeViewController.m
//  WayMisc
//
//  Created by xinmeiti on 16/5/12.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "FMViewController.h"

@interface FMViewController ()<UIPickerViewDelegate,UIPickerViewDataSource>
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *MHzViewMarginBottom;
@property (weak, nonatomic) IBOutlet UIImageView *AnimaImages;
@property (weak, nonatomic) IBOutlet UIButton *FMBtn;

@property (weak, nonatomic) IBOutlet UILabel *PickLabel;
@property (weak, nonatomic) IBOutlet UIPickerView *MHzPickerView;

@end

@implementation FMViewController

- (IBAction)EditMHz:(UIButton *)sender {
    
    [UIView animateWithDuration:0.25 animations:^{
        self.MHzViewMarginBottom.constant = 0;
    }];
    
}
- (IBAction)FMoffOron:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [sender setImage:[UIImage imageNamed:@"equipmentui_fm_on"] forState:UIControlStateNormal];
        [self.AnimaImages startAnimating];
    }else{
        [sender setImage:[UIImage imageNamed:@"equipmentui_fm_off"] forState:UIControlStateNormal];
        [self.AnimaImages stopAnimating];
    }
}
- (IBAction)confirmUpdate:(UIButton *)sender {
    
//    [self.FMBtn setTitle:@"" forState:UIControlStateNormal];
    self.MHzViewMarginBottom.constant = 309;

}
- (IBAction)cancelUpdate:(UIButton *)sender {
    self.MHzViewMarginBottom.constant = 309;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //设置动画数组
    
    [self.AnimaImages setAnimationImages:@[[UIImage imageNamed:@"equipmentui_fm_turn_wheel0"],[UIImage imageNamed:@"equipmentui_fm_turn_wheel1"],[UIImage imageNamed:@"equipmentui_fm_turn_wheel2"]]];
    //设置动画播放次数
    [self.AnimaImages setAnimationRepeatCount:0];
    //设置动画播放时间
    [self.AnimaImages setAnimationDuration:3*0.075];
    //开始动画
//    [self.AnimaImages startAnimating];
    
    self.MHzPickerView.delegate = self;
    self.MHzPickerView.dataSource = self;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 3;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (component == 2) {
        return 1;
    }
    return 5;
}

-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 25;
}

-(UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    if (!view) {
        view = [[UIView alloc]init];
    }
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, (kScreenWidth*0.5)/3, 25)];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"123";
    [view addSubview:label];
    if (component == 2) {
        label.text = @"MHz";
    }
    return view;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (component == 2) {
        return @"MHz";
    }
    return @"123";
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
//    self.PickLabel.text = @"";
}

- (IBAction)click:(id)sender {
    
    [self closePage];
}



@end
