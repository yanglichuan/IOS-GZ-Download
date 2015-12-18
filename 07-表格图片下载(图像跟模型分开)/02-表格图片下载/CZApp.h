//
//  CZApp.h
//  02-表格图片下载
//
//  Created by apple on 15-1-16.
//  Copyright (c) 2015年 apple. All rights reserved.
//

// Xcode 6 pch
#import <Foundation/Foundation.h>
//#import <UIKit/UIKit.h>

@interface CZApp : NSObject

@property(nonatomic,copy)NSString *name;

@property(nonatomic,copy)NSString *icon;

@property(nonatomic,copy)NSString *download;

/**
 保存网络下载下来的图像
 */
//@property(nonatomic,strong)UIImage *image;


+ (instancetype)appWithDict:(NSDictionary *)dict;

@end
