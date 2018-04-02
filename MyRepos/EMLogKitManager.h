//
//  EMLogKitManager.h
//  MintLive
//
//  Created by Lym on 2018/3/13.
//  Copyright © 2018年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

#if DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
static const DDLogLevel ddLogLevel = DDLogLevelInfo;
#endif

@interface EMLogKitManager : NSObject

+ (instancetype)shareManager;

//开始记录日志
- (void)beginLogging;
///**
// 发送反馈日志,返回是否成功
// @param title 反馈标题 @param image 反馈图片
// @param dic 反馈的自定义内容，需包含最新的日志下载地址，可以为用户的联系方式，
// example:{
// "log": "http://XXXXXX.log"
// "qq": "XXXXX"
// }
// */
//- (BOOL)sendFeedback:(NSString *)content
//               image:(UIImage *)image
////           keyValues:(NSDictionary *)dic;

//手动上传本地的日志,path为上传后的地址
- (void)uploadLogFileWithProgressCallback:(void(^)(float persent))progressCallback
                       completionCallback:(void(^)(NSString *path, NSError *error))completedCallback;

//获取最近创建的日志地址数组，由新到旧
- (NSArray *)getRecentlyLogFilePathsArr;

@end

