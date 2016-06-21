//
//  SemanticHelper.h
//  YuanTeHUD
//
//  Created by chinatsp on 16/6/14.
//  Copyright © 2016年 HandsonWu. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^semanticBlock)(NSString *type,NSString *keyWord);

@interface SemanticHelper : NSObject

+ (void)semanticWithSpeechRecognizerResults:(NSArray *)results complete:(semanticBlock)complete;
@end
