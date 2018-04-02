//
//  EMLogKitResourceEntity.h
//  MintLive
//
//  Created by Lym on 2018/3/17.
//  Copyright © 2018年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EMLogKitResourceEntity : NSObject
@property (copy, nonatomic) NSString *filePath;
@property (copy, nonatomic) NSString *bucket;
@property (copy, nonatomic) NSString *key;
@property (copy, nonatomic) NSString *token;
@property (copy, nonatomic) NSString *url;
@end
