//
//  DoCoExporterManager.h
//  doco_ios_app
//
//  Created by developer on 15/5/1.
//  Copyright (c) 2015年 developer. All rights reserved.
//
#import "DoCoVideoLayerAnimationManager.h"
#import "DoCoFilterTool.h"

typedef void (^AnimationBlock)(AVMutableVideoComposition *_Nonnull videoCom,CGSize size);
typedef void (^CuttoBlock)(DoCoVideoLayerAnimationManager *_Nonnull manager);
typedef void (^OverallAnimationBlock)(AVMutableVideoComposition *_Nonnull videoCom,CGSize size,DoCoVideoLayerAnimationManager *_Nonnull manager);
typedef void (^CompletionBlock)(NSURL *_Nonnull outputURL);
typedef void (^ProgressBlock)(float progress);
typedef void (^BeginBlock)(AVMutableComposition *_Nullable mixComposition,AVVideoComposition *_Nonnull videoComposition, AVMutableAudioMix *_Nonnull audioMix,NSURL *_Nonnull outputURL);
@class DoCoExporterManager;
@protocol DoCoExporterManagerDelegate <NSObject>

-(void)ExporterManager:(DoCoExporterManager *_Nullable)manager processingWithProgress:(float)progress;

-(void)ExporterManager:(DoCoExporterManager *_Nullable)manager DidSuccessComplementWithOutputUrl:(NSURL *_Nullable)outputUrl;

-(void)ExporterManager:(DoCoExporterManager *_Nullable)manager DidFailedComplementWithError:(NSError *_Nullable)error;

@end

@interface DoCoExporterManager : NSObject

@property(nonatomic,weak)_Nullable id<DoCoExporterManagerDelegate> delegate;
@property(nonatomic,assign)int tag;
@property(nonatomic,strong)AVAssetExportSession *_Nullable exporterSession;
@property(nonatomic,strong)NSTimer *_Nullable timer;
@property(nonatomic)BOOL isOriginalSoundOpen;
@property (nonatomic,strong) DoCoFilterTool *_Nullable  filterTool;


+(void)exportDidFinish:(NSURL *_Nullable)outputURL;
+ (void)exportDidFinish:(NSURL *_Nullable)outputURL complemetion:(CompletionBlock _Nullable)complemetion;

-(void)videoApplyAnimationAtFileURL:(NSURL *_Nullable)fileURL orientation:(NSInteger)orientation duration:(float)duration outputFilePath:(NSString *_Nullable)outputfilePath Animation:(AnimationBlock _Nullable)animation Dubbing:(nullable NSURL*)dubbing;

- (void)mergeAndExportVideosAtFileURLs:(NSDictionary *_Nullable)fileURLArray orientation:(NSInteger )orientation mergerFilePath:(NSString *_Nullable)mergeFilePath cutto:(CuttoBlock _Nullable)cutto Animation:(OverallAnimationBlock _Nullable)animation Begin:(BeginBlock _Nullable)begin;

-(void)transVideoAtFileURL:(NSURL *_Nullable)fileURL orientation:(NSInteger)orientation progress:(ProgressBlock _Nullable)progress Completion:(CompletionBlock _Nullable)completion;

+(void)trimVideo:(NSURL *_Nullable)fileURL startTime:(float)startTime endTime:(float)endTime toFilePath:(NSString *_Nullable)newPath Completion:(CompletionBlock _Nullable)completion;

+(void)trimVideoWithAsset:(AVAsset*_Nullable)asset startTime:(float)startTime endTime:(float)endTime toFilePath:(NSString *_Nullable)newPath Completion:(CompletionBlock _Nullable)completion;

-(void)addFilterWithUrl:(NSURL* _Nullable)url OutputUrl:(NSURL*_Nullable)output Orientation:(NSInteger)orientation Completion:(CompletionBlock _Nullable)completion;//滤镜添加

-(void)videoApplyPIPAnimationWithURL:(NSURL* _Nullable)url Orientation:(NSInteger)orientation duration:(float)duration outputFilePath:(NSString * _Nullable)outputfilePath PIP:(NSMutableDictionary* _Nullable)pip Completion:(CompletionBlock _Nullable)completion;//画中画添加

@end
