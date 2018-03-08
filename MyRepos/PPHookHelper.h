//
//  PPHookHelper.h
//  Maker
//
//  Created by yanruichen on 16/9/8.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

UIKIT_EXTERN void PP_SwitchInstanceMethods(Class cls, SEL originalSelector, SEL swizzledSelector);
UIKIT_EXTERN void PP_SwitchClassMethods(Class cls, SEL originalSelector, SEL swizzledSelector);
