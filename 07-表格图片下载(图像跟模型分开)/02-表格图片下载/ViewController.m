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

/**所有的下载操作的缓冲池*/
@property(nonatomic,strong)NSMutableDictionary *operationCache;

/**所有图像的的缓存*/
@property(nonatomic,strong)NSMutableDictionary *imageCache;

@end

@implementation ViewController

- (NSMutableDictionary *)imageCache
{
    if (_imageCache == nil) {
        _imageCache = [NSMutableDictionary dictionary];
    }
    return _imageCache;
}

- (NSMutableDictionary *)operationCache
{
    if (_operationCache == nil) {
        _operationCache = [NSMutableDictionary dictionary];
    }
    return _operationCache;
}

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
 
 问题3：如果图片下载速度不一致，同时用户快速滚动的时候，会因为cell的重用导致图片混乱
 解决办法：MVC，使用模型保持下载的图像。 再次刷新表格
 
 问题4：在用户快读滚动的时候，会重复添下载加操作到队列
 解决办法：建立一个下载操作的缓冲池，首先检查”缓冲池“里是否有当前图片下载操作，有。 就不创建操作了。保证一个图片只对应一个下载操作
 
 问题5：将图像保存到模型里优缺点
 优点：不用重复下载，利用MVC刷新表格，不会造成数据混乱.加载速度比较快
 缺点：内存：所有下载好的图像，都会记录在模型里。如果数据比较多(2000)
 造成内存警告
 
 --** 图像跟模型耦合性太强。导致清理内存非常困难
 解决办法:

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
    
    // 判断当前图片缓存里面是否有图像
    if ([self.imageCache objectForKey:app.icon]) {
        NSLog(@"没有上网下载.....");
        cell.imageView.image = self.imageCache[app.icon];
    }else{
        // 显示图片
        // 显示占位图
        cell.imageView.image = [UIImage imageNamed:@"user_default"];
        
#warning 从这里开始剪的代码
        // 下载图片
        [self downloadImage:indexPath];
        
    }
   
    return cell;
}

/**下载图像*/
- (void)downloadImage:(NSIndexPath *)indexPath
{
    CZApp *app = self.appList[indexPath.row];
    
    // 判断缓冲池中是否存在当前图片的操作
    if (self.operationCache[app.icon]) {
        NSLog(@"正在玩命下载中。。。。");
        return;
    }
    
    // 没有下载操作，创建异步下载操作，来下载图片
    NSBlockOperation *downloadOp = [NSBlockOperation blockOperationWithBlock:^{
    
//    if (indexPath.row == 8) {
//        // 0. 模拟延时
//        [NSThread sleepForTimeInterval:5];
//    }
    NSLog(@"正在下载中......");
    // 1. 下载图片(二进制)
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:app.icon]];
    UIImage *image = [UIImage imageWithData:data];
    
    // 2. 将下载的数据保存到模型
    // 字典的赋值，不能为nil
    if (image) {
        [self.imageCache setObject:image forKey:app.icon];
    }
    
        // 2. 更新UI
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            //            cell.imageView.image = image;
            // 刷新当前行
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }];
    }];
    
    // 将操作添加到队列
    [self.opQueue addOperation:downloadOp];
    NSLog(@"操作的数量--->%tu", self.opQueue.operationCount);
    
    // 将操作添加到缓冲池中（使用图片的url作为key）
    [self.operationCache setObject:downloadOp forKey:app.icon];
    
}
/**
 在真实开发中，一定要注意这个方法。
 */
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // 需要在这里做一些内存清理工作. 如果不处理，会被系统强制闪退。
    
    // 清理图片的缓存
    [self.imageCache removeAllObjects];
    
    // 清理操作缓存
    [self.operationCache removeAllObjects];
    
    // 取消下载队列里面的任务
    [self.opQueue cancelAllOperations];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

@end
