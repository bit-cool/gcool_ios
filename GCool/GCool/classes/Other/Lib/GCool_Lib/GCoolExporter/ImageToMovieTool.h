//
//  ImageToMovieTool.h
//  doco_ios_app
//
//  Created by developer on 15/4/27.
//  Copyright (c) 2015年 developer. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface ImageToMovieTool : NSObject

@property(nonatomic,strong)AVAssetWriter *assetWriter;
@property(nonatomic,strong)AVAssetWriterInput *assetWriterAudioInput;
@property(nonatomic,strong)AVAssetWriterInput *assetWriterVideoInput;

- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image andSize:(CGSize) size;

- (void) writeImages:(NSArray *)imagesArray ToMovieAtPath:(NSString *) path withSize:(CGSize) size inDuration:(float)duration byFPS:(int32_t)fps;
@end
