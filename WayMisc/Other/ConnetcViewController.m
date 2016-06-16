//
//  ConnetcViewController.m
//  WayMisc
//
//  Created by xinmeiti on 16/6/8.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import "ConnetcViewController.h"
#import "SlideNavigationController.h"
#import "SVProgressHUD.h"
#import "ViewController.h"
@interface ConnetcViewController ()
{
    
}
@end

@implementation ConnetcViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}


- (IBAction)pairing:(id)sender {
    //初始化BabyBluetooth 蓝牙库
    [SlideNavigationController sharedInstance].baby = [BabyBluetooth shareBabyBluetooth];
    //设置蓝牙委托

    [self babyDelegate:[SlideNavigationController sharedInstance].baby];
    
//    [SVProgressHUD showInfoWithStatus:@"开始连接设备"];

    if(![[SlideNavigationController sharedInstance].currPeripheral.name isEqualToString:@"CAR-KIT"]){
        //停止之前的连接
        [[SlideNavigationController sharedInstance].baby cancelAllPeripheralsConnection];
        
        
        //设置委托后直接可以使用，无需等待CBCentralManagerStatePoweredOn状态。
        [SlideNavigationController sharedInstance].baby.scanForPeripherals().begin();
        //baby.scanForPeripherals().begin().stop(10);
        
    }
    
}
- (IBAction)Skip:(id)sender {
    
    // 切换控制器
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    window.rootViewController = [SlideNavigationController sharedInstance];
}


-(void)viewDidAppear:(BOOL)animated{
    NSLog(@"viewDidAppear");
    
    
    
    
}
//蓝牙网关初始化和委托方法设置
-(void)babyDelegate:(BabyBluetooth *)ble{
    
    __weak typeof(self) weakSelf = self;
    
    
    [ble setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        if (central.state == CBCentralManagerStatePoweredOn) {
//            [SVProgressHUD showInfoWithStatus:@"设备打开成功，开始扫描设备"];
            [SVProgressHUD showWithStatus:@"正在连接设备"];
        }
    }];
    
    //设置扫描到设备的委托
    [ble setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        NSLog(@"搜索到了设备:%@",peripheral.name);
        if ([peripheral.name isEqualToString:@"CAR-KIT"]) {
            [SlideNavigationController sharedInstance].currPeripheral = peripheral;
            
            //添加断开自动重连
            [ble AutoReconnect:[SlideNavigationController sharedInstance].currPeripheral];
            //停止扫描
            [ble cancelScan];
            
            [weakSelf diso:ble];
            
            [SVProgressHUD dismiss];
            
        }
        //        [weakSelf insertTableView:peripheral advertisementData:advertisementData];
    }];
    
    
    
    
    
    //设置查找设备的过滤器
    [ble setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        
        //最常用的场景是查找某一个前缀开头的设备
        //        if ([peripheralName hasPrefix:@"Pxxxx"] ) {
        //            return YES;
        //        }
        //        return NO;
        
        //设置查找规则是名称大于0 ， the search rule is peripheral.name length > 0
        if (peripheralName.length >0) {
            return YES;
        }
        return NO;
    }];
    
}

-(void)diso:(BabyBluetooth*)ble
{
    __weak typeof(self) weakSelf = self;
    BabyRhythm *rhythm = [[BabyRhythm alloc]init];
    
    
    //设置设备连接成功的委托,同一个baby对象，使用不同的channel切换委托回调
    [ble setBlockOnConnectedAtChannel:channelOnPeropheralView block:^(CBCentralManager *central, CBPeripheral *peripheral) {
        [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"设备：%@--连接成功",peripheral.name]];
        
        // 切换控制器
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        window.rootViewController = [SlideNavigationController sharedInstance];
        
    }];
    
    //设置设备连接失败的委托
    [ble setBlockOnFailToConnectAtChannel:channelOnPeropheralView block:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备：%@--连接失败",peripheral.name);
        [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"设备：%@--连接失败",peripheral.name]];
        
    }];
    
    //设置设备断开连接的委托
    [ble setBlockOnDisconnectAtChannel:channelOnPeropheralView block:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备：%@--断开连接",peripheral.name);
        [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"设备：%@--断开失败",peripheral.name]];
    }];
    
    //设置发现设备的Services的委托
    [ble setBlockOnDiscoverServicesAtChannel:channelOnPeropheralView block:^(CBPeripheral *peripheral, NSError *error) {
        for (CBService *s in peripheral.services) {
            ///插入section到tableview
            //            [weakSelf insertSectionToTableView:s];
        }
        
        [rhythm beats];
    }];
    //设置发现设service的Characteristics的委托
    [ble setBlockOnDiscoverCharacteristicsAtChannel:channelOnPeropheralView block:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        
        if ([service.UUID.UUIDString isEqualToString:@"5858"]) {
            NSLog(@"===service name:%@",service.UUID);
            
        }
        
        //插入row到tableview
        //        [weakSelf insertRowToTableView:service];
        
    }];
    //设置读取characteristics的委托
    [ble setBlockOnReadValueForCharacteristicAtChannel:channelOnPeropheralView block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        if ([characteristics.UUID.UUIDString isEqualToString:@"5959"]) {
            [SlideNavigationController sharedInstance].characteristic = characteristics;            
            NSLog(@"characteristic name:%@ value is:%@",characteristics.UUID,characteristics.value);
            
        }
    }];
    //设置发现characteristics的descriptors的委托
    [ble setBlockOnDiscoverDescriptorsForCharacteristicAtChannel:channelOnPeropheralView block:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"===characteristic name:%@",characteristic.service.UUID);
        for (CBDescriptor *d in characteristic.descriptors) {
            NSLog(@"CBDescriptor name is :%@",d.UUID);
        }
    }];
    //设置读取Descriptor的委托
    [ble setBlockOnReadValueForDescriptorsAtChannel:channelOnPeropheralView block:^(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) {
        NSLog(@"Descriptor name:%@ value is:%@",descriptor.characteristic.UUID, descriptor.value);
    }];
    
    //读取rssi的委托
    [ble setBlockOnDidReadRSSI:^(NSNumber *RSSI, NSError *error) {
        NSLog(@"setBlockOnDidReadRSSI:RSSI:%@",RSSI);
    }];
    
    
    //设置beats break委托
    [rhythm setBlockOnBeatsBreak:^(BabyRhythm *bry) {
        NSLog(@"setBlockOnBeatsBreak call");
        
        //如果完成任务，即可停止beat,返回bry可以省去使用weak rhythm的麻烦
        //        if (<#condition#>) {
        //            [bry beatsOver];
        //        }
        
    }];
    
    //设置beats over委托
    [rhythm setBlockOnBeatsOver:^(BabyRhythm *bry) {
        NSLog(@"setBlockOnBeatsOver call");
    }];
    
    //扫描选项->CBCentralManagerScanOptionAllowDuplicatesKey:忽略同一个Peripheral端的多个发现事件被聚合成一个发现事件
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    /*连接选项->
     CBConnectPeripheralOptionNotifyOnConnectionKey :当应用挂起时，如果有一个连接成功时，如果我们想要系统为指定的peripheral显示一个提示时，就使用这个key值。
     CBConnectPeripheralOptionNotifyOnDisconnectionKey :当应用挂起时，如果连接断开时，如果我们想要系统为指定的peripheral显示一个断开连接的提示时，就使用这个key值。
     CBConnectPeripheralOptionNotifyOnNotificationKey:
     当应用挂起时，使用该key值表示只要接收到给定peripheral端的通知就显示一个提
     */
    NSDictionary *connectOptions = @{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,
                                     CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES,
                                     CBConnectPeripheralOptionNotifyOnNotificationKey:@YES};
    
    [ble setBabyOptionsAtChannel:channelOnPeropheralView scanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:connectOptions scanForPeripheralsWithServices:nil discoverWithServices:nil discoverWithCharacteristics:nil];
    
    
    ble.having([SlideNavigationController sharedInstance].currPeripheral).and.channel(channelOnPeropheralView).then.connectToPeripherals().discoverServices().discoverCharacteristics().readValueForCharacteristic().discoverDescriptorsForCharacteristic().readValueForDescriptors().begin();
}


-(void)viewWillDisappear:(BOOL)animated{
    NSLog(@"viewWillDisappear");
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)startBle
{
    [self.delegate setBabyDelegate];
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
