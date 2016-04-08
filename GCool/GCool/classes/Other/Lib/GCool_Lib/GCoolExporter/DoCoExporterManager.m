//
//  DoCoExporterManager.m
//  doco_ios_app
//
//  Created by developer on 15/5/1.
//  Copyright (c) 2015年 developer. All rights reserved.
//

#import "DoCoExporterManager.h"
#import "DoCoVideoLayerAnimationManager.h"
#import "DoCoExporterWriter.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import "AnimationAnalysisTool.h"
#import "FileTool.h"
@interface DoCoExporterManager()

//@property (nonatomic,strong) AVPlayerItemVideoOutput* output;
@property (nonatomic,strong) AVAssetWriter* writer;
@property (nonatomic,strong) AVAssetWriterInputPixelBufferAdaptor* adaptor;
@property (nonatomic,strong) AVAssetWriterInput* input;
@property (nonatomic,strong) CIContext* context;
@property (nonatomic,strong) AVAssetReader* reader;
@property (nonatomic,strong) AVAssetReaderVideoCompositionOutput* readerOutput;
@property (nonatomic,strong) AVAssetWriterInput* audioInput;
@property (nonatomic,strong) AVAssetReaderAudioMixOutput* audioOutput;

@end

@implementation DoCoExporterManager{
    ProgressBlock _progresss;
}

#pragma mark-实现类方法
//输出到相册

+(void)exportDidFinish:(NSURL *)outputURL{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL])
    {
        
        [library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
            });
            
            
        }];
    }

}
+ (void)exportDidFinish:(NSURL *)outputURL complemetion:(CompletionBlock)complemetion{
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL])
    {
        
        [library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
                if (complemetion) {
                    complemetion(assetURL);
                }
            });
            
            
        }];
    }
}

-(void)videoApplyAnimationAtFileURL:(NSURL *)fileURL renderSize:(CGSize)renderSize duration:(float)duration outputFilePath:(NSString *)outputfilePath Animation:(AnimationBlock)animation Dubbing:(nullable NSURL *)dubbing{
    
    NSURL* url = fileURL;
    NSError *error = nil;
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    //音频读取
    AVAsset *audioAsset;
    if (dubbing && [FileTool fileIsExistAtPath:dubbing.path]) {//判断配音文件是否存在
        audioAsset = [AVAsset assetWithURL:dubbing];
    }
    else{
        audioAsset = [AVAsset assetWithURL:fileURL];
    }
    int i = 0;
    while(audioAsset==nil || [audioAsset tracksWithMediaType:AVMediaTypeAudio].count <= 0){//防止偶尔的读取失败
        if (dubbing && [FileTool fileIsExistAtPath:dubbing.path]) {
            audioAsset = [AVAsset assetWithURL:dubbing];
        }
        else{
            audioAsset = [AVAsset assetWithURL:fileURL];
        }
        if (i>=5) {//防止死循环
            audioAsset = nil;//也可能出现原来就没有声音的情况啦
            break;
        }
        i++;
    }
    //视频读取
    AVAsset *asset = [AVAsset assetWithURL:url];
    NSArray *videoTracks =[asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *assetTrack = ([videoTracks count]>0)?[videoTracks objectAtIndex:0]:nil;
    i = 0;
    while (!assetTrack) {//防止偶尔的读取失败
        MyLog(@"单个videoasset为空");
        asset = [AVAsset assetWithURL:url];
        videoTracks =[asset tracksWithMediaType:AVMediaTypeVideo];
        assetTrack = ([videoTracks count]>0)?[videoTracks objectAtIndex:0]:nil;
        if (i >= 5) {//防止死循环
            if (_delegate) {
                [_delegate ExporterManager:self DidFailedComplementWithError:nil];
            }
            return;
        }
        i++;
    }
    
    //assettrack默认是横屏模式，所以这里宽>高
    CGSize naturalSize;
    if (renderSize.height > renderSize.width) {
        //如果是竖屏
        if (assetTrack.naturalSize.height < assetTrack.naturalSize.width) {
            naturalSize.width = assetTrack.naturalSize.height;
            naturalSize.height = assetTrack.naturalSize.width;
        }else{
            naturalSize.width = assetTrack.naturalSize.width;
            naturalSize.height = assetTrack.naturalSize.height;
        }
    }else{//横屏
        naturalSize.width = assetTrack.naturalSize.width;
        naturalSize.height = assetTrack.naturalSize.height;
    }
    MyLog(@"%@",[NSValue valueWithCGSize:assetTrack.naturalSize]);
    
    CMTime dur;
    if (duration>0) {
        dur = CMTimeMake(600*duration, 600);
    }else{
        dur = asset.duration;
        if ((_isOriginalSoundOpen==YES || dubbing!=nil) && audioAsset != nil) {
            AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            
            NSArray *trackarr = [audioAsset tracksWithMediaType:AVMediaTypeAudio];

            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, dur)
                                ofTrack:([trackarr count]>0)?[trackarr objectAtIndex:0]:nil
                                 atTime:kCMTimeZero
                                  error:nil];
        }
    }
   
    
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, dur)
                        ofTrack:assetTrack
                         atTime:kCMTimeZero
                          error:&error];
    
    //调整视频方向、大小一致
    //视频大小调整策略
    /**
     *1.强制拉伸或者缩小到960*540  填满  --
     *2.保持比例不变，放缩到到等高或者等宽，居中显示
     *3.保持原大小，居中显示
     *
     **/
    AVMutableVideoCompositionLayerInstruction *layerInstruciton = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    
    float rateW = naturalSize.width/renderSize.width;
    float rateH = naturalSize.height/renderSize.height;
    
    CGAffineTransform transform = CGAffineTransformScale(assetTrack.preferredTransform, rateW, rateH);
    
    [layerInstruciton setTransform:transform atTime:kCMTimeZero];
    [layerInstruciton setOpacity:0.0 atTime:dur];
    
    //get save path
    
    NSURL *outputURL = [NSURL fileURLWithPath:outputfilePath];
    
    
    //export
    AVMutableVideoCompositionInstruction *mainInstruciton = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruciton.timeRange = CMTimeRangeMake(kCMTimeZero, dur);
    mainInstruciton.layerInstructions = @[layerInstruciton];
    AVMutableVideoComposition *videoCom = [AVMutableVideoComposition videoComposition];
    videoCom.instructions = @[mainInstruciton];
    videoCom.frameDuration = CMTimeMake(1, 25);
    videoCom.renderSize = CGSizeMake(renderSize.width, renderSize.height);
    
    if(animation){
        @synchronized(self) {
            animation(videoCom,renderSize);
        }
    }
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPreset960x540];
    exporter.videoComposition = videoCom;
    exporter.outputURL = outputURL;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    _exporterSession = exporter;
    dispatch_async(dispatch_get_main_queue(), ^{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(onProgress:) userInfo:_exporterSession repeats:YES];
    });
    [_exporterSession exportAsynchronouslyWithCompletionHandler:^{
        MyLog(@"单个error:%@",exporter.error);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_exporterSession.status == AVAssetExportSessionStatusFailed) {
                MyLog(@"到了错误状态");
                if([_delegate respondsToSelector:@selector(ExporterManager:DidFailedComplementWithError:)]){
                    [_delegate ExporterManager:self DidFailedComplementWithError:_exporterSession.error];
                }
            }else if (_exporterSession.status == AVAssetExportSessionStatusCompleted){
                if ([_delegate respondsToSelector:@selector(ExporterManager:DidSuccessComplementWithOutputUrl:)]) {
                    [_delegate ExporterManager:self DidSuccessComplementWithOutputUrl:outputURL];
                }
            }
            
        });
    }];
    
}

- (void)mergeAndExportVideosAtFileURLs:(NSDictionary *)fileURLArray renderSize:(CGSize)renderSize mergerFilePath:(NSString *)mergeFilePath cutto:(CuttoBlock)cutto Animation:(OverallAnimationBlock)animation Begin:(BeginBlock)begin
{
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    
    DoCoVideoLayerAnimationManager *manager = [[DoCoVideoLayerAnimationManager alloc]init];
        
    for (int i=0;i<fileURLArray.count;i++) {
        NSURL *fileUrl = fileURLArray[[NSString stringWithFormat:@"part%d",i+1]];
        AVAsset *asset = [AVAsset assetWithURL:fileUrl];
        NSArray *videoTracks =[asset tracksWithMediaType:AVMediaTypeVideo];
        AVAssetTrack *assetTrack = ([videoTracks count]>0)?[videoTracks objectAtIndex:0]:nil;
        while (!assetTrack) {//防止偶尔的读取失败
            MyLog(@"总体的videoasset为空");
            asset = [AVAsset assetWithURL:fileUrl];
            videoTracks =[asset tracksWithMediaType:AVMediaTypeVideo];
            assetTrack = ([videoTracks count]>0)?[videoTracks objectAtIndex:0]:nil;
        }
        
        [manager.assetArray addObject:asset];
    }
    [manager firstTrack];
    
    if (cutto) {
        @synchronized(self) {
            cutto(manager);
        }
    }
    NSURL *waterURL = [[NSBundle mainBundle]URLForResource:(renderSize.height>renderSize.width)?@"water_portrait":@"water" withExtension:@"mov"];
    AVAsset *waterAsset = [AVAsset assetWithURL:waterURL];
    
    
    
    NSArray *videoTracks = [waterAsset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *videoTrack = videoTracks[0];
    
    AVMutableCompositionTrack *videoComTrack = [manager.mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [videoComTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, waterAsset.duration)
                           ofTrack:videoTrack
                            atTime:manager.totalDuration
                             error:nil];
    
    //后视频动画设置
    AVMutableVideoCompositionLayerInstruction *layerInstruciton = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoComTrack];
    
    AVMutableCompositionTrack *audioTrack = [manager.mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    NSArray *trackarr = [waterAsset tracksWithMediaType:AVMediaTypeAudio];
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, waterAsset.duration)
                        ofTrack:([trackarr count]>0)?[trackarr objectAtIndex:0]:nil
                         atTime:manager.totalDuration
                          error:nil];
    
    manager.totalDuration = CMTimeAdd(manager.totalDuration, waterAsset.duration);
    //这是为了防止ghost现象  应该在本段最后添加效果
    [layerInstruciton setOpacity:0.0 atTime:manager.totalDuration];
    [manager.layerInstructionArray insertObject:layerInstruciton atIndex:0];
    
    
    //video
    AVMutableVideoCompositionInstruction *mainInstruciton = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruciton.timeRange = CMTimeRangeMake(kCMTimeZero, manager.totalDuration);
    mainInstruciton.layerInstructions = manager.layerInstructionArray;
    AVMutableVideoComposition *videoCom = [AVMutableVideoComposition videoComposition];
    videoCom.instructions = @[mainInstruciton];
    videoCom.frameDuration = CMTimeMake(1, 25);
    videoCom.renderSize = manager.renderSize;
    
    if(animation){
        @synchronized(self) {
            animation(videoCom,manager.renderSize,manager);
        }
    }
    
    //export
    //audio
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = [NSArray arrayWithArray:manager.audioMixParas];
    
    NSURL *mergeFileURL = [NSURL fileURLWithPath:mergeFilePath];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:manager.mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.videoComposition = videoCom;
    exporter.audioMix = audioMix;
    exporter.outputURL = mergeFileURL;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    _exporterSession = exporter;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(onProgress:) userInfo:_exporterSession repeats:YES];
    });
    
    [_exporterSession exportAsynchronouslyWithCompletionHandler:^{
        MyLog(@"总体的error:%@",exporter.error);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_exporterSession.status == AVAssetExportSessionStatusFailed) {
                if([_delegate respondsToSelector:@selector(ExporterManager:DidFailedComplementWithError:)]){
                    [_delegate ExporterManager:self DidFailedComplementWithError:_exporterSession.error];
                }
            }else if (_exporterSession.status == AVAssetExportSessionStatusCompleted){
                if ([_delegate respondsToSelector:@selector(ExporterManager:DidSuccessComplementWithOutputUrl:)]) {
                    [_delegate ExporterManager:self DidSuccessComplementWithOutputUrl:mergeFileURL];
                }
            }
            
        });
    }];
}

-(void)transVideoAtFileURL:(NSURL *)fileURL renderSize:(CGSize)renderSize outputURL:(NSURL *)outputURL progress:(ProgressBlock)progress Completion:(CompletionBlock)completion{
    NSError *error = nil;
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    AVAsset *asset = [AVAsset assetWithURL:fileURL];
    NSArray *videoTracks =[asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *assetTrack = ([videoTracks count]>0)?[videoTracks objectAtIndex:0]:nil;
    while (!assetTrack) {//防止偶尔的读取失败
        MyLog(@"单个videoasset为空");
        asset = [AVAsset assetWithURL:fileURL];
        videoTracks =[asset tracksWithMediaType:AVMediaTypeVideo];
        assetTrack = ([videoTracks count]>0)?[videoTracks objectAtIndex:0]:nil;
    }
    
    //assettrack默认是横屏模式，所以这里宽>高
    CGSize naturalSize;
//    if (orientation ==AVCaptureVideoOrientationPortrait) {
//        //如果是竖屏
//        naturalSize.width = assetTrack.naturalSize.height;
//        naturalSize.height = assetTrack.naturalSize.width;
//    }else{//横屏
        naturalSize.width = assetTrack.naturalSize.width;
        naturalSize.height = assetTrack.naturalSize.height;
//    }
    
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSArray *trackarr = [asset tracksWithMediaType:AVMediaTypeAudio];
    CMTime dur;
    dur = asset.duration;
    
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, dur)
                        ofTrack:([trackarr count]>0)?[trackarr objectAtIndex:0]:nil
                         atTime:kCMTimeZero
                          error:nil];
    
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, dur)
                        ofTrack:assetTrack
                         atTime:kCMTimeZero
                          error:&error];
    
    //调整视频方向、大小一致
    //视频大小调整策略
    /**
     *1.强制拉伸或者缩小到960*540  填满  --
     *2.保持比例不变，放缩到到等高或者等宽，居中显示
     *3.保持原大小，居中显示
     *
     **/
    AVMutableVideoCompositionLayerInstruction *layerInstruciton = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    
    float rateW = naturalSize.width/renderSize.width;
    float rateH = naturalSize.height/renderSize.height;
    
    CGAffineTransform transform = CGAffineTransformScale(assetTrack.preferredTransform, rateW, rateH);
    
    [layerInstruciton setTransform:transform atTime:kCMTimeZero];
    [layerInstruciton setOpacity:0.0 atTime:asset.duration];
    
    //export
    AVMutableVideoCompositionInstruction *mainInstruciton = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruciton.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    mainInstruciton.layerInstructions = @[layerInstruciton];
    AVMutableVideoComposition *videoCom = [AVMutableVideoComposition videoComposition];
    videoCom.instructions = @[mainInstruciton];
    videoCom.frameDuration = CMTimeMake(1, 25);
    videoCom.renderSize = CGSizeMake(renderSize.width, renderSize.height);
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];
    exporter.videoComposition = videoCom;
    exporter.outputURL = outputURL;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    _exporterSession = exporter;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(transProgress:) userInfo:_exporterSession repeats:YES];
        if (progress) {
            _progresss = progress;
        }
        
    });
    [_exporterSession exportAsynchronouslyWithCompletionHandler:^{
        MyLog(@"转换error:%@",exporter.error);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_exporterSession.status == AVAssetExportSessionStatusFailed) {
                MyLog(@"转换格式错误");
            }else if (_exporterSession.status == AVAssetExportSessionStatusCompleted){
                if (completion) {
                    completion(outputURL);
                }
            }
            
        });
    }];

}

-(void)transProgress:(NSTimer *)timer{
    AVAssetExportSession *exporter = [timer userInfo];
    AVAssetExportSessionStatus status = [exporter status];
    float progress = 0;
    if (status == AVAssetExportSessionStatusExporting) {
        progress = _exporterSession.progress;
        
    } else if (status == AVAssetExportSessionStatusCompleted) {
        progress = 1;
        [timer invalidate];
        self.timer = nil;
    }
    if (_progresss) {
        _progresss(progress);
    }

}

- (void)onProgress:(NSTimer *)timer{
    AVAssetExportSession *exporter = [timer userInfo];
    AVAssetExportSessionStatus status = [exporter status];
    float progress = 0;
    if (status == AVAssetExportSessionStatusExporting) {
        progress = _exporterSession.progress;
        if ([_delegate respondsToSelector:@selector(ExporterManager:processingWithProgress:)]) {
            [_delegate ExporterManager:self processingWithProgress:progress];
        }
    } else if (status == AVAssetExportSessionStatusCompleted) {
        progress = 1;
        [timer invalidate];
        self.timer = nil;
    }
}
//裁剪视频
+(void)trimVideo:(NSURL *)fileURL startTime:(float)startTime endTime:(float)endTime toFilePath:(NSString *)newPath Completion:(CompletionBlock)completion{
    
    NSURL *newURL = [NSURL fileURLWithPath:newPath];
    [FileTool removeFile:newURL];
    AVAsset *asset = [AVAsset assetWithURL:fileURL];
    
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
    if ([compatiblePresets containsObject:AVAssetExportPreset960x540]) {
        
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
                                               initWithAsset:asset presetName:AVAssetExportPreset960x540];
        MyLog(@"newURL:%@",newURL.absoluteString);
        exportSession.outputURL = newURL;
        exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        
        CMTime start = CMTimeMakeWithSeconds(startTime, asset.duration.timescale);
        CMTime duration = CMTimeMakeWithSeconds(endTime - startTime, asset.duration.timescale);
        CMTimeRange range = CMTimeRangeMake(start, duration);
        exportSession.timeRange = range;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            MyLog(@"TrimError:%@",exportSession.error);
            if (completion) {
                completion(newURL);
            }
        }];
    }
}
//也是剪裁
+(void)trimVideoWithAsset:(AVAsset*)asset startTime:(float)startTime endTime:(float)endTime toFilePath:(NSString *)newPath Completion:(CompletionBlock)completion{
    
    NSURL *newURL = [NSURL fileURLWithPath:newPath];
    [FileTool removeFile:newURL];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
    if ([compatiblePresets containsObject:AVAssetExportPreset960x540]) {
        
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
                                               initWithAsset:asset presetName:AVAssetExportPreset960x540];
        // Implementation continues.
        MyLog(@"newURL:%@",newURL.absoluteString);
        exportSession.outputURL = newURL;
        exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        
        CMTime start = CMTimeMakeWithSeconds(startTime, asset.duration.timescale);
        CMTime duration = CMTimeMakeWithSeconds(endTime - startTime, asset.duration.timescale);
        CMTimeRange range = CMTimeRangeMake(start, duration);
        exportSession.timeRange = range;
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            MyLog(@"TrimError:%@",exportSession.error);
            if (completion) {
                completion(newURL);
                
            }
        }];
    }
}

-(void)addFilterWithUrl:(NSURL *)url OutputUrl:(NSURL *)output Orientation:(NSInteger)orientation Completion:(CompletionBlock)completion{
    
    AVAsset* asset =  [AVAsset assetWithURL:url];
    int safe = 0;//只是个保险
    while(asset.tracks.count<=0) {//防止偶尔的读取失败
        asset = [AVAsset assetWithURL:url];
        safe++;
        if (safe > 20) {
            return;
        }
    }
    
    [FileTool removeFile:output];
    CGSize renderSize;
    if (orientation == AVCaptureVideoOrientationPortrait) {
        renderSize = CGSizeMake(540, 960);
    }else{
        renderSize = CGSizeMake(960, 540);
    }
    _context = [CIContext contextWithOptions:@{kCIContextWorkingColorSpace:[NSNull null]}];
    
    UIDevice* device = [UIDevice currentDevice];
    CGFloat version = [device.systemVersion floatValue];
    if (version >= 9.0) {
        AVMutableVideoComposition* videoCom = [AVMutableVideoComposition videoCompositionWithAsset:asset applyingCIFiltersWithHandler:^(AVAsynchronousCIImageFilteringRequest * _Nonnull request) {
            CIImage* output = request.sourceImage;
            output = [_filterTool filtImage:request.sourceImage WithOption:nil];
            [request finishWithImage:output context:_context];
        }];
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
                                               initWithAsset:asset presetName:AVAssetExportPresetHighestQuality];

        exportSession.videoComposition = videoCom;
        exportSession.outputURL = output;
        exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            MyLog(@"filterError:%@",exportSession.error);
            if (completion) {
                completion(output);
            }
            if (_delegate) {
                [_delegate ExporterManager:self DidSuccessComplementWithOutputUrl:output];
            }
        }];

    }else{
        [self setupReaderWithAsset:asset];
        [self setupWriterWithOutputUrl:output RenderSize:renderSize];
        
        dispatch_queue_t videoQueue = dispatch_queue_create("video", NULL);
        dispatch_queue_t audioQueue = dispatch_queue_create("audio", NULL);
        dispatch_queue_t main = dispatch_queue_create("main", NULL);
        dispatch_group_t group = dispatch_group_create();
        
        [_reader startReading];
        [_writer startWriting];
        [_writer startSessionAtSourceTime:kCMTimeZero];
        
        __block BOOL video = NO;
        __block BOOL audio = NO;
        
        if (_readerOutput) {//是否有视频
            dispatch_group_enter(group);
            [_input requestMediaDataWhenReadyOnQueue:videoQueue usingBlock:^{
                while (_input.readyForMoreMediaData && !video) {
                    
                    CMSampleBufferRef sampleBuffer =[_readerOutput copyNextSampleBuffer];
                    if (sampleBuffer == NULL) {
                        MyLog(@"视频结束");
                        video = YES;
                        dispatch_group_leave(group);
                        if (!audio) {
                            [_input markAsFinished];
                        }
                        break;
                    }else{
                        CVPixelBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
                        CMTime time =  CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                        
                        CIImage* outputImage = [CIImage imageWithCVPixelBuffer:buffer];
                        
                        outputImage = [_filterTool filtImage:outputImage WithOption:nil];
                        
                        
                        CVPixelBufferRef newBuffer = NULL;
                        
                        CVReturn status = CVPixelBufferPoolCreatePixelBuffer(NULL, _adaptor.pixelBufferPool,&newBuffer);
                        
                        [_context render:outputImage toCVPixelBuffer:newBuffer bounds:outputImage.extent colorSpace:nil];
                        BOOL yes = [_adaptor appendPixelBuffer:newBuffer withPresentationTime:time];
                        if (!yes){
                            MyLog(@"失败%lld error%d",time.value,status);
                        }
                        if (sampleBuffer) {
                            CFRelease(sampleBuffer);
                        }
                        if (newBuffer) {
                            CFRelease(newBuffer);
                        }
                    }
                }
            }];
        }else{
            [_input markAsFinished];
            video = YES;
        }
        
        if (_audioOutput) {
            dispatch_group_enter(group);
            [_audioInput requestMediaDataWhenReadyOnQueue:audioQueue usingBlock:^{
                while (_audioInput.readyForMoreMediaData && !audio) {
                    CMSampleBufferRef sample = [_audioOutput copyNextSampleBuffer];
                    if (sample == NULL) {
                        audio = YES;
                        MyLog(@"音频结束");
                        dispatch_group_leave(group);
                        if (!video) {
                            [_audioInput markAsFinished];
                        }
                        break;
                    }
                    else{
                        BOOL status = [_audioInput appendSampleBuffer:sample];
                        if (!status) {
                            MyLog(@"失败");
                        }
                        if (sample) {
                            CFRelease(sample);
                        }
                        
                    }
                }
            }];
        }else{
            [_audioInput markAsFinished];
            audio = YES;
        }
        
        dispatch_group_notify(group, main, ^{
            [_writer finishWritingWithCompletionHandler:^{
                MyLog(@"结束");
                if (completion) {
                    completion(output);
                }
                if(_delegate){
                    [_delegate ExporterManager:self DidSuccessComplementWithOutputUrl:output];
                }
            }];
        });
    }
}

-(void)setupWriterWithOutputUrl:(NSURL*)url RenderSize:(CGSize)renderSize{
    _writer = [[AVAssetWriter alloc] initWithURL:url fileType:AVFileTypeQuickTimeMovie error:nil];
    int width = (int)renderSize.width;
    int height = (int)renderSize.height;
    NSDictionary* outputSetting = @{AVVideoCodecKey:AVVideoCodecH264,
                                    AVVideoWidthKey:[NSNumber numberWithInt:width],
                                    AVVideoHeightKey:[NSNumber numberWithInt:height]};
    _input = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:outputSetting];
    NSDictionary *pixelBufferAttributes = @{
                                            (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange],
                                            (id)kCVPixelBufferWidthKey : [NSNumber numberWithInt:width],
                                            (id)kCVPixelBufferHeightKey : [NSNumber numberWithInt:height],
                                            (id)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]
                                            };
    _adaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:_input sourcePixelBufferAttributes:pixelBufferAttributes];
    
    AudioChannelLayout stereoChannelLayout = {
        .mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
        .mChannelBitmap = 0,
        .mNumberChannelDescriptions = 0
    };
    NSData *channelLayoutAsData = [NSData dataWithBytes:&stereoChannelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];
    NSDictionary *compressionAudioSettings = @{
                                               AVFormatIDKey         : [NSNumber numberWithUnsignedInt:kAudioFormatMPEG4AAC],
                                               AVEncoderBitRateKey   : [NSNumber numberWithInteger:128000],
                                               AVSampleRateKey       : [NSNumber numberWithInteger:44100],
                                               AVChannelLayoutKey    : channelLayoutAsData,
                                               AVNumberOfChannelsKey : [NSNumber numberWithUnsignedInteger:2]
                                               };

    
    _audioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:compressionAudioSettings];
    
    if ([_writer canAddInput:_input]) {
        [_writer addInput:_input];
    }
    if ([_writer canAddInput:_audioInput]) {
        [_writer addInput:_audioInput];
    }
}
-(void)setupReaderWithAsset:(AVAsset*)asset{
    AVMutableVideoComposition* composition = [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:asset];
    
    NSArray* tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    
    _reader = [[AVAssetReader alloc] initWithAsset:asset error:nil];

    NSDictionary *decompressionVideoSettings = @{
                                                 (id)kCVPixelBufferPixelFormatTypeKey     : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
                                                 (id)kCVPixelBufferIOSurfacePropertiesKey : [NSDictionary dictionary]
                                                 };
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count]>0) {
        _readerOutput = [AVAssetReaderVideoCompositionOutput assetReaderVideoCompositionOutputWithVideoTracks:tracks videoSettings:decompressionVideoSettings];
    }
    [_readerOutput setVideoComposition:composition];
    
    NSDictionary *decompressionAudioSettings = @{ AVFormatIDKey : [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM] };
    
    if ([[asset tracksWithMediaType:AVMediaTypeAudio] count]>0) {
        _audioOutput = [[AVAssetReaderAudioMixOutput alloc] initWithAudioTracks:[asset tracksWithMediaType:AVMediaTypeAudio] audioSettings:decompressionAudioSettings];
    }
    
    if(_readerOutput && [_reader canAddOutput:_readerOutput])
        [_reader addOutput:_readerOutput];
    if (_audioOutput && [_reader canAddOutput:_audioOutput]) {
        [_reader addOutput:_audioOutput];
    }
    
}

-(void)videoApplyPIPAnimationWithURL:(NSURL*)url renderSize:(CGSize)renderSize duration:(float)duration outputFilePath:(NSString *)outputfilePath PIP:(NSMutableDictionary*)pip Completion:(CompletionBlock)completion{
    
    AVAsset *asset = [AVAsset assetWithURL:url];
    NSArray *videoTracks =[asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *assetTrack = ([videoTracks count]>0)?[videoTracks objectAtIndex:0]:nil;
    int i = 0;
    while (!assetTrack) {//防止偶尔的读取失败
        MyLog(@"单个videoasset为空");
        asset = [AVAsset assetWithURL:url];
        videoTracks =[asset tracksWithMediaType:AVMediaTypeVideo];
        assetTrack = ([videoTracks count]>0)?[videoTracks objectAtIndex:0]:nil;
        if (i >= 5) {//防止死循环
            if (_delegate) {
                [_delegate ExporterManager:self DidFailedComplementWithError:nil];
            }
            return;
        }
        i++;
    }
    
    //assettrack默认是横屏模式，所以这里宽>高
    CGSize naturalSize;
    if (renderSize.height > renderSize.width) {
        //如果是竖屏
        if (assetTrack.naturalSize.height < assetTrack.naturalSize.width) {
            naturalSize.width = assetTrack.naturalSize.height;
            naturalSize.height = assetTrack.naturalSize.width;
        }else{
            naturalSize.width = assetTrack.naturalSize.width;
            naturalSize.height = assetTrack.naturalSize.height;
        }
    }else{//横屏
        naturalSize.width = assetTrack.naturalSize.width;
        naturalSize.height = assetTrack.naturalSize.height;
    }
    MyLog(@"%@",[NSValue valueWithCGSize:assetTrack.naturalSize]);
    //处理视频本体
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
    AVMutableVideoCompositionLayerInstruction *layerInstruciton = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    float rateW = naturalSize.width/renderSize.width;
    float rateH = naturalSize.height/renderSize.height;
    
    CGAffineTransform transform = CGAffineTransformScale(assetTrack.preferredTransform, rateW, rateH);
    
    [layerInstruciton setTransform:transform atTime:kCMTimeZero];
    [layerInstruciton setOpacity:0.0 atTime:asset.duration];
    
    //get save path
    NSURL *outputURL = [NSURL fileURLWithPath:outputfilePath];
    [FileTool removeFile:outputURL];
    
    //export
    AVMutableVideoCompositionInstruction *mainInstruciton = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruciton.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    mainInstruciton.layerInstructions = @[layerInstruciton];
    
    AVMutableVideoComposition *videoCom = [AVMutableVideoComposition videoComposition];
    videoCom.instructions = @[mainInstruciton];
    videoCom.frameDuration = CMTimeMake(1, 25);
    videoCom.renderSize = CGSizeMake(renderSize.width, renderSize.height);
    //添加画中画
    AnimationAnalysisTool* tool = [[AnimationAnalysisTool alloc] init];
    tool.isPortrait = (renderSize.height > renderSize.width);
    [tool addVideoWithVideoComposition:videoCom Composition:mixComposition Dictionary:pip];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPreset960x540];
    exporter.videoComposition = videoCom;
    exporter.outputURL = outputURL;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    _exporterSession = exporter;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(onProgress:) userInfo:_exporterSession repeats:YES];
    });
    [_exporterSession exportAsynchronouslyWithCompletionHandler:^{
        if (_exporterSession.status == AVAssetExportSessionStatusFailed) {
            MyLog(@"pip错误");
        }else if (_exporterSession.status == AVAssetExportSessionStatusCompleted){
            if (completion) {
                completion(outputURL);
            }
        }

    }];
    
}


@end
