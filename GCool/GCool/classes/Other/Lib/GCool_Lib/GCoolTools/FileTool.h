//
//  FileTool.h
//  doco_ios_app
//
//  Created by developer on 15/5/4.
//  Copyright (c) 2015年 developer. All rights reserved.
//

typedef void (^successBlock)(NSURL* url);
typedef void (^failureBlock)(NSError* error);
@interface FileTool : NSObject
//判断文件是否存在
+(BOOL)fileIsExistAtPath:(NSString *)path;
//获取应用根目录的文件夹路径
+ (NSString *)getRootFolderPathStringWithFolderName:(NSString *)folderName;
//移动一堆文件到某个文件夹  会自动判断是否存在
+(BOOL)moveFiles:(NSArray *)pathArray toPath:(NSArray *)dstArray;
//复制一个文件
+(BOOL)copyFile:(NSString *)filePath toPath:(NSString *)dstFilePath;
//删除文件
+(void) removeFile:(NSURL *)fileURL;
+(void) removeFiles:(NSArray *)urlArray;
//创建文件
+ (BOOL)createFolderIfNotExistForFolderPath:(NSString *)folderPath;
+ (BOOL)createFileIfNotExistForFilePath:(NSString *)filePath;
@end
