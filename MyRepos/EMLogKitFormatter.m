//
//  EMLogKitFormatter.m
//  Test
//
//  Created by Lym on 2018/3/16.
//  Copyright © 2018年 Lym. All rights reserved.
//

#import "EMLogKitFormatter.h"
@implementation EMLogKitFormatter

- (instancetype)init
{
    self = [super init];
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss:SSS";
    });
    return self;
}

+ (NSString *)getDateFormatterStr:(NSDate *)timeStamp
{
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH-mm-ss-SSS";
    });
//    return formatter;
    NSString *dateAndTime = [formatter stringFromDate:timeStamp];
    return dateAndTime;
}
- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    //取得文件名
    NSString *fileLocation;
    NSArray *parts = [logMessage.file componentsSeparatedByString:@"/"];
    if ([parts count] > 0)
        fileLocation = [parts lastObject];
    if ([fileLocation length] == 0)
        fileLocation = @"No file";
    //时间
    NSString *dateAndTime = [EMLogKitFormatter getDateFormatterStr: logMessage.timestamp];
    return [NSString stringWithFormat:@"[%@] %@ [%@][Line %lu] [%@][Log:%@]", [self translateToLevelStr:logMessage.level],dateAndTime,fileLocation, logMessage.line,logMessage.function,logMessage.message];
}

- (NSString *)translateToLevelStr:(DDLogLevel)level
{
    switch (level) {
        case DDLogLevelError:
            return @"ERROR";
        case DDLogLevelWarning:
            return @"WARNING";
        case DDLogLevelInfo:
            return @"INFO";
        case DDLogLevelDebug:
            return @"DEBUG";
        case DDLogLevelAll:
            return @"ALL";
        case DDLogLevelVerbose:
            return @"VERBOSE";
        case DDLogLevelOff:
            return @"OFF";
        default:
            break;
    }
    
}
@end
