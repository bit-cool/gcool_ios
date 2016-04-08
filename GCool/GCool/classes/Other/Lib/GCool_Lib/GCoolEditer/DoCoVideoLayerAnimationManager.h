//
//  DoCoVideoLayerAnimationTool.h
//  doco_ios_app
//
//  Created by developer on 15/5/1.
//  Copyright (c) 2015年 developer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface DoCoVideoLayerAnimationManager : NSObject

@property(nonatomic,strong)NSMutableArray *assetArray;
@property(nonatomic,strong)NSMutableArray *layerInstructionArray;
@property(nonatomic,strong)NSMutableArray *audioMixParas;
@property(nonatomic,strong)AVMutableComposition *mixComposition;
@property(nonatomic,assign)CMTime totalDuration;
@property(nonatomic,assign)CGSize renderSize;

@property(nonatomic,strong)NSMutableArray *totalDurs;

//判断是否有背景音乐
@property(nonatomic,strong) NSArray* bgmVolumes;


//平移转场
-(void)cuttoAnimationtranslationAsset:(AVAsset *)asset direction:(NSString *)dir duration:(float)duration;
//淡入淡出
-(void)cuttoAnimationopacityAsset:(AVAsset *)asset duration:(NSNumber *)duration;
//转入转出
-(void)cuttoAnimationrotateoutAsset:(AVAsset *)asset duration:(NSNumber *)duration;
//缩放
-(void)cuttoAnimationscaleAsset:(AVAsset *)asset duration:(NSNumber *)duration;
//无视频动作转场
-(void)cuttoAnimationnoneAsset:(AVAsset *)asset duration:(NSNumber *)duration;
//第一个track
-(void)firstTrack;
//音乐
- (void) setUpAndAddAudioAtPath:(AVAssetTrack*)sourceAudioTrack start:(CMTime)start dura:(CMTime)dura Type:(NSString *)type;
@end
