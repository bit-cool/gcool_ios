//
//  AVCamCaptureManager.h
//  视频录制处理器
//
//  Created by PfcStyle on 15-1-21.
//  Copyright (c) 2015年 PfcStyle. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#define CAPTURE_FAIL @"captureConfigFail"

@class AVCamRecorder;
@protocol AVCamCaptureManagerDelegate;
@interface AVCamCaptureManager : NSObject
//需要视频和音频两个硬件输入设备
@property(nonatomic,strong)AVCaptureDeviceInput *captureVideoInput;
@property(nonatomic,strong)AVCaptureDeviceInput *captureAudioInput;
//输出视频文件
@property(nonatomic,strong)AVCaptureOutput *captureOutput;
//输出照片
@property (nonatomic,strong) AVCaptureStillImageOutput *stillImageOutput;
//视频输出
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
//软硬件的对话管理对象
@property(nonatomic,strong)AVCaptureSession *captureSession;
//声明一个摄像机对象
@property (nonatomic,strong) AVCamRecorder *recorder;
//显示内容的图层
@property (nonatomic,strong)AVCaptureVideoPreviewLayer *previewLayer;

//视频录制的重力参数
@property(nonatomic,assign)AVCaptureVideoOrientation orientation;

//硬件连接观察者
@property (nonatomic,assign) id deviceConnectedObserver;
@property (nonatomic,assign) id deviceDisconnectedObserver;
//代理对象
@property(nonatomic,weak)id<AVCamCaptureManagerDelegate> delegate;
//后台任务的标志  当多个后台任务同时运行时才会体现作用
@property (nonatomic,assign) UIBackgroundTaskIdentifier backgroundRecordingID;

@property (nonatomic) id runtimeErrorHandlingObserver;

//计时器
@property (strong, nonatomic) NSTimer *countDurTimer;
//当前视频时长
@property (assign, nonatomic) CGFloat currentVideoDur;
//当前视频文件路径
@property (assign, nonatomic) NSURL *currentFileURL;
//所有视频总时长
@property (assign ,nonatomic) CGFloat totalVideoDur;
//录制的视频数组
@property (strong, nonatomic) NSMutableArray *videoFileDataArray;

//最长录制时间
@property(nonatomic,assign)float maxRecordTime;
//最短录制时间
@property(nonatomic,assign)float minRecordTime;

//初始化函数
-(instancetype)initWithOrentation:(AVCaptureVideoOrientation)orientation andMaxRecorderTime:(float)maxRecorderTime;



//现在录了多少视频
- (NSUInteger)getVideoCount;
//获取总得时长
- (CGFloat)getTotalVideoDuration;
//删除最后一个视频
- (void)deleteLastVideo;
//删除所有的视频
- (void)deleteAllVideo;

//session设置函数
-(BOOL)setSession;

-(void)openVoice;
-(void)closeVoice;

//获取摄像头数量
- (NSUInteger) cameraCount;
//获取mic数量
- (NSUInteger) micCount;
//开启录像
- (void) startRecordingWithOutputUrl:(NSURL *)outputUrl;
//停止录像
- (void) stopRecording;
//捕获静态图片
- (BOOL) captureStillImage;
//交换前后摄像头
- (BOOL) exchangeCamera;
//自动对点对焦（响应点击）
- (void) autoFocusAtPoint:(CGPoint)point;
//自动对焦
- (void) continuousFocusAtPoint:(CGPoint)point;
//锁定焦距
- (void) LockedFocus;
//改变手电模式
- (void) changeTorchMode:(AVCaptureTorchMode)torchMode;
//改变闪光灯模式
-(void)changeFlashMode:(AVCaptureFlashMode)flashMode;
//改变焦距
-(void) changeZoomFactor:(CGFloat)newZoom;
@end

@protocol AVCamCaptureManagerDelegate <NSObject>
@optional
- (void) captureManager:(AVCamCaptureManager *)captureManager didFailWithError:(NSError *)error;
- (void) captureManagerRecordingBegan:(AVCamCaptureManager *)captureManager;
- (void) captureManagerRecordingFinished:(AVCamCaptureManager *)captureManager outputFileURL:(NSURL *)outputFileURL;
- (void)captureManager:(AVCamCaptureManager *)captureManager didFinishMergingVideosToOutPutFileAtURL:(NSURL *)outputFileURL;

- (void)captureManager:(AVCamCaptureManager *)captureManager didRecordingToOutPutFileAtURL:(NSURL *)outputFileURL duration:(CGFloat)videoDuration recordedVideosTotalDur:(CGFloat)totalDur;

- (void)captureManager:(AVCamCaptureManager *)captureManager didRemoveVideoFileAtURL:(NSURL *)fileURL totalDur:(CGFloat)totalDur error:(NSError *)error;

- (void) captureManagerDeviceConfigurationChanged:(AVCamCaptureManager *)captureManager;

- (void) captureManagerStillImageCaptured:(AVCamCaptureManager *)captureManager WithImage:(UIImage *)image;

-(void) didBeginUploadFileWithProgress:(float)percent;

-(void) didFinishUploadFileLocalUrl:(NSURL *)localUrl QiNiuUrl:(NSString *)remoteStr;

-(void) captureDidToMaxVideoTime;
@end