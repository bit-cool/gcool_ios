//
//  AVCamUtilities.m
//  视频录制处理器
//
//  Created by PfcStyle on 15-1-23.
//  Copyright (c) 2015年 PfcStyle. All rights reserved.
//

#import "AVCamUtilities.h"
#import <AVFoundation/AVFoundation.h>
@implementation AVCamUtilities
//创建连接
+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections
{
	for ( AVCaptureConnection *connection in connections ) {
		for ( AVCaptureInputPort *port in [connection inputPorts] ) {
			if ( [[port mediaType] isEqual:mediaType] ) {
				return connection;
			}
		}
	}
	return nil;
}
@end
