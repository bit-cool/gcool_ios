//
//  DoCoExporterWriter.m
//  doco_ios_app
//
//  Created by developer on 15/4/19.
//  Copyright (c) 2015年 developer. All rights reserved.
//

#import "DoCoExporterWriter.h"
#import <AVFoundation/AVAssetReaderOutput.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/ES2/gl.h>


@implementation DoCoExporterWriter

-(instancetype)initWithSourceURL:(NSURL *)sourceURL outputURL:(NSURL *)outputURL{
    self = [super init];
    if(self){
        [self initialQueue];
        //[self initialAssetWithSourceFileURL:sourceURL outputURL:outputURL];
    }
    return self;
}

-(instancetype)initWithSource:(AVMutableComposition *)mixComposition videoComposition:(AVVideoComposition *)videoComposition audioMix:(AVMutableAudioMix *)audioMix outputURL:(NSURL *)outputURL Script:(NSString *)scriptName{
    self = [super init];
    if(self){
        [self initialQueue];
        [self initialAssetWithSource:mixComposition videoComposition:videoComposition audioMix:audioMix outputURL:outputURL Script:(NSString *)scriptName];
    }
    return self;
}

-(void)initialQueue{
    NSString *serializationQueueDescription = [NSString stringWithFormat:@"%@ serialization queue", self];
    
    // Create the main serialization queue.
    self.mainSerializationQueue = dispatch_queue_create([serializationQueueDescription UTF8String], NULL);
    NSString *rwAudioSerializationQueueDescription = [NSString stringWithFormat:@"%@ rw audio serialization queue", self];
    
    // Create the serialization queue to use for reading and writing the audio data.
    self.rwAudioSerializationQueue = dispatch_queue_create([rwAudioSerializationQueueDescription UTF8String], NULL);
    NSString *rwVideoSerializationQueueDescription = [NSString stringWithFormat:@"%@ rw video serialization queue", self];
    
    // Create the serialization queue to use for reading and writing the video data.
    self.rwVideoSerializationQueue = dispatch_queue_create([rwVideoSerializationQueueDescription UTF8String], NULL);
}

//-(void)initialAssetWithSourceFileURL:(NSURL *)sourceURL outputURL:(NSURL *)outputURL{
//    self.asset = [AVAsset assetWithURL:sourceURL];
//    self.cancelled = NO;
//    self.outputURL = outputURL;
//    // Asynchronously load the tracks of the asset you want to read.
//    [self.asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
//        // Once the tracks have finished loading, dispatch the work to the main serialization queue.
//        dispatch_async(self.mainSerializationQueue, ^{
//            // Due to asynchronous nature, check to see if user has already cancelled.
//            if (self.cancelled)
//                return;
//            BOOL success = YES;
//            NSError *localError = nil;
//            // Check for success of loading the assets tracks.
//            success = ([self.asset statusOfValueForKey:@"tracks" error:&localError] == AVKeyValueStatusLoaded);
//            if (success)
//            {
//                // If the tracks loaded successfully, make sure that no file exists at the output path for the asset writer.
//                NSFileManager *fm = [NSFileManager defaultManager];
//                NSString *localOutputPath = [self.outputURL path];
//                if ([fm fileExistsAtPath:localOutputPath])
//                    success = [fm removeItemAtPath:localOutputPath error:&localError];
//            }
//            if (success)
//                success = [self setupAssetReaderAndAssetWriter:&localError];
//            if (success)
//                success = [self startAssetReaderAndWriter:&localError];
//            if (!success)
//                [self readingAndWritingDidFinishSuccessfully:success withError:localError];
//        });
//    }];
//}

-(void)initialAssetWithSource:(AVMutableComposition *)mixComposition videoComposition:(AVVideoComposition *)videoComposition audioMix:(AVMutableAudioMix *)audioMix outputURL:(NSURL *)outputURL Script:(NSString *)scriptName{
    self.mixCom = mixComposition;
    self.videoCom = videoComposition;
    if (audioMix) {
        self.audioMix = audioMix;
    }
    
    self.cancelled = NO;
    self.outputURL = outputURL;
    self.scriptName = scriptName;
    // Asynchronously load the tracks of the asset you want to read.
        // Once the tracks have finished loading, dispatch the work to the main serialization queue.
    dispatch_async(self.mainSerializationQueue, ^{
        // Due to asynchronous nature, check to see if user has already cancelled.
        if (self.cancelled)
            return;
        BOOL success = YES;
        NSError *localError = nil;
        // Check for success of loading the assets tracks.
        success = ([self.asset statusOfValueForKey:@"tracks" error:&localError] == AVKeyValueStatusLoaded);
        success = YES;
        if (success)
        {
            // If the tracks loaded successfully, make sure that no file exists at the output path for the asset writer.
            NSFileManager *fm = [NSFileManager defaultManager];
            NSString *localOutputPath = [self.outputURL path];
            if ([fm fileExistsAtPath:localOutputPath])
                success = [fm removeItemAtPath:localOutputPath error:&localError];
        }
        if (success)
            success = [self setupAssetReaderAndAssetWriter:&localError];
        if (success)
            success = [self startAssetReaderAndWriter:&localError];
        if (!success)
            [self readingAndWritingDidFinishSuccessfully:success withError:localError];
    });

}

- (BOOL)setupAssetReaderAndAssetWriter:(NSError **)outError
{
    MyLog(@"setupAssetReadingandWriter");
    // Create and initialize the asset reader.
    
    self.asset = (AVAsset *)_mixCom;
    
    self.assetReader = [[AVAssetReader alloc]initWithAsset:self.asset error:outError];
    
    BOOL success = (self.assetReader != nil);
    if (success)
    {
        // If the asset reader was successfully initialized, do the same for the asset writer.
        self.assetWriter = [[AVAssetWriter alloc] initWithURL:self.outputURL fileType:AVFileTypeMPEG4 error:outError];
        success = (self.assetWriter != nil);
    }
    
    if (success)
    {
        // If the reader and writer were successfully initialized, grab the audio and video asset tracks that will be used.
        AVAssetTrack *assetAudioTrack = nil, *assetVideoTrack = nil;
        NSArray *audioTracks = [_mixCom tracksWithMediaType:AVMediaTypeAudio];
        if ([audioTracks count] > 0)
            assetAudioTrack = [audioTracks objectAtIndex:0];
        NSArray *videoTracks = [_mixCom tracksWithMediaType:AVMediaTypeVideo];
        if ([videoTracks count] > 0)
            assetVideoTrack = [videoTracks objectAtIndex:0];
        
        if (audioTracks)
        {
            // If there is an audio track to read, set the decompression settings to Linear PCM and create the asset reader output.
            NSDictionary *decompressionAudioSettings = @{ AVFormatIDKey : [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM] };
            self.audioOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:audioTracks audioSettings:decompressionAudioSettings ];
            if (_audioMix) {
                self.audioOutput.audioMix = _audioMix;
            }
            
            [self.assetReader addOutput:self.audioOutput];
            // Then, set the compression settings to 128kbps AAC and create the asset writer input.
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
            self.assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:compressionAudioSettings];
            [self.assetWriter addInput:self.assetWriterAudioInput];
        }
        
        if (videoTracks)
        {
            // If there is a video track to read, set the decompression settings for YUV and create the asset reader output.
            NSDictionary *decompressionVideoSettings = @{
                (id)kCVPixelBufferPixelFormatTypeKey     : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
                (id)kCVPixelBufferIOSurfacePropertiesKey : [NSDictionary dictionary]
            };
            self.videoOutput = [AVAssetReaderVideoCompositionOutput assetReaderVideoCompositionOutputWithVideoTracks:videoTracks videoSettings:decompressionVideoSettings ];

            self.videoOutput.videoComposition = _videoCom;
            [self.assetReader addOutput:self.videoOutput];
            CMFormatDescriptionRef formatDescription = NULL;
            // Grab the video format descriptions from the video track and grab the first one if it exists.
            NSArray *videoFormatDescriptions = [assetVideoTrack formatDescriptions];
            if ([videoFormatDescriptions count] > 0)
                formatDescription = (__bridge CMFormatDescriptionRef)[videoFormatDescriptions objectAtIndex:0];
            CGSize trackDimensions = {
                .width = 0.0,
                .height = 0.0,
            };
            // If the video track had a format description, grab the track dimensions from there. Otherwise, grab them direcly from the track itself.
            if (formatDescription)
                trackDimensions = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, false, false);
            else
                trackDimensions = [assetVideoTrack naturalSize];
            NSDictionary *compressionSettings = nil;
            // If the video track had a format description, attempt to grab the clean aperture settings and pixel aspect ratio used by the video.
            if (formatDescription)
            {
                NSDictionary *cleanAperture = nil;
                NSDictionary *pixelAspectRatio = nil;
                CFDictionaryRef cleanApertureFromCMFormatDescription = CMFormatDescriptionGetExtension(formatDescription, kCMFormatDescriptionExtension_CleanAperture);
                if (cleanApertureFromCMFormatDescription)
                {
                    MyLog(@"cleanAperture");
                    cleanAperture = @{
                                      
                    AVVideoCleanApertureWidthKey            :(id)CFDictionaryGetValue(cleanApertureFromCMFormatDescription,kCMFormatDescriptionKey_CleanApertureWidth),
                    AVVideoCleanApertureHeightKey           : (id)CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureHeight),
                    AVVideoCleanApertureHorizontalOffsetKey : (id)CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureHorizontalOffset),
                    AVVideoCleanApertureVerticalOffsetKey   : (id)CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureVerticalOffset),
                    AVVideoAverageBitRateKey   : [NSNumber numberWithInteger:706000],
                    
                    };
                }
                CFDictionaryRef pixelAspectRatioFromCMFormatDescription = CMFormatDescriptionGetExtension(formatDescription, kCMFormatDescriptionExtension_PixelAspectRatio);
                if (pixelAspectRatioFromCMFormatDescription)
                {
                    MyLog(@"pixelAspect");
                    pixelAspectRatio = @{
                                         
                    AVVideoPixelAspectRatioHorizontalSpacingKey : (id)CFDictionaryGetValue(pixelAspectRatioFromCMFormatDescription, kCMFormatDescriptionKey_PixelAspectRatioHorizontalSpacing),
                    AVVideoPixelAspectRatioVerticalSpacingKey   : (id)CFDictionaryGetValue(pixelAspectRatioFromCMFormatDescription, kCMFormatDescriptionKey_PixelAspectRatioVerticalSpacing)
                    };
                }
                // Add whichever settings we could grab from the format description to the compression settings dictionary.
                if (cleanAperture || pixelAspectRatio)
                {
                    NSMutableDictionary *mutableCompressionSettings = [NSMutableDictionary dictionary];
                    if (cleanAperture)
                        MyLog(@"hahahah");
                        [mutableCompressionSettings setObject:cleanAperture forKey:AVVideoCleanApertureKey];
                    if (pixelAspectRatio)
                        MyLog(@"xixixi");
                        [mutableCompressionSettings setObject:pixelAspectRatio forKey:AVVideoPixelAspectRatioKey];
                    compressionSettings = mutableCompressionSettings;
                }
            }
            //修改比特率
            NSDictionary *compressionSetting = @{
                AVVideoAverageBitRateKey:[NSNumber numberWithDouble:706000],
            };
            // Create the video settings dictionary for H.264.
            NSMutableDictionary *videoSettings = (NSMutableDictionary *) @{
                                                                           
                    AVVideoCodecKey  : AVVideoCodecH264,
                    AVVideoWidthKey  : [NSNumber numberWithDouble:trackDimensions.width],
                    AVVideoHeightKey : [NSNumber numberWithDouble:trackDimensions.height],
                    AVVideoCompressionPropertiesKey:compressionSetting
            };
            // Put the compression settings into the video settings dictionary if we were able to grab them.

            // Create the asset writer input and add it to the asset writer.
            self.assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
            
            //初始化adapter
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription);
            
            NSDictionary *pixelBufferAttributes = @{
                    (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_422YpCbCr8],
                    (id)kCVPixelBufferWidthKey : [NSNumber numberWithInt:dimensions.width],
                    (id)kCVPixelBufferHeightKey : [NSNumber numberWithInt:dimensions.height]
                    
            };
            
            _videoPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_assetWriterVideoInput sourcePixelBufferAttributes:pixelBufferAttributes];
            [self.assetWriter addInput:self.assetWriterVideoInput];
        }
        NSDictionary *options = @{ kCIContextWorkingColorSpace : [NSNull null], kCIContextOutputColorSpace : [NSNull null] };
        
        _context = [CIContext contextWithEAGLContext:[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2] options:options];
    }
    return success;
}

- (BOOL)startAssetReaderAndWriter:(NSError **)outError
{
    MyLog(@"startAssetReadingAndWriter");
    BOOL success = YES;
    // Attempt to start the asset reader.
    if ([self.assetReader status] == AVAssetReaderStatusReading || [self.assetReader status] == AVAssetReaderStatusCompleted) {
        MyLog(@"already....");
        success = YES;
    }else{
        MyLog(@"startReading....");
        success = [self.assetReader startReading];
    }
    if (!success)
        *outError = [self.assetReader error];
    if (success)
    {
        // If the reader started successfully, attempt to start the asset writer.
        success = [self.assetWriter startWriting];
        if (!success)
            *outError = [self.assetWriter error];
    }
    
    if (success)
    {
        // If the asset reader and writer both started successfully, create the dispatch group where the reencoding will take place and start a sample-writing session.
        self.dispatchGroup = dispatch_group_create();
        [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
        self.audioFinished = NO;
        self.videoFinished = NO;
        
        if (self.assetWriterAudioInput)
        {
            // If there is audio to reencode, enter the dispatch group before beginning the work.
            dispatch_group_enter(self.dispatchGroup);
            // Specify the block to execute when the asset writer is ready for audio media data, and specify the queue to call it on.
            [self.assetWriterAudioInput requestMediaDataWhenReadyOnQueue:self.rwAudioSerializationQueue usingBlock:^{
                // Because the block is called asynchronously, check to see whether its task is complete.
                if (self.audioFinished)
                    return;
                
                BOOL completedOrFailed = NO;
                // If the task isn't complete yet, make sure that the input is actually ready for more media data.
                while ([self.assetWriterAudioInput isReadyForMoreMediaData] && !completedOrFailed)
                {
                    // Get the next audio sample buffer, and append it to the output file.
                    CMSampleBufferRef sampleBuffer = [self.audioOutput copyNextSampleBuffer];
                    if (sampleBuffer != NULL)
                    {
                        BOOL success = [self.assetWriterAudioInput appendSampleBuffer:sampleBuffer];
                        CFRelease(sampleBuffer);
                        sampleBuffer = NULL;
                        completedOrFailed = !success;
                    }
                    else
                    {
                        completedOrFailed = YES;
                    }
                }
                if (completedOrFailed)
                {
                    // Mark the input as finished, but only if we haven't already done so, and then leave the dispatch group (since the audio work has finished).
                    BOOL oldFinished = self.audioFinished;
                    self.audioFinished = YES;
                    if (oldFinished == NO)
                    {
                        [self.assetWriterAudioInput markAsFinished];
                    }
                    dispatch_group_leave(self.dispatchGroup);
                }
            }];
        }
      //========================================================
        if (self.assetWriterVideoInput)
        {
            // If we had video to reencode, enter the dispatch group before beginning the work.
            dispatch_group_enter(self.dispatchGroup);
            // Specify the block to execute when the asset writer is ready for video media data, and specify the queue to call it on.
            [self.assetWriterVideoInput requestMediaDataWhenReadyOnQueue:self.rwVideoSerializationQueue usingBlock:^{
                // Because the block is called asynchronously, check to see whether its task is complete.
                if (self.videoFinished)
                    return;
                
                BOOL completedOrFailed = NO;
                // If the task isn't complete yet, make sure that the input is actually ready for more media data.
                //int i=0;
                float progress = 0.05;
                while ([self.assetWriterVideoInput isReadyForMoreMediaData] && !completedOrFailed)
                {
                   
                    
                    if ([_delegate respondsToSelector:@selector(readingAndWritingDidBeginWithProgress:)]) {
                        [_delegate readingAndWritingDidBeginWithProgress:progress];
                    }
                    // Get the next video sample buffer, and append it to the output file.
                    CMSampleBufferRef sampleBuffer = [self.videoOutput copyNextSampleBuffer];
                    
    //读取图片=================================================
//                    NSMutableString *fileName;
//                    if ([_scriptName isEqualToString:@"GQT"]) {
//                       fileName =[[NSMutableString alloc]initWithFormat:@"30S_%@_%d",_scriptName,i+10000];
//                    }else{
//                        fileName=[[NSMutableString alloc]initWithFormat:@"30s_%@_%d",_scriptName,i+10000];
//                    }
//                    
//                    [fileName replaceCharactersInRange:NSMakeRange(8, 1) withString:@"0"];
//                    NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"png"];
//                    UIImage *coverImage = [UIImage imageWithContentsOfFile:filePath];
//                    
//                    i++;
                    
                    if (sampleBuffer != NULL)
                    {
                        //MyLog(@"sampleBuffer并不是空");
                        BOOL success = [self coverImage:nil ForSampleBuffer:sampleBuffer];
                        CFRelease(sampleBuffer);
                        sampleBuffer = NULL;
                        completedOrFailed = !success;
                    }
                    else
                    {
                        completedOrFailed = YES;
                    }
                }
                if (completedOrFailed)
                {
                    // Mark the input as finished, but only if we haven't already done so, and then leave the dispatch group (since the video work has finished).
                    BOOL oldFinished = self.videoFinished;
                    self.videoFinished = YES;
                    if (oldFinished == NO)
                    {
                        [self.assetWriterVideoInput markAsFinished];
                    }
                    dispatch_group_leave(self.dispatchGroup);
                }
            }];
        }
        // Set up the notification that the dispatch group will send when the audio and video work have both finished.
        dispatch_group_notify(self.dispatchGroup, self.mainSerializationQueue, ^{
            MyLog(@"group_notify通知");
            BOOL finalSuccess = YES;
            NSError *finalError = nil;
            // Check to see if the work has finished due to cancellation.
            if (self.cancelled)
            {
                // If so, cancel the reader and writer.
                [self.assetReader cancelReading];
                [self.assetWriter cancelWriting];
            }
            else
            {
                // If cancellation didn't occur, first make sure that the asset reader didn't fail.
                if ([self.assetReader status] == AVAssetReaderStatusFailed)
                {
                    finalSuccess = NO;
                    finalError = [self.assetReader error];
                    MyLog(@"self.assetReader error:%@",finalError);
                }
                // If the asset reader didn't fail, attempt to stop the asset writer and check for any errors.
                if (finalSuccess)
                {
                    finalSuccess = [self.assetWriter finishWriting];
                    if (!finalSuccess){
                        finalError = [self.assetWriter error];
                        MyLog(@"self.assetWriter error:%@",finalError);
                    }
                }
            }
            // Call the method to handle completion, and pass in the appropriate parameters to indicate whether reencoding was successful.
            [self readingAndWritingDidFinishSuccessfully:finalSuccess withError:finalError];
        });
    }
    // Return success here to indicate whether the asset reader and writer were started successfully.
    return success;
}

-(BOOL)coverImage:(UIImage *)coverImage ForSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVPixelBufferRef sampleBufferImage = CMSampleBufferGetImageBuffer(sampleBuffer);
//    size_t bufferWidth = (CGFloat)CVPixelBufferGetWidth(sampleBufferImage);
//    size_t bufferHeight = (CGFloat)CVPixelBufferGetHeight(sampleBufferImage);
    
    CMTime time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
//    CVPixelBufferLockBaseAddress( sampleBufferImage, 0 );
//    
//    CGContextRef context = CGBitmapContextCreate(CVPixelBufferGetBaseAddress(sampleBufferImage),
//        bufferWidth,
//        bufferHeight,
//        8,
//        CVPixelBufferGetBytesPerRow(sampleBufferImage),
//        CGColorSpaceCreateDeviceRGB(),
//        (CGBitmapInfo)kCGBitmapByteOrder32Little |
//        kCGImageAlphaPremultipliedFirst);
//    
//    CGRect renderBounds = CGRectMake(0, 0, bufferWidth, bufferHeight);
//    CGContextDrawImage(context, renderBounds, [coverImage CGImage]);
    
//    CVPixelBufferUnlockBaseAddress(sampleBufferImage, 0);
    
    
//      成功   但是效率过低
//    CIImage *bufferImage = [CIImage imageWithCVPixelBuffer:sampleBufferImage];
//    UIImage *bufferUIImage = [UIImage imageWithCIImage:bufferImage];
//    
//    CGSize size=CGSizeMake(bufferWidth, bufferHeight);//画布大小
//    UIGraphicsBeginImageContext(size);
//    
//    [bufferUIImage drawInRect:CGRectMake(0, 0, bufferWidth, bufferHeight)];//注意绘图的位置是相对于画布顶点而言，不是屏幕
//    [coverImage drawInRect:CGRectMake(0, 0, bufferWidth, bufferHeight)];
//    
//    //返回绘制的新图形
//    UIImage *newImage=UIGraphicsGetImageFromCurrentImageContext();
//    
//    //最后一定不要忘记关闭对应的上下文
//    UIGraphicsEndImageContext();
//    
//    
//    
//    CIImage *image1 = [CIImage imageWithCGImage:newImage.CGImage];
//    [_context render:image1 toCVPixelBuffer:sampleBufferImage];
    
    [_videoPixelBufferAdaptor appendPixelBuffer:sampleBufferImage withPresentationTime:time];
    
    return YES;
}
- (void)readingAndWritingDidFinishSuccessfully:(BOOL)success withError:(NSError *)error
{
    if (!success)
    {
        // If the reencoding process failed, we need to cancel the asset reader and writer.
        MyLog(@"失败了");
        MyLog(@"%@",error);
        [self.assetReader cancelReading];
        [self.assetWriter cancelWriting];
        dispatch_async(dispatch_get_main_queue(), ^{
            // Handle any UI tasks here related to failure.
        });
    }
    else
    {
        // Reencoding was successful, reset booleans.
        self.cancelled = NO;
        self.videoFinished = NO;
        self.audioFinished = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            // Handle any UI tasks here related to success.
            MyLog(@"lailailai------");
            if([_delegate respondsToSelector:@selector(readingAndWritingDidFinishSuccessfullyWithOutputURL:)]){
                MyLog(@"--------------------");
                [_delegate readingAndWritingDidFinishSuccessfullyWithOutputURL:_outputURL];
            }
            
        });
    }
}

- (void)cancel
{
    // Handle cancellation asynchronously, but serialize it with the main queue.
    dispatch_async(self.mainSerializationQueue, ^{
        // If we had audio data to reencode, we need to cancel the audio work.
        if (self.assetWriterAudioInput)
        {
            // Handle cancellation asynchronously again, but this time serialize it with the audio queue.
            dispatch_async(self.rwAudioSerializationQueue, ^{
                // Update the Boolean property indicating the task is complete and mark the input as finished if it hasn't already been marked as such.
                BOOL oldFinished = self.audioFinished;
                self.audioFinished = YES;
                if (oldFinished == NO)
                {
                    [self.assetWriterAudioInput markAsFinished];
                }
                // Leave the dispatch group since the audio work is finished now.
                dispatch_group_leave(self.dispatchGroup);
            });
        }
        
        if (self.assetWriterVideoInput)
        {
            // Handle cancellation asynchronously again, but this time serialize it with the video queue.
            dispatch_async(self.rwVideoSerializationQueue, ^{
                // Update the Boolean property indicating the task is complete and mark the input as finished if it hasn't already been marked as such.
                BOOL oldFinished = self.videoFinished;
                self.videoFinished = YES;
                if (oldFinished == NO)
                {
                    [self.assetWriterVideoInput markAsFinished];
                }
                // Leave the dispatch group, since the video work is finished now.
                dispatch_group_leave(self.dispatchGroup);
            });
        }
        // Set the cancelled Boolean property to YES to cancel any work on the main queue as well.
        self.cancelled = YES;
    });
}


// Note the caller is responsible for calling glDeleteTextures on the return value.
- (GLuint)textureFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    GLuint texture = 0;
    
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(pixelBuffer));
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return texture;
}

// This function exists to free the malloced data when the CGDataProviderRef is
// eventually freed.
void dataProviderFreeData(void *info, const void *data, size_t size){
    free((void *)data);
}

// Returns an autoreleased CGImageRef.
- (CGImageRef)processTexture:(GLuint)texture width:(int)width height:(int)height {
    CGImageRef newImage = NULL;
    
    // Set up framebuffer and renderbuffer.
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    
    GLuint colorRenderbuffer;
    glGenRenderbuffers(1, &colorRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, width, height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        MyLog(@"Failed to create OpenGL frame buffer: %x", status);
    } else {
        glViewport(0, 0, width, height);
        glClearColor(0.0,0.0,0.0,1.0);
        glClear(GL_COLOR_BUFFER_BIT);
        
        // Do whatever is necessary to actually draw the texture to the framebuffer
        //[self renderTextureToCurrentFrameBuffer:texture];
        
        // Read the pixels out of the framebuffer
        void *data = malloc(width * height * 4);
        glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
        
        // Convert the data to a CGImageRef. Note that CGDataProviderRef takes
        // ownership of our malloced data buffer, and the CGImageRef internally
        // retains the CGDataProviderRef. Hence the callback above, to free the data
        // buffer when the provider is finally released.
        CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, data, width * height * 4, dataProviderFreeData);
        CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
        newImage = CGImageCreate(width, height, 8, 32, width*4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast, dataProvider, NULL, true, kCGRenderingIntentDefault);
        CFRelease(dataProvider);
        CGColorSpaceRelease(colorspace);
        
    }
    
    // Clean up the framebuffer and renderbuffer.
    glDeleteRenderbuffers(1, &colorRenderbuffer);
    glDeleteFramebuffers(1, &framebuffer);
    
    return newImage;
}
@end

