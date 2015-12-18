//
//  CZApp.h
//  02-表格图片下载
//
//  Created by apple on 15-1-16.
//  Copyright (c) 2015年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CZApp : NSObject

@property(nonatomic,copy)NSString *name;

@property(nonatomic,copy)NSString *icon;

@property(nonatomic,copy)NSString *download;


+ (instancetype)appWithDict:(NSDictionary *)dict;

@end
