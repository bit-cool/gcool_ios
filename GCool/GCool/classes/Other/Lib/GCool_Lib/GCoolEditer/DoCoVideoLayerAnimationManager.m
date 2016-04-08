//
//  DoCoVideoLayerAnimationTool.m
//  doco_ios_app
//
//  Created by developer on 15/5/1.
//  Copyright (c) 2015年 developer. All rights reserved.
//

#import "DoCoVideoLayerAnimationManager.h"

@implementation DoCoVideoLayerAnimationManager


-(instancetype)init{
    self = [super init];
    if (self) {
        _assetArray = [[NSMutableArray alloc]init];
        _audioMixParas = [[NSMutableArray alloc]init];
        _layerInstructionArray = [[NSMutableArray alloc]init];
        _mixComposition = [[AVMutableComposition alloc]init];
        _totalDuration = kCMTimeZero;
        _totalDurs = [[NSMutableArray alloc]init];
    }
    return self;
}

-(void)cuttoAnimationCommonOperationWithAsset:(AVAsset *)asset aniDur:(CMTime)aniDur aniRange:(CMTimeRange)aniRange{
    
    NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    if (audioTracks.count==0) {
        MyLog(@"audioTracks为空了");
    }
    AVAssetTrack *audioTrack = ([audioTracks count]>0)?[audioTracks objectAtIndex:0]:nil;
    
    //    音频的效果设置  总时间还没有变化！！！
    //防止片头没有声音而出错  前音频效果
    if (_audioMixParas.count>0) {
        AVMutableAudioMixInputParameters *trackMix1 = _audioMixParas[0];
        [trackMix1 setVolumeRampFromStartVolume:1.0f toEndVolume:0.0f timeRange:aniRange];
        _audioMixParas[0] = trackMix1;
    }
    
    if (audioTrack) {
        //后音频时间配置和效果设置
        AVMutableCompositionTrack *audioComTrack = [_mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        [audioComTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                               ofTrack:audioTrack
                                atTime:CMTimeSubtract(_totalDuration, aniDur)
                                 error:nil];
        
        AVMutableAudioMixInputParameters *trackMix2 = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioComTrack];
        [trackMix2 setVolumeRampFromStartVolume:0.0f toEndVolume:1.0f timeRange:aniRange];
        [_audioMixParas insertObject:trackMix2 atIndex:0];
    }
    //
    //总时间计算  减去与前一段重叠的时间
    _totalDuration = CMTimeAdd(_totalDuration, asset.duration);
    _totalDuration = CMTimeSubtract(_totalDuration, aniDur);
    float total = _totalDuration.value*1.0 / _totalDuration.timescale*1000;
    
    [_totalDurs addObject:[NSNumber numberWithFloat:total]];
}

-(void)cuttoAnimationtranslationAsset:(AVAsset *)asset direction:(NSString *)dir duration:(float)duration {
    
    CMTime aniDur = CMTimeMake(duration*600/1000, 600);
    CMTimeRange aniRange = CMTimeRangeMake(CMTimeSubtract(_totalDuration, aniDur), aniDur);
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *videoTrack = videoTracks[0];
    if (videoTracks.count==0) {
        MyLog(@"videoTracks为空了");
    }
    
    AVMutableCompositionTrack *videoComTrack = [_mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [videoComTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                           ofTrack:videoTrack
                            atTime:CMTimeSubtract(_totalDuration, aniDur)
                             error:nil];
    
    //视频效果设置
    //前视频动画设置
    //这里使用的是当前视频的transform  有可能会有考虑不到的问题
    AVMutableVideoCompositionLayerInstruction *layerInstruction1 = _layerInstructionArray[0];
    CGAffineTransform animationTransform1;
    CGAffineTransform animationTransform2;
    if ([@"right" isEqualToString:dir]) {
        animationTransform1 = CGAffineTransformTranslate(videoTrack.preferredTransform, -_renderSize.width, 0 );
        animationTransform2 = CGAffineTransformTranslate(videoTrack.preferredTransform, _renderSize.width, 0 );
    }else if([@"left" isEqualToString:dir]){
        animationTransform1 = CGAffineTransformTranslate(videoTrack.preferredTransform, _renderSize.width, 0 );
        animationTransform2 = CGAffineTransformTranslate(videoTrack.preferredTransform, -_renderSize.width, 0 );
    }
    [layerInstruction1 setTransformRampFromStartTransform:asset.preferredTransform toEndTransform:animationTransform1  timeRange:aniRange];
    _layerInstructionArray[0] = layerInstruction1;
    
    //后视频动画设置
    AVMutableVideoCompositionLayerInstruction *layerInstruciton2 = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoComTrack];
    [layerInstruciton2 setTransformRampFromStartTransform:animationTransform2 toEndTransform:asset.preferredTransform timeRange:aniRange];
    
    [self cuttoAnimationCommonOperationWithAsset:asset aniDur:aniDur aniRange:aniRange];
    
    //这是为了防止ghost现象  应该在本段最后添加效果
    [layerInstruciton2 setOpacity:0.0 atTime:_totalDuration];
    [_layerInstructionArray insertObject:layerInstruciton2 atIndex:0];
    
}
//opacity
-(void)cuttoAnimationopacityAsset:(AVAsset *)asset duration:(NSNumber *)duration{
    //            CMTimeRange headRange = CMTimeRangeMake(CMTimeSubtract(totalDuration, asset.duration),CMTimeMake(300, 600));
    //
    //            [layerInstruciton setOpacityRampFromStartOpacity:0.0f toEndOpacity:1.0f timeRange:headRange];
    //
    //            CMTimeRange footerRange = CMTimeRangeMake(CMTimeSubtract(totalDuration, CMTimeMake(300, 600)), CMTimeMake(300, 600));
    //
    //            [layerInstruciton setOpacityRampFromStartOpacity:1.0f toEndOpacity:0.0f timeRange:footerRange];
    float dur = [duration floatValue];
    CMTime aniDur = CMTimeMake(dur*600/1000, 600);
    CMTimeRange aniRange = CMTimeRangeMake(CMTimeSubtract(_totalDuration, aniDur), aniDur);
    
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *videoTrack = videoTracks[0];
    if (videoTracks.count==0) {
        MyLog(@"videoTracks为空了");
    }
    
    AVMutableCompositionTrack *videoComTrack = [_mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [videoComTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                           ofTrack:videoTrack
                            atTime:CMTimeSubtract(_totalDuration, aniDur)
                             error:nil];
    
    //视频效果设置
    //前视频动画设置
    //这里使用的是当前视频的transform  有可能会有考虑不到的问题
    AVMutableVideoCompositionLayerInstruction *layerInstruction1 = _layerInstructionArray[0];
    
    [layerInstruction1 setOpacityRampFromStartOpacity:1.0f toEndOpacity:0.0f timeRange:aniRange];
    _layerInstructionArray[0] = layerInstruction1;
    
    //后视频动画设置
    AVMutableVideoCompositionLayerInstruction *layerInstruciton2 = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoComTrack];
    [layerInstruciton2 setOpacityRampFromStartOpacity:0.0f toEndOpacity:1.0f timeRange:aniRange];
    
    [self cuttoAnimationCommonOperationWithAsset:asset aniDur:aniDur aniRange:aniRange];
    
    //这是为了防止ghost现象  应该在本段最后添加效果
    [layerInstruciton2 setOpacity:0.0 atTime:_totalDuration];
    [_layerInstructionArray insertObject:layerInstruciton2 atIndex:0];
}

//转入转出
-(void)cuttoAnimationrotateoutAsset:(AVAsset *)asset duration:(NSNumber *)duration{
    float dur = [duration floatValue];
    CMTime aniDur = CMTimeMake(dur*600/1000, 600);
    CMTimeRange aniRange = CMTimeRangeMake(CMTimeSubtract(_totalDuration, aniDur), aniDur);
    
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *videoTrack = videoTracks[0];
    if (videoTracks.count==0) {
        MyLog(@"videoTracks为空了");
    }
    
    AVMutableCompositionTrack *videoComTrack = [_mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [videoComTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                           ofTrack:videoTrack
                            atTime:CMTimeSubtract(_totalDuration, aniDur)
                             error:nil];
    
    //视频效果设置
    //前视频动画设置
    //这里使用的是当前视频的transform  有可能会有考虑不到的问题
    AVMutableVideoCompositionLayerInstruction *layerInstruction1 = _layerInstructionArray[0];
    CGAffineTransform animationTransform1;
    animationTransform1 = CGAffineTransformMakeRotation(M_PI_2);
    
    [layerInstruction1 setTransformRampFromStartTransform:asset.preferredTransform toEndTransform:animationTransform1  timeRange:aniRange];
    _layerInstructionArray[0] = layerInstruction1;
    
    //后视频动画设置
    AVMutableVideoCompositionLayerInstruction *layerInstruciton2 = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoComTrack];
    [layerInstruciton2 setTransformRampFromStartTransform:animationTransform1 toEndTransform:asset.preferredTransform timeRange:aniRange];
    
    [self cuttoAnimationCommonOperationWithAsset:asset aniDur:aniDur aniRange:aniRange];
    
    //这是为了防止ghost现象  应该在本段最后添加效果
    [layerInstruciton2 setOpacity:0.0 atTime:_totalDuration];
    [_layerInstructionArray insertObject:layerInstruciton2 atIndex:0];
}

//缩放
-(void)cuttoAnimationscaleAsset:(AVAsset *)asset duration:(NSNumber *)duration{
    
    float dur = [duration floatValue];
    CMTime aniDur = CMTimeMake(dur*600/1000, 600);
    CMTimeRange aniRange = CMTimeRangeMake(CMTimeSubtract(_totalDuration, aniDur), aniDur);
    
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if (videoTracks.count==0) {
        MyLog(@"缩放videoTracks为空了");
    }
    AVAssetTrack *videoTrack = videoTracks[0];
    
    
    AVMutableCompositionTrack *videoComTrack = [_mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [videoComTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                           ofTrack:videoTrack
                            atTime:CMTimeSubtract(_totalDuration, aniDur)
                             error:nil];
    
    //视频效果设置
    //前视频动画设置
    //这里使用的是当前视频的transform  有可能会有考虑不到的问题
    AVMutableVideoCompositionLayerInstruction *layerInstruction1 = _layerInstructionArray[0];
    CGAffineTransform animationTransform1;
    animationTransform1 = CGAffineTransformMakeScale(0, 1);
    
    [layerInstruction1 setTransformRampFromStartTransform:asset.preferredTransform toEndTransform:animationTransform1  timeRange:aniRange];
    _layerInstructionArray[0] = layerInstruction1;
    
    //后视频动画设置
    AVMutableVideoCompositionLayerInstruction *layerInstruciton2 = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoComTrack];
    [layerInstruciton2 setTransformRampFromStartTransform:animationTransform1 toEndTransform:asset.preferredTransform timeRange:aniRange];
    
    [self cuttoAnimationCommonOperationWithAsset:asset aniDur:aniDur aniRange:aniRange];
    
    //这是为了防止ghost现象  应该在本段最后添加效果
    [layerInstruciton2 setOpacity:0.0 atTime:_totalDuration];
    [_layerInstructionArray insertObject:layerInstruciton2 atIndex:0];
}

//无视频动作转场
-(void)cuttoAnimationnoneAsset:(AVAsset *)asset duration:(NSNumber *)duration{
    float dur = [duration floatValue];
    CMTime aniDur = CMTimeMake(dur*600/1000, 600);
    CMTimeRange aniRange = CMTimeRangeMake(CMTimeSubtract(_totalDuration, aniDur), aniDur);
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if (videoTracks.count==0) {
        MyLog(@"无videoTracks为空了");
    }
    AVAssetTrack *videoTrack = videoTracks[0];
    
    AVMutableCompositionTrack *videoComTrack = [_mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [videoComTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                           ofTrack:videoTrack
                            atTime:CMTimeSubtract(_totalDuration, aniDur)
                             error:nil];
    
    //后视频动画设置
    AVMutableVideoCompositionLayerInstruction *layerInstruciton = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoComTrack];
    [self cuttoAnimationCommonOperationWithAsset:asset aniDur:aniDur aniRange:aniRange];
    
    //这是为了防止ghost现象  应该在本段最后添加效果
    [layerInstruciton setOpacity:0.0 atTime:_totalDuration];
    [_layerInstructionArray insertObject:layerInstruciton atIndex:0];
}


-(void)firstTrack{
    AVAsset *asset = [_assetArray objectAtIndex:0];
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0];
    
    AVMutableCompositionTrack *videoComTrack = [_mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [videoComTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                           ofTrack:videoTrack
                            atTime:_totalDuration
                             error:nil];
    
    AVMutableVideoCompositionLayerInstruction *layerInstruciton = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoComTrack];
    
    //总时间计算
    _totalDuration = CMTimeAdd(_totalDuration, asset.duration);
    float total = _totalDuration.value*1.0 / _totalDuration.timescale*1000;
    MyLog(@"总时间计算：%f",total);
    [_totalDurs addObject:[NSNumber numberWithFloat:total]];
    [layerInstruciton setOpacity:0.0 atTime:_totalDuration];
    //data
    [_layerInstructionArray insertObject:layerInstruciton atIndex:0];
}

#pragma mark-音乐
//这里的dura是指音乐的长度  以后可能不只是添加背景音乐
- (void) setUpAndAddAudioAtPath:(AVAssetTrack*)sourceAudioTrack start:(CMTime)start dura:(CMTime)dura Type:(NSString *)type{
    AVMutableCompositionTrack *track = [_mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSError *error = nil;
    
    CMTime startTime = start;
    CMTime trackDuration = dura;
//    CMTimeRange tRange = CMTimeRangeMake(kCMTimeZero, trackDuration);
    CMTime endTime = CMTimeAdd(start, dura);
    CMTime time = CMTimeMake(10, 1);
    CMTimeRange tRange = CMTimeRangeMake(kCMTimeZero, time);
    CMTime lastTime = CMTimeSubtract(endTime, time);
    
    //Insert audio into track  //offset CMTimeMake(0, 44100)
    while (CMTimeCompare(start, lastTime)<0) {
        [track insertTimeRange:tRange ofTrack:sourceAudioTrack atTime:start error:&error];
        start = CMTimeAdd(start, time);
    }
    tRange = CMTimeRangeMake(kCMTimeZero,CMTimeSubtract(endTime, start));
    [track insertTimeRange:tRange ofTrack:sourceAudioTrack atTime:start error:&error];
    //[track insertTimeRange:tRange ofTrack:sourceAudioTrack atTime:startTime error:&error];
    
    if (error) {
        MyLog(@"Musicerror:%@",error);
    }
    
    //Set Volume
    AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
    if ([@"bg" isEqualToString:type]) {
        CMTime startTime = kCMTimeZero;
        for (int i=0; i<_bgmVolumes.count; i++) {
            AVAsset* asset = _assetArray[i];
            [trackMix setVolumeRampFromStartVolume:[_bgmVolumes[i-1>=0?i-1:0] floatValue] toEndVolume:[_bgmVolumes[i] floatValue] timeRange:CMTimeRangeMake(startTime, CMTimeMake(25, 25))];
            
//            [trackMix setVolume:[_bgmVolumes[i] floatValue] atTime:startTime];
            startTime = CMTimeAdd(startTime,asset.duration);
        }
        [trackMix setVolumeRampFromStartVolume:[_bgmVolumes[_assetArray.count - 1] floatValue] toEndVolume:0.f timeRange:CMTimeRangeMake(CMTimeSubtract(trackDuration, CMTimeMake(2, 1)), CMTimeMake(2, 1))];
    }else if ([@"cutto" isEqualToString:type]){
        [trackMix setVolume:1.0f atTime:startTime];
    }
    
    [_audioMixParas insertObject:trackMix atIndex:0];
    
}

@end
