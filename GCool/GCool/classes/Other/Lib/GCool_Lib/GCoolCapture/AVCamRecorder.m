//
//  AVCamRecorder.m
//  视频录制处理器
//
//  Created by PfcStyle on 15-1-23.
//  Copyright (c) 2015年 PfcStyle. All rights reserved.
//

#import "AVCamRecorder.h"
#import "AVCamUtilities.h"

@interface AVCamRecorder (FileOutputDelegate) <AVCaptureFileOutputRecordingDelegate>
@end
@implementation AVCamRecorder
- (instancetype) initWithSession:(AVCaptureSession *)aSession
{
	self = [super init];
	if (self) {
		AVCaptureMovieFileOutput *aMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
		if ([aSession canAddOutput:aMovieFileOutput])
			[aSession addOutput:aMovieFileOutput];
		[self setMovieFileOutput:aMovieFileOutput];
		
		[self setSession:aSession];
	}
	
	return self;
}

-(BOOL)recordsVideo
{
	AVCaptureConnection *videoConnection = [AVCamUtilities connectionWithMediaType:AVMediaTypeVideo fromConnections:[[self movieFileOutput] connections]];
	return [videoConnection isActive];
}

-(BOOL)recordsAudio
{
	AVCaptureConnection *audioConnection = [AVCamUtilities connectionWithMediaType:AVMediaTypeAudio fromConnections:[[self movieFileOutput] connections]];
	return [audioConnection isActive];
}

-(BOOL)isRecording
{
	return [[self movieFileOutput] isRecording];
}

-(void)startRecordingWithOrientation:(AVCaptureVideoOrientation)videoOrientation  outputFileURL:(NSURL *)outputfile
{
	AVCaptureConnection *videoConnection = [AVCamUtilities connectionWithMediaType:AVMediaTypeVideo fromConnections:[[self movieFileOutput] connections]];
	if ([videoConnection isVideoOrientationSupported])
		[videoConnection setVideoOrientation:videoOrientation];
	[[self movieFileOutput] startRecordingToOutputFileURL:outputfile recordingDelegate:self];
}

-(void)stopRecording
{
	[[self movieFileOutput] stopRecording];
}

@end

@implementation AVCamRecorder (FileOutputDelegate)

-(void)				 captureOutput:(AVCaptureFileOutput *)captureOutput
didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
				   fromConnections:(NSArray *)connections
{
	if ([[self delegate] respondsToSelector:@selector(recorderRecordingDidBegin:)]) {
		[[self delegate] recorderRecordingDidBegin:self];
	}
}

- (void)			  captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)anOutputFileURL
					fromConnections:(NSArray *)connections
							  error:(NSError *)error
{
	if ([[self delegate] respondsToSelector:@selector(recorder:recordingDidFinishToOutputFileURL:error:)]) {
		[[self delegate] recorder:self recordingDidFinishToOutputFileURL:anOutputFileURL error:error];
	}
}


@end
