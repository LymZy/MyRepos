//
//  EMLogKitManager.m
//  MintLive
//
//  Created by Lym on 2018/3/13.
//  Copyright © 2018年 NetEase. All rights reserved.
//

#import "EMLogKitManager.h"
#import "EMLogKitFormatter.h"

#import "EMLogKitResourceEntity.h"
#import <SSZipArchive/SSZipArchive.h>
#import <NOSSDK/NOSSDK.h>
#import <AFNetworking.h>
#import <NSObject+YYModel.h>
#define NSErrorBHUploadSDKNOSError @"com.netease.mint.uploadsdk.noserror"
@interface EMLogKitManager()
@property (nonatomic, strong) DDFileLogger *fileLogger;
@property (nonatomic, strong) NOSUploadManager *uploadManager;
@end

@implementation EMLogKitManager

+ (void)load
{
    [[EMLogKitManager shareManager]beginLogging];
}

+ (instancetype)shareManager {
    static dispatch_once_t onceToken = 0;
    __strong static EMLogKitManager *sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
      
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        DDLogFileManagerDefault *m = [[DDLogFileManagerDefault alloc] initWithLogsDirectory:[self configLogPath]];
        EMLogKitFormatter *formatter = [[EMLogKitFormatter alloc]init];
        DDFileLogger *fileLogger = [[DDFileLogger alloc] initWithLogFileManager:m];
        fileLogger.rollingFrequency = 60 * 60 * 24 * 3;
        fileLogger.maximumFileSize = kDDDefaultLogMaxFileSize * 3;  //最大3m
        fileLogger.logFileManager.maximumNumberOfLogFiles = kDDDefaultLogMaxNumLogFiles; //最多5个
        fileLogger.logFormatter = formatter;
        _fileLogger = fileLogger;
        
        [DDTTYLogger sharedInstance].logFormatter = formatter;
        NOSConfig *conf = [[NOSConfig alloc] init];
        conf.NOSSoTimeout = 30;
        conf.NOSRetryCount = 0;
        [NOSUploadManager setGlobalConf:conf];
        
        _uploadManager = [NOSUploadManager sharedInstanceWithRecorder:nil recorderKeyGenerator:nil];
    }
    return self;
}


//- (BOOL)sendFeedback:(NSString *)content image:(UIImage *)image keyValues:(NSDictionary *)dic
//{
//    BOOL isSend = NO;
//    for (NSString *key in dic.allKeys) {
//        [Bugtags setUserData:dic[key] forKey:key];
//    }
//    if (content &&  image) {
////       [Bugtags sendFeedback:content image:image];
//        isSend = YES;
//    }else if (content && image == nil)
//    {
////       [Bugtags sendFeedback:content];
//        isSend = YES;
//    }else
//    {
//        isSend = NO;
//    }
//    return isSend;
//}

- (void)uploadLogFileWithProgressCallback:(void(^)(float persent))progressCallback
                       completionCallback:(void(^)(NSString *path, NSError *error))completedCallback
{
    NSArray *filePathsArr = [self getRecentlyLogFilePathsArr];
    if (filePathsArr.count == 0) {
        completedCallback(nil,[NSError errorWithDomain:@"com.netease.mint.loginKitManager" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"本地无日志文件"}]);
        return;
    }
    __block float currentUploadPercent = 0;
    void(^temp_progressCallback)(float currentPercent) = [progressCallback copy];
    void(^temp_completedCallback)(NSString *path, NSError *error) = [completedCallback copy];
    
    NSString *logZipPath = [self zipAllLog];
    EMLogKitResourceEntity *entity = [[EMLogKitResourceEntity alloc]init];
    entity.filePath = logZipPath;
    
    dispatch_group_t uploadGroup = dispatch_group_create();
    dispatch_queue_t uploadQueue = dispatch_queue_create("com.netease.mint.queue.uploadlog", DISPATCH_QUEUE_SERIAL);
    dispatch_group_enter(uploadGroup);
    //上传token
    [self getNOSTokenResource:entity withCallback:^(NSHTTPURLResponse *resp, id body, NSError *error) {
        if (error) {
            temp_completedCallback(nil,error);
        }
        if (uploadGroup != NULL) {
            dispatch_group_leave(uploadGroup);
        }
    }];
    
    //上传回调
    NOSUploadOption *option = [[NOSUploadOption alloc] initWithMime:nil progressHandler:^(NSString *key, float percent) {
       temp_progressCallback( currentUploadPercent + percent);
    } metas:nil cancellationSignal:^BOOL {
#warning 此处可以加取消逻辑
        BOOL cancel = NO;
        return cancel;
    }];
    
    //上传过程
    dispatch_group_notify(uploadGroup, uploadQueue, ^{
        if (entity.token) {
            [_uploadManager putFileByHttp:entity.filePath bucket:entity.bucket key:entity.key token:entity.token complete:^(NOSResponseInfo *info, NSString *key, NSDictionary *resp) {
                if (info.isOK) {
                    DDLogWarn(@"日志上传成功，返回：%@",info.callbackRetMsg);
                    // 成功
                    NSData *jsonData = [info.callbackRetMsg dataUsingEncoding:NSUTF8StringEncoding];
                    NSError *err;
                    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
                    NSString *downloadURL = dic[@"url"];
                    temp_completedCallback(downloadURL,nil);
                    
                    [[NSFileManager defaultManager] removeItemAtPath:logZipPath error:nil];
                } else {
                    NSError *error = [NSError errorWithDomain:NSErrorBHUploadSDKNOSError code:info.statusCode userInfo:nil];
                      DDLogWarn(@"日志上传失败，error：%@",error);
                    temp_completedCallback(key,error);
                }
            } option:option];
        }
    });
}



- (NSString *)zipAllLog
{
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    NSString *logZipPath = [NSString stringWithFormat:@"%@/%@_%@.zip",[self configLogPath],identifier,[EMLogKitFormatter getDateFormatterStr:[NSDate dateWithTimeIntervalSinceNow:0]]];
    BOOL isCreate = [SSZipArchive createZipFileAtPath:logZipPath withFilesAtPaths:[self getRecentlyLogFilePathsArr]];
    if (isCreate) {
        return logZipPath;
    }else
    {
        return nil;
    }
}

//获取上传token
- (void)getNOSTokenResource:(EMLogKitResourceEntity *)resource
               withCallback:(void(^)(NSHTTPURLResponse *resp, id body, NSError *error))callback
{
    if (!callback) {
        return ;
    }
    void(^tempCallback)(NSHTTPURLResponse *resp, id body, NSError *error) = [callback copy];
    
    [[AFHTTPSessionManager manager] GET:@"https://live.ent.163.com/api/upload/nos/tokenForFile" parameters:@{@"fileName":[resource.filePath lastPathComponent]} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if([responseObject isKindOfClass:[NSDictionary class]])
        {
            [resource yy_modelSetWithJSON:responseObject[@"data"]];
            tempCallback((NSHTTPURLResponse *)task.response,responseObject,nil);
        }else
        {
            NSHTTPURLResponse *respon = task.response;
            NSError *error = [NSError errorWithDomain:task.response.URL.absoluteString code:respon.statusCode userInfo:@{@"info":@"获取上传token失败"}];
            tempCallback((NSHTTPURLResponse *)task.response,nil,error);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            tempCallback((NSHTTPURLResponse *)task.response,nil,error);
    }];
}

- (NSString *)configLogPath {
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    NSString *groupSharedPushLogPath = [rootPath stringByAppendingPathComponent:@"/LogDir/"];
    NSLog(@"本地日志目录：%@",groupSharedPushLogPath);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:groupSharedPushLogPath]) {
        [fileManager createDirectoryAtPath:groupSharedPushLogPath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return groupSharedPushLogPath;
}

- (void)beginLogging
{
    [DDLog addLogger:self.fileLogger withLevel:DDLogLevelAll];
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:DDLogLevelAll];
}

- (NSArray *)getRecentlyLogFilePathsArr
{
    return [[self.fileLogger logFileManager] sortedLogFilePaths];
}

@end
