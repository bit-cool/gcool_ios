//
//  AppDelegate.m
//  GCool
//
//  Created by developer on 16/4/6.
//  Copyright © 2016年 developer. All rights reserved.
//

#import "AppDelegate.h"
#import "UncaughtExceptionHandl.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //配置自定义日志框架 以及 异常安装
    [self setFileLogger];
    
    //配置屏幕适配属性
//    [self AutoSizeScaleToFitScreen];
    
//    //判断是否是新版本
//    [self NewVersionOrNot];
    

    return YES;
    
}

- (void)setFileLogger
{
    //配置自定义日志框架
    [DDLog addLogger:[DDASLLogger sharedInstance]withLevel:DDLogLevelVerbose];
    [DDLog addLogger:[DDTTYLogger sharedInstance]withLevel:DDLogLevelVerbose];
    //配置日志文件   保持一周
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    
    [DDLog addLogger:fileLogger withLevel:DDLogLevelError];
    InstallUncaughtExceptionHandler();
    MyLog(@"logdir:%@",fileLogger.logFileManager.logsDirectory);
    //fileLogger.logFileManager.logsDirectory
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
