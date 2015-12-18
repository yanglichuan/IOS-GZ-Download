//
//  ViewController.m
//  02-表格图片下载
//
//  Created by apple on 15-1-16.
//  Copyright (c) 2015年 apple. All rights reserved.
//

#import "ViewController.h"
#import "CZApp.h"

@interface ViewController ()

// plist文件数据的容器
@property(nonatomic,strong)NSArray *appList;

/**管理全局下载操作的队列*/
@property(nonatomic,strong)NSOperationQueue *opQueue;

@end

@implementation ViewController

- (NSOperationQueue *)opQueue
{
    if (_opQueue == nil) {
        _opQueue = [[NSOperationQueue alloc]init];
    }
    return _opQueue;
}

// 懒加载
- (NSArray *)appList
{
    if (_appList == nil) {
        NSArray *dictArray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"apps.plist" ofType:nil]];
        
        // 字典转模型
        NSMutableArray *arrayM = [NSMutableArray array];
        for (NSDictionary *dict in dictArray) {
            CZApp *app = [CZApp appWithDict:dict];
            [arrayM addObject:app];
        }
        _appList = arrayM;
    }
    return _appList;
}

#pragma mark - 数据源方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.appList.count;
}

/**
 问题1: 如果网络比较慢，会比较卡
 解决办法：用异步下载
 
 问题2：图片没有frame,所有cell初始化的时候，给imageView的frame是0。 异步下载完成以后，不显示
 解决办法：使用占位图（如果占位图比较大，下载的图片比较小。自定义cell可以解决）

 */
// cell里面的imageView子控件也是懒加载。
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ID = @"AppCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    
    // 给cell设置数据
    CZApp *app = self.appList[indexPath.row];
    
    cell.textLabel.text = app.name;
    cell.detailTextLabel.text = app.download;
    
    // 显示图片
    cell.imageView.image = [UIImage imageNamed:@"user_default"];
    
    // 异步下载图片
    NSBlockOperation *downloadOp = [NSBlockOperation blockOperationWithBlock:^{
     
        // 0. 模拟延时
        [NSThread sleepForTimeInterval:0.5];
        NSLog(@"正在下载中......");
        // 1. 下载图片(二进制)
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:app.icon]];
        UIImage *image = [UIImage imageWithData:data];
        
        // 2. 更新UI
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            cell.imageView.image = image;
        }];
    }];
    
    // 将操作添加到队列
    [self.opQueue addOperation:downloadOp];
   
    return cell;
}






@end
