//
//  AVCamCaptureManager.m
//  视频录制处理器
//
//  Created by PfcStyle on 15-1-21.
//  Copyright (c) 2015年 PfcStyle. All rights reserved.
//

#import "AVCamCaptureManager.h"
#import "AVCamRecorder.h"
#import "AVCamUtilities.h"
#import "AnimationTool.h"
#import "DoCoExporterWriter.h"
#import "ImageToMovieTool.h"
#import "DoCoExporterManager.h"
#import "DoCoVideoLayerAnimationManager.h"
#import "FileTool.h"
#import <AssetsLibrary/AssetsLibrary.h>

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);
#define COUNT_DUR_TIMER_INTERVAL 1.0/60.0
//定义一个视频内部类
@interface kVideo : NSObject
@property(nonatomic,strong)NSURL *fileURL;
@property(nonatomic,assign)CGFloat  duration;

@end
@implementation kVideo

@end

@interface AVCamCaptureManager (RecorderDelegate) <AVCamRecorderDelegate>
@end
@interface AVCamCaptureManager (DoCoExporterWriterDelegate) <DoCoExporterWriterDelegate>
@end
#pragma mark - 分类 工具类
@interface AVCamCaptureManager (InternalUtilityMethods)
//屏幕方向改变后
- (void)deviceOrientationDidChange;
//根据位置获取硬件
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition)position;
//获取前置摄像头
- (AVCaptureDevice *) frontFacingCamera;
//获取后置摄像头
- (AVCaptureDevice *) backFacingCamera;
//获取麦克
- (AVCaptureDevice *) audioDevice;
//获取临时文件夹url
- (NSURL *) tempFileURL;
//更改硬件设置
-(void)changeDeviceProperty:(PropertyChangeBlock)propertyChange;
@end
@interface AVCamCaptureManager()<AVCaptureFileOutputRecordingDelegate>
{
    UIImage *_headImage;
    UIImage *_footImage;
	AVAsset *_videoAsset;
    NSString *_mergeVideoPath;
}

@end
@implementation AVCamCaptureManager
-(instancetype)init
{
	self = [super init];
	if(self){
		_orientation = AVCaptureVideoOrientationLandscapeRight;
        _maxRecordTime  = 10.0f;
		//初始化session
		[self setSession];
		
		self.videoFileDataArray = [[NSMutableArray alloc] init];
		self.totalVideoDur = 0.0f;
		self.previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
	}
	return self;
}

-(instancetype)initWithOrentation:(AVCaptureVideoOrientation)orientation andMaxRecorderTime:(float)maxRecorderTime
{
    self = [super init];
    if(self){
        //设置录制视频的方向
        if(orientation){
            _orientation = orientation;
        }else{
            _orientation = AVCaptureVideoOrientationPortrait;
        }
        
        if (maxRecorderTime) {
            _maxRecordTime = maxRecorderTime;
        }else{
            _maxRecordTime  = 10.0f;
        }
        
        [self setSession];
        
        self.videoFileDataArray = [[NSMutableArray alloc] init];
        self.totalVideoDur = 0.0f;
        self.previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
    }
    return self;
}



- (BOOL)setSession
{
    
	BOOL success = NO;
	//初始化输入输出设备并添加到session中，默认是相机
	[self setInOutDeviceInSessionAndRecorder];
	
//	设置闪关灯模式为自动
//	 Set torch and flash mode to auto
	if ([[self backFacingCamera] hasFlash]) {
		[self changeFlashMode:AVCaptureFlashModeAuto];
	}
	//设置手电模式为自动
	if ([[self backFacingCamera] hasTorch]) {
		[self changeTorchMode:AVCaptureTorchModeAuto];
	}
	success = YES;
	
	return success;
    
}

-(void)setInOutDeviceInSessionAndRecorder{
	// Init the device inputs
    //设置视频录制的fps为25
    AVCaptureDevice *backFacing = [self backFacingCamera];
    if ( [backFacing lockForConfiguration:NULL] == YES ) {        backFacing.activeVideoMinFrameDuration = CMTimeMake(1, 25);
        backFacing.activeVideoMaxFrameDuration = CMTimeMake(1, 25);
        [backFacing unlockForConfiguration];
    }
    NSError* error;
	AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:backFacing error:&error];
    if (error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CAPTURE_FAIL object:nil];//发送设置失败广播
    }
    error = nil;
	AVCaptureDeviceInput *newAudioInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self audioDevice] error:&error];
    if (error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CAPTURE_FAIL object:nil];//发送设置失败广播
    }
	//默认高质量分辨率
	// Create session (use default AVCaptureSessionPresetHigh)
	AVCaptureSession *newCaptureSession = [[AVCaptureSession alloc] init];
    
	if([newCaptureSession canSetSessionPreset:AVCaptureSessionPresetiFrame960x540]){
        [newCaptureSession setSessionPreset:AVCaptureSessionPresetiFrame960x540];
	}else{
		MyLog(@"不能设置SissionPreset");
	}
	// Add inputs and output to the capture session
	if ([newCaptureSession canAddInput:newVideoInput]) {
		[newCaptureSession addInput:newVideoInput];
	}
	if ([newCaptureSession canAddInput:newAudioInput]) {
		[newCaptureSession addInput:newAudioInput];
	}

	[self setCaptureVideoInput:newVideoInput];
	[self setCaptureAudioInput:newAudioInput];
	[self setCaptureSession:newCaptureSession];
        
    AVCamRecorder *newRecorder = [[AVCamRecorder alloc] initWithSession:self.captureSession];
    [newRecorder setDelegate:self];
        [self setRecorder:newRecorder];
        
    AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    if ([newCaptureSession canAddOutput:stillImageOutput])
    {
        [stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
        [newCaptureSession addOutput:stillImageOutput];
        [self setStillImageOutput:stillImageOutput];
    }

}

-(void)openVoice{
    if ([_captureSession canAddInput:_captureAudioInput]) {
        [_captureSession addInput:_captureAudioInput];
    }
}

-(void)closeVoice{
    [_captureSession removeInput:_captureAudioInput];
}

- (void) startRecordingWithOutputUrl:(NSURL *)outputUrl
{
    
    [self.recorder startRecordingWithOrientation:_orientation outputFileURL:outputUrl];

}

- (void)startCountDurTimer
{
	self.countDurTimer = [NSTimer scheduledTimerWithTimeInterval:COUNT_DUR_TIMER_INTERVAL target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
}

- (void)onTimer:(NSTimer *)timer
{
	self.currentVideoDur += COUNT_DUR_TIMER_INTERVAL;
	if ([_delegate respondsToSelector:@selector(captureManager:didRecordingToOutPutFileAtURL:duration:recordedVideosTotalDur:)]) {
		[_delegate captureManager:self didRecordingToOutPutFileAtURL:_currentFileURL duration:_currentVideoDur recordedVideosTotalDur:_totalVideoDur];
	}
    if (_currentVideoDur >= _maxRecordTime) {
        
        if ([_delegate respondsToSelector:@selector(captureDidToMaxVideoTime)]) {
            [_delegate captureDidToMaxVideoTime];
        }
        [self stopRecording];
    }
}

- (void)stopCountDurTimer
{
    [_countDurTimer invalidate];
    self.countDurTimer = nil;
}

//会调用delegate
//删除最后一段视频
- (void)deleteLastVideo
{
	if ([_videoFileDataArray count] == 0) {
		return;
	}
    
	kVideo *data = (kVideo *)[_videoFileDataArray lastObject];
	
    
	NSURL *videoFileURL = data.fileURL;
	CGFloat videoDuration = data.duration;
	
	[_videoFileDataArray removeLastObject];
	_totalVideoDur -= videoDuration;
	
	//delete
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSString *filePath = [[videoFileURL absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if ([fileManager fileExistsAtPath:filePath]) {
			NSError *error = nil;
			[fileManager removeItemAtPath:filePath error:&error];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				//delegate
				if ([_delegate respondsToSelector:@selector(captureManager:didRemoveVideoFileAtURL:totalDur:error:)]) {
					[_delegate captureManager:self didRemoveVideoFileAtURL:videoFileURL totalDur:_totalVideoDur error:error];
				}
			});
		}
	});
}


//不调用delegate
//删除所有的视频

- (void)deleteAllVideo
{
	for (kVideo *data in _videoFileDataArray) {
		NSURL *videoFileURL = data.fileURL;
		[FileTool removeFile:videoFileURL];
		
	}
    [_videoFileDataArray removeAllObjects];
    _totalVideoDur = 0.0f;
    dispatch_async(dispatch_get_main_queue(), ^{
        //delegate
        if ([_delegate respondsToSelector:@selector(captureManager:didRemoveVideoFileAtURL:totalDur:error:)]) {
            [_delegate captureManager:self didRemoveVideoFileAtURL:nil totalDur:_totalVideoDur error:nil];
        }
    });
}


- (void) stopRecording
{
    [self stopCountDurTimer];
    [[self recorder] stopRecording];
}


//将视频输出到相册并删除原视频
- (void)exportDidFinish:(NSURL *)outputURL {

    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL])
    {
        [library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error){
//            dispatch_async(dispatch_get_main_queue(), ^{
//                if (error) {
//                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
//                        message:@"Video Saving Failed"
//                        delegate:nil
//                        cancelButtonTitle:@"OK"
//                        otherButtonTitles:nil];
//                    [alert show];
//                } else {
//                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved"
//                        message:@"Saved To Photo Album"
//                        delegate:self
//                        cancelButtonTitle:@"OK"
//                        otherButtonTitles:nil];
//                    [alert show];
//                }
//            });
        }];
    }
}

- (BOOL) captureStillImage
{
    AVCaptureConnection *stillImageConnection = [AVCamUtilities connectionWithMediaType:AVMediaTypeVideo fromConnections:[[self stillImageOutput] connections]];
        if ([stillImageConnection isVideoOrientationSupported])
            [stillImageConnection setVideoOrientation:_orientation];
        if (stillImageConnection.isEnabled && _captureSession.isRunning && [stillImageConnection isActive] && stillImageConnection != nil) {
        [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            ALAssetsLibraryWriteImageCompletionBlock completionBlock = ^(NSURL *assetURL, NSError *error) {
                if (error) {
                    if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
                        [[self delegate] captureManager:self didFailWithError:error];
                    }
                }
            };
            
            if (imageDataSampleBuffer != NULL) {
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                UIImage *image = [[UIImage alloc] initWithData:imageData];
                if ([[self delegate] respondsToSelector:@selector(captureManagerStillImageCaptured:WithImage:)]) {
                    [[self delegate] captureManagerStillImageCaptured:self WithImage:image];
                }
            }else completionBlock(nil, error);
            
        }];
                return YES;

    }else{
        return NO;
    }
}



// 前后摄像头的转换
- (BOOL) exchangeCamera
{
	BOOL success = NO;
	
	if ([self cameraCount] > 1) {
		NSError *error;
		AVCaptureDeviceInput *newVideoInput;
		AVCaptureDevicePosition position = [[_captureVideoInput device] position];
		if (position == AVCaptureDevicePositionBack)
			newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontFacingCamera] error:&error];
		else if (position == AVCaptureDevicePositionFront)
			newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backFacingCamera] error:&error];
		else
			return success;
		if (newVideoInput != nil) {
			[[self captureSession] beginConfiguration];
			[[self captureSession] removeInput:[self captureVideoInput]];
			if ([[self captureSession] canAddInput:newVideoInput]) {
				[[self captureSession] addInput:newVideoInput];
				[self setCaptureVideoInput:newVideoInput];
			} else {
				[[self captureSession] addInput:[self captureVideoInput]];
			}
			[[self captureSession] commitConfiguration];
			success = YES;
		} else if (error) {
			if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
				[[self delegate] captureManager:self didFailWithError:error];
			}
		}
	}
	return success;
}

//总时长
- (CGFloat)getTotalVideoDuration
{
	return _totalVideoDur;
}

//现在录了多少视频
- (NSUInteger)getVideoCount
{
	return [_videoFileDataArray count];
}

#pragma mark-Get Device Counts
- (NSUInteger) cameraCount
{
	return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}

- (NSUInteger) micCount
{
	return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] count];
}

#pragma mark-Camera Properties
// 定点聚焦
- (void) autoFocusAtPoint:(CGPoint)point
{
	AVCaptureDevice *device = [[self captureVideoInput] device];
	if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
		NSError *error;
		if ([device lockForConfiguration:&error]) {
			[device setFocusPointOfInterest:point];
			[device setFocusMode:AVCaptureFocusModeAutoFocus];
			[device unlockForConfiguration];
		} else {
			if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
				[[self delegate] captureManager:self didFailWithError:error];
			}
		}
	}
}

// 自动聚焦模式
- (void) continuousFocusAtPoint:(CGPoint)point
{
	AVCaptureDevice *device = [[self captureVideoInput] device];
	
	if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
		NSError *error;
		if ([device lockForConfiguration:&error]) {
			[device setFocusPointOfInterest:point];
			[device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
			[device unlockForConfiguration];
		} else {
			if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
				[[self delegate] captureManager:self didFailWithError:error];
			}
		}
	}
}

// 锁定焦距
- (void) LockedFocus
{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusPointOfInterestSupported] && [captureDevice isFocusModeSupported:AVCaptureFocusModeLocked]) {
            [captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
    }];
}

//更改闪光灯模式
-(void)changeFlashMode:(AVCaptureFlashMode)flashMode{
	[self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
		if ([captureDevice isFlashModeSupported:flashMode]) {
			[captureDevice setFlashMode:flashMode];
		}
	}];

}
//更改手电模式
-(void)changeTorchMode:(AVCaptureTorchMode)torchMode{
	[self changeDeviceProperty:^(AVCaptureDevice *captureDevice){
		if ([captureDevice isTorchModeSupported:torchMode]) {
			[captureDevice setTorchMode:torchMode ];
		}
	}];
}

-(void) changeZoomFactor:(CGFloat)newZoom{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice){
        captureDevice.videoZoomFactor = newZoom;
    }];
}

//内存警告时及时销毁一些对象释放内存
- (void)memoryWarning:(NSNotification*)note{

}

#pragma mark-和outputfile的代理
-(void)				 captureOutput:(AVCaptureFileOutput *)captureOutput
didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
          fromConnections:(NSArray *)connections
{
    self.currentFileURL =  self.movieFileOutput.outputFileURL;
    self.currentVideoDur = 0.0f;
    [self startCountDurTimer];
    if ([[self delegate] respondsToSelector:@selector(captureManagerRecordingBegan:)]) {
        [[self delegate] captureManagerRecordingBegan:self];
    }
}

- (void)			  captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)anOutputFileURL
           fromConnections:(NSArray *)connections
                     error:(NSError *)error
{
    kVideo *data = [[kVideo alloc]init];
    AVURLAsset *video = [AVURLAsset URLAssetWithURL:anOutputFileURL options:nil];
    _currentVideoDur = video.duration.value/video.duration.timescale;
    data.duration = _currentVideoDur;
    data.fileURL = anOutputFileURL;
    [_videoFileDataArray addObject:data];
    self.totalVideoDur += _currentVideoDur;
    self.currentVideoDur = 0.0f;
    if([_delegate respondsToSelector:@selector(captureManagerRecordingFinished:outputFileURL:)]){
        MyLog(@"将要进入录像完成的代理了--%@",[anOutputFileURL absoluteString]);
        [self.delegate captureManagerRecordingFinished:self outputFileURL:anOutputFileURL];
    }
}

@end



#pragma mark -对工具分类的实现
@implementation AVCamCaptureManager (InternalUtilityMethods)

// Keep track of current device orientation so it can be applied to movie recordings and still image captures
//监控手机方向的变化  要和摄像头的方位保持一致
- (void)deviceOrientationDidChange
{
	UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
	
	if (deviceOrientation == UIDeviceOrientationPortrait)
		self.orientation = AVCaptureVideoOrientationPortrait;
	else if (deviceOrientation == UIDeviceOrientationPortraitUpsideDown)
		self.orientation = AVCaptureVideoOrientationPortraitUpsideDown;
	
	// AVCapture and UIDevice have opposite meanings for landscape left and right (AVCapture orientation is the same as UIInterfaceOrientation)
	else if (deviceOrientation == UIDeviceOrientationLandscapeLeft)
		self.orientation = AVCaptureVideoOrientationLandscapeRight;
	else if (deviceOrientation == UIDeviceOrientationLandscapeRight)
		self.orientation = AVCaptureVideoOrientationLandscapeLeft;
	
	// Ignore device orientations for which there is no corresponding still image orientation (e.g. UIDeviceOrientationFaceUp)
}

// Find a camera with the specificed AVCaptureDevicePosition, returning nil if one is not found
//根据AVCaptureDevicePositon获取硬件，如果没有找到，返回nil
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *device in devices) {
		if ([device position] == position) {
			return device;
		}
	}
	return nil;
}

// Find a front facing camera, returning nil if one is not found
//获取前置摄像头，如果没有找到，返回nil
- (AVCaptureDevice *) frontFacingCamera
{
	return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

// Find a back facing camera, returning nil if one is not found
//获取后置摄像头，如果没有找到，返回nil
- (AVCaptureDevice *) backFacingCamera
{
	return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

// Find and return an audio device, returning nil if one is not found
//获取mic，如果没有找到，返回nil
- (AVCaptureDevice *) audioDevice
{
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
	if ([devices count] > 0) {
		return [devices objectAtIndex:0];
	}
	return nil;
}

//获取临时文件路径
- (NSURL *) tempFileURL
{
	return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"]];
}



//将硬件属性设置统一
-(void)changeDeviceProperty:(PropertyChangeBlock)propertyChange{
	AVCaptureDevice *captureDevice= [self.captureVideoInput device];
	NSError *error;
	//注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
	if ([captureDevice lockForConfiguration:&error]) {
		propertyChange(captureDevice);
		[captureDevice unlockForConfiguration];
	}else{
		MyLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}

@end

#pragma mark -实现代理 RecorderDelegate
@implementation AVCamCaptureManager (RecorderDelegate)
//开始录像代理事件
-(void)recorderRecordingDidBegin:(AVCamRecorder *)recorder
{
	self.currentFileURL = recorder.movieFileOutput.outputFileURL;
	self.currentVideoDur = 0.0f;
	[self startCountDurTimer];
	if ([[self delegate] respondsToSelector:@selector(captureManagerRecordingBegan:)]) {
		[[self delegate] captureManagerRecordingBegan:self];
	}
}

//录像完成输出到文件的代理
-(void)recorder:(AVCamRecorder *)recorder recordingDidFinishToOutputFileURL:(NSURL *)outputFileURL error:(NSError *)error
{
	kVideo *data = [[kVideo alloc]init];
	data.duration = _currentVideoDur;
	data.fileURL = outputFileURL;
	[_videoFileDataArray addObject:data];
	self.totalVideoDur += _currentVideoDur;
    if([_delegate respondsToSelector:@selector(captureManagerRecordingFinished:outputFileURL:)]){
        MyLog(@"将要进入录像完成的代理了--%@",[outputFileURL absoluteString]);
		[self.delegate captureManagerRecordingFinished:self outputFileURL:outputFileURL];
	}
}


@end

@implementation AVCamCaptureManager(DoCoExporterWriterDelegate) 

-(void)readingAndWritingDidFinishSuccessfullyWithOutputURL:(NSURL *)outputURL{
    dispatch_async(dispatch_get_main_queue(), ^{
//        UIImage *image = [FinishTool thumbnailImageForVideo:outputURL atTime:8];
//        NSData *data = UIImagePNGRepresentation(image);
//        [BaseHttpTool uploadData:data token:@"vUQlBXXwgYNrGLunTtVbEi40TGU41MvT8rw8N2Qj:Z5qsp9O49BkzJJ5vEtHEePeBs_U=:eyJzY29wZSI6ImRvY28iLCJkZWFkbGluZSI6MTU4NzAxNDkxN30=" progress:nil
//            completion:^(NSDictionary *dic){
//                NSString *key = dic[@"key"];
//                NSString *baseUrl = @"http://7xir3h.com2.z0.glb.qiniucdn.com/";
//                NSString *imageUrl = [NSString stringWithFormat:@"%@%@",baseUrl,key];
//                [BaseHttpTool uploadFileWithFilePath:[FileTool getFilePathFromFileURL:outputURL] token:@"vUQlBXXwgYNrGLunTtVbEi40TGU41MvT8rw8N2Qj:Z5qsp9O49BkzJJ5vEtHEePeBs_U=:eyJzY29wZSI6ImRvY28iLCJkZWFkbGluZSI6MTU4NzAxNDkxN30="
//                                            progress:^(float percent){
//                                                if ([_delegate respondsToSelector:@selector(didBeginUploadFileWithProgress:)] ) {
//                                                    [_delegate didBeginUploadFileWithProgress:percent];
//                                                }
//                                            }completion:^(NSDictionary *dic){
//                                                
//                                                NSString *key = dic[@"key"];
//                                                NSString *baseUrl = @"http://7xir3h.com2.z0.glb.qiniucdn.com/";
//                                                NSString *absoluteUrl = [NSString stringWithFormat:@"%@%@",baseUrl,key];
//                                                [BaseHttpTool postWithPath:@"api/video/video_add/" params:@{
//                                                                                                            @"classification_id" : @"1",
//                                                                                                            @"name" : @"测试一下",
//                                                                                                            @"duration" :@"30",
//                                                                                                            @"description" : @"test",
//                                                                                                            @"url" : absoluteUrl,
//                                                                                                            @"cover" : imageUrl,
//                                                                                                            @"fps" : @"25",
//                                                                                                            @"resolution" : @"960*540",
//                                                                                                            @"extension_name" : @"mp4",
//                                                                                                            @"bitrate" : @"3.52mps",
//                                                                                                            @"is_editor_choice" : @"0",
//                                                                                                            @"is_private" : @"0",
//                                                                                                            @"is_cross_screen" : @"1",
//                                                                                                            @"tag" : @""
//                                                                                                            }
//                                                                   success:^(id JSON){
//                                                                       if ([_delegate respondsToSelector:@selector(didFinishUploadFileLocalUrl:QiNiuUrl:)]){
//                                                                           [_delegate didFinishUploadFileLocalUrl:outputURL QiNiuUrl:absoluteUrl];
//                                                                       }
//                                                                   }
//                                                                   failure:^(NSError *error){
//                                                                       
//                                                                   }];
//                                            }];
//
//            }];
//        
        [self exportDidFinish:outputURL];
        if ([_delegate respondsToSelector:@selector(captureManager:didFinishMergingVideosToOutPutFileAtURL:)]){
            [_delegate captureManager:self didFinishMergingVideosToOutPutFileAtURL:outputURL];
        }

    });
}

@end

