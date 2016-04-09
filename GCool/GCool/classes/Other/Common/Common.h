//
//  Common.h
//  GCool
//
//  Created by developer on 16/4/6.
//  Copyright © 2016年 developer. All rights reserved.
//

#import "AppDelegate.h"

//定义工程Dock总布局及颜色
#define kDockItemNormalColor [UIColor whiteColor]
#define kDockItemSelectColor [UIColor greenColor]
#define kDockHeight 44
#define kDockItemCount 5

//定义iphone型号
#define isIphone5 ([UIScreen mainScreen].bounds.size.height == 568)
#define isIphone6 ([UIScreen mainScreen].bounds.size.height == 667)
#define isIphone6p ([UIScreen mainScreen].bounds.size.height == 960)

//定义的全屏尺寸（包含状态栏）
#define DEVICE_BOUNDS [[UIScreen mainScreen] bounds]
#define DEVICE_SIZE [[UIScreen mainScreen] bounds].size

//定义系统版本
#define DEVICE_OS_VERSION [[[UIDevice currentDevice] systemVersion] floatValue]

//定义视频渲染尺寸
#define kRenderSize CGSizeMake(540, 540)
//定义fps
#define kFps 30

//获得RGBA颜色
#define kColor(r, g, b, a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]

//AppDelegate
#define MyDelegate ((AppDelegate *)[[UIApplication sharedApplication] delegate])

////服务器配置、client_id 和 client_secret

//系统默认字体
#define commonFont @"Helvetica"

//日志输出宏定义
#ifdef DEBUG
//调试状态
#define MyLog(...) DDLogVerbose(__VA_ARGS__)
#else
//发布状态
#define MyLog(...)
#endif
