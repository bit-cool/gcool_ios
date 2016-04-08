//
//  AVCamUtilities.h
//  视频录制处理器
//
//  Created by PfcStyle on 15-1-23.
//  Copyright (c) 2015年 PfcStyle. All rights reserved.
//
@class AVCaptureConnection;
@interface AVCamUtilities : NSObject
+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;
@end
