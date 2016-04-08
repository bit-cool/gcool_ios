//
//  AVCamRecorder.h
//  视频录制处理器
//
//  Created by PfcStyle on 15-1-23.
//  Copyright (c) 2015年 PfcStyle. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>

@protocol AVCamRecorderDelegate;

@interface AVCamRecorder : NSObject {
}

@property (nonatomic,strong) AVCaptureSession *session;
@property (nonatomic,strong) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic,copy) NSURL *outputFileURL;
@property (nonatomic,readonly) BOOL recordsVideo;
@property (nonatomic,readonly) BOOL recordsAudio;
@property (nonatomic,readonly,getter=isRecording) BOOL recording;
@property (nonatomic,assign) id <NSObject,AVCamRecorderDelegate> delegate;

-(id)initWithSession:(AVCaptureSession *)session;
-(void)startRecordingWithOrientation:(AVCaptureVideoOrientation)videoOrientation outputFileURL:(NSURL *)outputfile;
-(void)stopRecording;

@end

@protocol AVCamRecorderDelegate
@required
-(void)recorderRecordingDidBegin:(AVCamRecorder *)recorder;
-(void)recorder:(AVCamRecorder *)recorder recordingDidFinishToOutputFileURL:(NSURL *)outputFileURL error:(NSError *)error;
@end
