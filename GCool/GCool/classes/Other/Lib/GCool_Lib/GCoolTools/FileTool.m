//
//  FileTool.m
//  doco_ios_app
//
//  Created by developer on 15/5/4.
//  Copyright (c) 2015年 developer. All rights reserved.
//

#import "FileTool.h"

@implementation FileTool
+ (BOOL)createFolderIfNotExistForFolderPath:(NSString *)folderPath
{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = FALSE;
    
    BOOL isDirExist = [fileManager fileExistsAtPath:folderPath isDirectory:&isDir];
    NSError *error;
    if(!(isDirExist && isDir))
    {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&error];
        if(!bCreateDir){
            MyLog(@"创文件夹失败:%@",error);
            MyLog(@"创建路径：%@",folderPath);
            return NO;
        }
        [self addSkipBackupAttributeToItemAtPath:folderPath];
        return YES;
    }
    return YES;
}

+(BOOL)addSkipBackupAttributeToItemAtPath:(NSString *)filepathString{
    NSURL *url = [NSURL fileURLWithPath:filepathString];
    
    NSError *error = nil;
    BOOL success = [url setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
    MyLog(@"urlpath:%@",[url path]);
    if(!success){
        MyLog(@"不备份Error:%@",error);
    }
    return success;
}


+ (BOOL)createFileIfNotExistForFilePath:(NSString *)filePath
{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = FALSE;
    
    BOOL isFileExist = [fileManager fileExistsAtPath:filePath isDirectory:&isDir];
    
    if(!isFileExist && !isDir)
    {
        BOOL bCreateDir = [fileManager createFileAtPath:filePath contents:nil attributes:nil];
        if(!bCreateDir){
            MyLog(@"创文件失败");
            return NO;
        }
        return YES;
    }
    MyLog(@"不用创建了");
    return YES;
}

//获取应用根目录的文件夹路径
+ (NSString *)getRootFolderPathStringWithFolderName:(NSString *)folderName{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    path = [path stringByAppendingPathComponent:folderName];
    
    return path;
}

//移动所有文件到目录
+(BOOL)moveFiles:(NSArray *)pathArray toPath:(NSArray *)dstArray{
    
    for(int i=0;i<pathArray.count;i++){
        NSError *error;
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:dstArray[i]]) {
            MyLog(@"文件已经存在！不用存了");
            return YES;
            
        }
        BOOL isSuccess = [fm moveItemAtPath:pathArray[i] toPath:dstArray[i] error:&error];
        if (!isSuccess) {
            MyLog(@"移动文件错误：%@",error);
            return NO;
        }
    }
    return YES;
}

+(BOOL)copyFile:(NSString *)filePath toPath:(NSString *)dstFilePath{
    NSError *error;
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:dstFilePath]) {
        MyLog(@"文件已经存在！不用存了");
        return YES;
        
    }
    BOOL isSuccess = [fm copyItemAtPath:filePath toPath:dstFilePath error:&error];
    if (!isSuccess) {
        MyLog(@"复制文件错误：%@",error);
        return NO;
    }
    return YES;
}

//删除文件
+ (void) removeFile:(NSURL *)fileURL
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *filePath = [[fileURL absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:filePath]) {
            NSError *error = nil;
            [fileManager removeItemAtPath:filePath error:&error];
            if (error) {
                MyLog(@"删除失败：%@",error);
            }
            
        }
    });
    
}

+(BOOL)fileIsExistAtPath:(NSString *)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:path];
}

+(void) removeFiles:(NSArray *)urlArray{
    
    for (NSURL *fileURL in urlArray) {
        [self removeFile:fileURL];
    }
}

@end
