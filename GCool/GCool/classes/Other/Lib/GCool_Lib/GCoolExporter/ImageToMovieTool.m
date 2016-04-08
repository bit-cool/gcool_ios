//
//  ImageToMovieTool.m
//  doco_ios_app
//
//  Created by developer on 15/4/27.
//  Copyright (c) 2015年 developer. All rights reserved.
//

#import "ImageToMovieTool.h"

@implementation ImageToMovieTool
- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image andSize:(CGSize) size
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width,size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef)(options),
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,size.height, 8, 4*size.width, rgbColorSpace,
        kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}
//至少两张
- (void) writeImages:(NSArray *)imagesArray ToMovieAtPath:(NSString *) path withSize:(CGSize) size inDuration:(float)duration byFPS:(int32_t)fps{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //Wire the writer:
        NSError *error = nil;
        AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
            fileType:AVFileTypeMPEG4
            error:&error];
        NSParameterAssert(videoWriter);
        
        NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
            AVVideoCodecH264, AVVideoCodecKey,
            [NSNumber numberWithInt:size.width], AVVideoWidthKey,
            [NSNumber numberWithInt:size.height], AVVideoHeightKey,nil];
        AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput
            assetWriterInputWithMediaType:AVMediaTypeVideo
                                                 outputSettings:videoSettings];
        
        
        AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
             assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
            sourcePixelBufferAttributes:nil];
        NSParameterAssert(videoWriterInput);
        NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
        [videoWriter addInput:videoWriterInput];
        
        //Start a session:
        [videoWriter startWriting];
        [videoWriter startSessionAtSourceTime:kCMTimeZero];
        
        //Write some samples:
        CVPixelBufferRef buffer = NULL;
        
        int frameCount = 0;
        
        long imagesCount = [imagesArray count];
        float averageTime = duration/imagesCount;
        int averageFrame = (int)(averageTime * fps);
        
        for(UIImage * img in imagesArray)
        {
            buffer = [self pixelBufferFromCGImage:[img CGImage] andSize:size];
            
            BOOL append_ok = NO;
            int j = 0;
            while (!append_ok && j < 60)
            {
                if (adaptor.assetWriterInput.readyForMoreMediaData)
                {
                    printf("appending %d attemp %d\n", frameCount, j);
                    
                    CMTime frameTime = CMTimeMake(frameCount,(int32_t) fps);
                    float frameSeconds = CMTimeGetSeconds(frameTime);
                    MyLog(@"frameCount:%d,kRecordingFPS:%d,frameSeconds:%f",frameCount,fps,frameSeconds);
                    append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];

                }
                else
                {
                    printf("adaptor not ready %d, %d\n", frameCount, j);
                    [NSThread sleepForTimeInterval:0.1];
                }
                j++;
            }
            if (!append_ok) {
                printf("error appending image %d times %d\n", frameCount, j);
            }
            
            frameCount = frameCount + averageFrame;
        }
        
        //Finish the session:
        [videoWriterInput markAsFinished];
        [videoWriter finishWriting];
    });
    MyLog(@"finishWriting");
}
@end
