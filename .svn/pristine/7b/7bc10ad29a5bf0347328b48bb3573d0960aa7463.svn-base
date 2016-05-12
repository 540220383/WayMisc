//
//  FlowLayout.h
//  CustomWaterFlow
//
//  Created by DYS on 15/12/12.
//  Copyright © 2015年 DYS. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FlowLayout;

@protocol HMWaterflowLayoutDelegate <NSObject>
- (CGFloat)waterflowLayout:(FlowLayout *)waterflowLayout heightForWidth:(CGFloat)width atIndexPath:(NSIndexPath *)indexPath;
@end


@interface FlowLayout : UICollectionViewFlowLayout


@property (nonatomic, assign) NSInteger  colCount;

//@property (nonatomic, strong) NSArray *shops;
@property (nonatomic, weak) id<HMWaterflowLayoutDelegate> delegate;

@end
