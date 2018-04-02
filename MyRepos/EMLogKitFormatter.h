//
//  EMLogKitFormatter.h
//  Test
//
//  Created by Lym on 2018/3/16.
//  Copyright © 2018年 Lym. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
@interface EMLogKitFormatter : NSObject<DDLogFormatter>

//获取日志时间戳
+ (NSString *)getDateFormatterStr:(NSDate *)timeStamp;
//遵从<DDLogFormatter>协议，重新格式化每一条ddlog日志消息体
- (NSString *)formatLogMessage:(DDLogMessage *)logMessage;

@end
