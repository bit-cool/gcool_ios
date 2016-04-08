//
//  AnimationAnalysisTool.m
//  doco_ios_app
//
//  Created by developer on 15/6/1.
//  Copyright (c) 2015年 developer. All rights reserved.
//

#import "AnimationAnalysisTool.h"
#import "AnimationTool.h"

@implementation AnimationAnalysisTool

-(void)setupLayerWithDic:(NSDictionary *)layer toLayer:(CALayer *)anilayer startTime:(float)startTime type:(NSString *)type{
    
    //获取透明度
    float opacity = [(NSNumber *)layer[@"opacity"] floatValue]/100;
    [anilayer setOpacity:opacity];
    
    //获取锚点
    NSDictionary *anchorpoint = layer[@"anchorpoint"];
    float ax,ay;
    //获取坐标
    NSDictionary *position = layer[@"position"];
    float px = [(NSNumber *)position[@"x"] floatValue];
    float py = [(NSNumber *)position[@"y"] floatValue];
    //获取大小
    NSDictionary *size = layer[@"size"];
    float width = [(NSNumber *)size[@"width"] floatValue];
    float height = [(NSNumber *)size[@"height"] floatValue];
    
    if (!_isPortrait) {//横屏
        ax = [(NSNumber *)anchorpoint[@"x"] floatValue]/960;
        ay = 1-[(NSNumber *)anchorpoint[@"y"] floatValue]/540;
        py = 540-py;
        anilayer.frame = CGRectMake(px, py, width, height);
    }else{
        ax = [(NSNumber *)anchorpoint[@"x"] floatValue]/540;
        ay = 1-[(NSNumber *)anchorpoint[@"y"] floatValue]/960;
        py = 960-py;
        anilayer.frame = CGRectMake(px, py, width, height);
    }
    
    //layer的大小
    if ([@"subtitle" isEqualToString:type]) {
        anilayer.frame = CGRectMake(0, 0, width, height+10);
    }
    anilayer.anchorPoint = CGPointMake(ax, ay);
    anilayer.position = CGPointMake(px, py);
    
    //获取scale
    NSDictionary *scale = layer[@"scale"];
    float sx = [(NSNumber *)scale[@"x"] floatValue]/100;
    float sy = [(NSNumber *)scale[@"y"] floatValue]/100;
    [anilayer setTransform:CATransform3DMakeScale(sx, sy, 1)];
    //解析动画
    AnimationTool *tool = [[AnimationTool alloc]init];
    tool.isPortrait = _isPortrait;
    NSMutableDictionary *animations = [NSMutableDictionary dictionaryWithDictionary:layer[@"animations"]];
    NSDictionary *animation1 = animations[@"animation1"];
    if ([@"still"isEqualToString: animation1[@"name"]]) {
        return;
    }
    [animations setObject:_resources forKey:@"paths"];
    
    CAAnimationGroup *groupAnimation;
    groupAnimation = [tool groupAnimation:animations WithSegStartTime:startTime ];
    [anilayer addAnimation:groupAnimation forKey:nil];
}

-(void)segmentAnimationAnalysisWithDic:(NSDictionary *)segment subtitles:(NSMutableArray *)subs parentLayer:(CALayer *)parentLayer headImage:(UIImage *)headImage footImage:(UIImage *)footImage{
    float startTime = [self getTimeFromFrame:segment[@"starttime"]];
    
    if(segment[@"head"]){
        NSDictionary  *head = segment[@"head"];
        CALayer *anilayer = [CALayer layer];
        [self setupLayerWithDic:head toLayer:anilayer startTime:startTime type:nil];
        //设置片头的图片  （固定的路径）
        anilayer.contents = (id)headImage.CGImage;
        //等比例放大
        anilayer.contentsGravity = kCAGravityResizeAspect;
        [parentLayer addSublayer:anilayer];
        
    }else if (segment[@"foot"]){
        NSDictionary  *foot = segment[@"foot"];
        CALayer *anilayer = [CALayer layer];
        [self setupLayerWithDic:foot toLayer:anilayer startTime:startTime type:nil];
        //设置片尾的图片  （固定的路径）
        anilayer.contents = (id)footImage.CGImage;
        anilayer.contentsGravity = kCAGravityResizeAspect;
        [parentLayer addSublayer:anilayer];
    }else if (segment[@"heads"]){
        NSDictionary *layers = segment[@"heads"];
        for (int k=0; k<layers.count; k++) {
            NSString *layerkey = [NSString stringWithFormat:@"layer%d",k+1];
            if(!layers[layerkey]){
                break;
            }
            NSDictionary *layer = layers[layerkey];
            //创建layer
            CALayer *animationlayer = [CALayer layer];
            [self setupLayerWithDic:layer toLayer:animationlayer startTime:startTime type:nil];
            //获取图片名称
            NSString *imageName = layer[@"imageName"];
            MyLog(@"imageName：%@",imageName);
            NSString *imagePath = [[NSBundle mainBundle]pathForResource:imageName ofType:nil];
            UIImage *aniImage = [UIImage imageWithContentsOfFile:imagePath];
            [animationlayer setContents:(id)aniImage.CGImage];
            [parentLayer addSublayer:animationlayer];
        }
    }else if (segment[@"foots"]){
        NSDictionary *layers = segment[@"foots"];
        for (int k=0; k<layers.count; k++) {
            NSString *layerkey = [NSString stringWithFormat:@"layer%d",k+1];
            if(!layers[layerkey]){
                break;
            }
            NSDictionary *layer = layers[layerkey];
            //创建layer
            CALayer *animationlayer = [CALayer layer];
            [self setupLayerWithDic:layer toLayer:animationlayer startTime:startTime type:nil];
            //获取图片名称
            NSString *imageName = layer[@"imageName"];
            NSString *imagePath = [[NSBundle mainBundle]pathForResource:imageName ofType:nil];
            MyLog(@"imageName：%@",imageName);
            UIImage *aniImage = [UIImage imageWithContentsOfFile:imagePath];
            [animationlayer setContents:(id)aniImage.CGImage];
            [parentLayer addSublayer:animationlayer];
        }

    }
    MyLog(@"%lu",(unsigned long)segment.count);
    for (int j=0; j<segment.count; j++) {
        NSString *trackkey = [NSString stringWithFormat:@"track%d",j+1];

        if (!segment[trackkey]) {
            break;
        }
        NSDictionary *layers = segment[trackkey];
        MyLog(@"trackkey:%@",trackkey);
        [self layersAnimationAnalysisWithDic:layers parentLayer:parentLayer startTime:startTime];
    }
    
    //解析字幕
    NSDictionary *subtitles = segment[@"subtitles"];
    for (int i=0; i<subtitles.count; i++) {
//        NSString *subtitlekey = [NSString stringWithFormat:@"sublayer%d",i+1];
        NSString *subtitlekey = [NSString stringWithFormat:@"subtitle%d",i+1];
        if (!subtitles[subtitlekey]) {
            break;
        }
//        NSDictionary *sublayerDic = subtitles[subtitlekey];
        NSDictionary *subtitle = subtitles[subtitlekey];
        //创建字幕的画布
//        CALayer *subDrawlayer = [CALayer layer];
//        [self setupLayerWithDic:sublayerDic toLayer:subDrawlayer startTime:startTime type:nil];
        
        //解析字幕专有属性
        CATextLayer *sublayer = [CATextLayer layer];
        [self setupLayerWithDic:subtitle toLayer:sublayer startTime:startTime type:@"subtitle"];
//        NSDictionary *position = subtitle[@"position"];
//        float px = [(NSNumber *)position[@"x"] floatValue];
//        float py = [(NSNumber *)position[@"y"] floatValue];
//        
//        NSDictionary *size = subtitle[@"size"];
//        float width = [(NSNumber *)size[@"width"] floatValue];
//        float height = [(NSNumber *)size[@"height"] floatValue];
        //sublayer.frame = CGRectMake(0, 0, width, height);
        //sublayer.position = CGPointMake(px, py);
        //[subDrawlayer addSublayer:sublayer];
        //字体
        //NSString *fontName = subtitle[@"fontName"];
        //字体大小
        float fontSize = [(NSNumber *)subtitle[@"fontSize"] floatValue];
        //字体颜色
        NSDictionary *rgba = subtitle[@"fontColor"];
        UIColor *fontColor = kColor([rgba[@"r"] floatValue], [rgba[@"g"] floatValue], [rgba[@"b"] floatValue], [rgba[@"a"] floatValue]);
        //内容
        NSString *text = subtitle[@"textName"];
        if (subs.count<=i) {
            MyLog(@"字幕的描述数量与合成数量不符！");
        }
        
//        for (DoCoSubtitle *sub in subs) {
//            MyLog(@"%@===",sub.textName);
//            if ([text isEqualToString:sub.textName]) {
//                text = sub.text;
//                break;
//            }
//        }
        NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc]initWithString:text attributes:@{
            NSForegroundColorAttributeName :fontColor,
            NSKernAttributeName:@0,
            NSFontAttributeName:[UIFont fontWithName:@"Helvetica" size:fontSize],
//            //下面这个属性值是设置描边的颜色
//            NSStrokeColorAttributeName:[UIColor redColor],
//            //下面这个属性值是设置描边的宽度（像素）  正数为镂空，向外描边，负数为向内描边
//            NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-1.5f],
            NSVerticalGlyphFormAttributeName:@(0),
            }];
        //在这里设置字体
        
        [sublayer setString:attributeStr];
        
        NSString* alignment = subtitle[@"textAlignment"];
        if (alignment) {
            if ([alignment isEqualToString:@"left"]) {
                [sublayer setAlignmentMode:kCAAlignmentLeft];
            }
            else if([alignment isEqualToString:@"right"]){
                [sublayer setAlignmentMode:kCAAlignmentRight];
            }
            else{
                [sublayer setAlignmentMode:kCAAlignmentCenter];
            }
        }else{
            [sublayer setAlignmentMode:kCAAlignmentCenter];
        }
        
        [parentLayer addSublayer:sublayer];
        //[parentLayer addSublayer:subDrawlayer];
    }
}

-(void)layersAnimationAnalysisWithDic:(NSDictionary *)layers parentLayer:(CALayer *)parentLayer startTime:(float)startTime{
    
    for (int k=0; k<layers.count; k++) {
        NSString *layerkey = [NSString stringWithFormat:@"layer%d",k+1];
        if(!layers[layerkey]){
            break;
        }
        MyLog(@"layerKey:%@",layerkey);
        NSDictionary *layer = layers[layerkey];
        //创建layer
        CALayer *animationlayer = [CALayer layer];
        [self setupLayerWithDic:layer toLayer:animationlayer startTime:startTime type:nil];
        //获取图片名称
        NSString *imageName = layer[@"imageName"];
        NSString *imagePath = [_resources stringByAppendingPathComponent:imageName];
        MyLog(@"imageName：%@",imagePath);
        UIImage *aniImage = [UIImage imageWithContentsOfFile:imagePath];
        if (!aniImage) {//若为空 则尝试读取其他字段
            aniImage = layer[@"image"];
        }
        if (!aniImage) {//依然为空 则再读取本地文件
            MyLog(@"Image::为空了！！！！");
            aniImage = [UIImage imageWithContentsOfFile:imagePath];
        }
        if (aniImage) {
            [animationlayer setContents:(id)aniImage.CGImage];
        }
        
        [parentLayer addSublayer:animationlayer];
    }
}

-(void)overall_layerAnimationAnalysisWithDic:(NSDictionary *)layers parentLayer:(CALayer *)parentLayer{
    [self layersAnimationAnalysisWithDic:layers parentLayer:parentLayer startTime:0];
}

#pragma mark-添加音乐也是在这了
-(void)cuttoLayerAnimationAnalysisWithDic:(NSDictionary *)cuttolayers parentLayer:(CALayer *)parentLayer manager:(DoCoVideoLayerAnimationManager *)manager{
    //manager中是nsnumber   ms毫秒
    //    添加背景音乐
    NSString * path = cuttolayers[@"backgroundMusic"];
    MyLog(@"musicPath:%@",path);
    NSURL *musicURL = [NSURL fileURLWithPath:path];
    CMTime startTime = kCMTimeZero;
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:musicURL options:nil];
    AVAssetTrack *sourceAudioTrack = [[songAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    [manager setUpAndAddAudioAtPath:sourceAudioTrack start:startTime dura:CMTimeMakeWithSeconds([manager.totalDurs[manager.totalDurs.count-1] floatValue]/1000, sourceAudioTrack.timeRange.duration.timescale)  Type:@"bg"];
    
    //加载转场动画和音效
    int index = 1;
    for (int i=0; i<cuttolayers.count; i++) {
        NSString *cuttolayerkey = [NSString stringWithFormat:@"cutto%d",index];
        while (!cuttolayers[cuttolayerkey]) {
            index++;
            cuttolayerkey = [NSString stringWithFormat:@"cutto%d",index];
            if (index>cuttolayers.count+5) {//防止出现死循环
                return;
            }
        }
        MyLog(@"%@---%d",cuttolayerkey,i);
        //计算startTime  这里其实是被剪切掉的时长
        NSDictionary *layers = cuttolayers[cuttolayerkey];
        float nowStartTime = [(NSNumber *)manager.totalDurs[i] floatValue] - [self getTimeFromFrame:layers[@"duration"]]/2;
        
        float oldStartTime = [self getTimeFromFrame:layers[@"starttime"]];
        
        float starttime = oldStartTime - nowStartTime;
        MyLog(@"startTime:%f",starttime);
        [self layersAnimationAnalysisWithDic:layers parentLayer:parentLayer startTime:starttime];
        
        //转场音效添加
        NSString * path = [_resources stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp3",layers[@"music"]]];
        MyLog(@"cuttoPath:%@",path);
        NSURL *musicURL = [NSURL fileURLWithPath:path];
        AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:musicURL options:nil];
        CMTime duration = [songAsset duration];
        AVAssetTrack *sourceAudioTrack = [[songAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        CMTime startTime = CMTimeMakeWithSeconds(([manager.totalDurs[index-1] floatValue]/1000-0.5), sourceAudioTrack.timeRange.duration.timescale);
        [manager setUpAndAddAudioAtPath:sourceAudioTrack start:startTime dura:duration Type:@"cutto"];
        index++;
    }
}

-(void)cuttoAnimationAnalysisWithDic:(NSDictionary *)cuttos manager:(DoCoVideoLayerAnimationManager *)manager{
    int index = 1;
    for (int i = 0; i<cuttos.count; i++) {
        
        NSString *cuttokey = [NSString stringWithFormat:@"cutto%d",index];
        while (!cuttos[cuttokey]) {
            index++;
            cuttokey = [NSString stringWithFormat:@"cutto%d",index];
        }
        index ++;
        NSDictionary *cutto = cuttos[cuttokey];
        NSString *name = cutto[@"cuttoname"];
        float duration = [self getTimeFromFrame:cutto[@"duration"]];
        
        if ([@"translation" isEqualToString:name]) {
            NSString *direction = cutto[@"direction"];
            [manager cuttoAnimationtranslationAsset:manager.assetArray[i+1] direction:direction duration:duration];
        }else{
            
            NSString *funcName = [NSString stringWithFormat:@"cuttoAnimation%@Asset:duration:",name];
            MyLog(@"%d的函数名：%@",i,funcName);
            [manager performSelector:NSSelectorFromString(funcName) withObject:manager.assetArray[i+1] withObject:[NSNumber numberWithFloat:duration]];
        }
        
    }
}

//画中画(支持复数视频)
-(void)addVideoWithVideoComposition:(AVMutableVideoComposition *)videoCom Composition:(AVMutableComposition*)com Dictionary:(NSDictionary *)dic{
    //获取instructions
    AVMutableVideoCompositionInstruction* main = (AVMutableVideoCompositionInstruction*)[videoCom.instructions objectAtIndex:0];
    NSMutableArray* videoArr;
    if (main) {
        videoArr = [NSMutableArray arrayWithArray:main.layerInstructions];
    }
    //横竖屏判断 逻辑尺寸
    CGFloat width;
    CGFloat height;
    if (_isPortrait) {
        width = 540;
        height = 960;
    }else{
        width = 960;
        height = 540;
    }
    //依照模板添加子视频
    NSError* error;
    int i = 1;
    for (i = 1; i <= [dic allKeys].count; i++) {
        //读取dictionary
        NSDictionary* video = [dic objectForKey:[NSString stringWithFormat:@"video%d",i]];
        CGFloat startTime = [self getTimeFromFrame:[video objectForKey:@"starttime"]]/1000;
        CGFloat scale = ((NSNumber*)[video objectForKey:@"scale"]).floatValue;
        NSDictionary* position = [video objectForKey:@"position"];
        CGFloat px = ((NSNumber*)[position objectForKey:@"x"]).floatValue;
        px = px - width/2*scale;
        CGFloat py = ((NSNumber*)[position objectForKey:@"y"]).floatValue;
        py = py - height/2*scale;
        CGFloat fadein = [[video objectForKey:@"fadeInDuration"] floatValue];
        CGFloat fadeout = [[video objectForKey:@"fadeOutDuration"] floatValue];
        CGFloat duration = [[video objectForKey:@"duration"] floatValue];
        NSURL* url;
        if ([video objectForKey:@"path"] == nil) {
            continue;
        }else{
            url = [NSURL fileURLWithPath:[video objectForKey:@"path"]];
            MyLog(@"%f--%f--%f---%f---%f---%f----%f",px,py,scale,startTime,fadein,fadeout,duration);
        }

        AVAsset* asset = [AVAsset assetWithURL:url];
        NSArray* tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        AVAssetTrack* videoTrack = tracks.count>0?[tracks objectAtIndex:0]:nil;
        if (videoTrack == nil) {//偶尔的读取失败 再读一次
            asset = [AVAsset assetWithURL:url];
            tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            videoTrack = tracks.count>0?[tracks objectAtIndex:0]:nil;
        }
        if (videoTrack) {
            //视频尺寸处理 按照最小比例进行缩放 使原视频尺寸在960x540之内
            CGFloat naturlWidth = [videoTrack naturalSize].width;
            CGFloat naturlHeight = [videoTrack naturalSize].height;
            scale = scale*MIN(width/naturlWidth, height/naturlHeight);
            
            //添加layerinsturction
            AVMutableCompositionTrack* mixTrack = [com addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            [mixTrack insertTimeRange:
                            CMTimeRangeMake(kCMTimeZero, asset.duration)
                              ofTrack:videoTrack
                               atTime:CMTimeMake(startTime*25, 25)
                                error:&error];
            AVMutableVideoCompositionLayerInstruction* layer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:mixTrack];
            //添加transform
            CGAffineTransform transform = CGAffineTransformIdentity;
            transform = CGAffineTransformTranslate(transform, px, py);
            transform = CGAffineTransformScale(transform, scale, scale);
            
            [layer setTransform:transform atTime:kCMTimeZero];
            [layer setOpacity:0 atTime:kCMTimeZero];
            [layer setOpacityRampFromStartOpacity:0 toEndOpacity:0.99 timeRange:CMTimeRangeMake(CMTimeMake(startTime*25, 25), CMTimeMake(fadein*25, 25))];
            if (fadeout>0) {
                [layer setOpacityRampFromStartOpacity:0.99 toEndOpacity:0 timeRange:CMTimeRangeMake(CMTimeMake((startTime + duration - fadeout)*25, 25) ,CMTimeMake(fadeout*25, 25) )];
            }
        
            [videoArr insertObject:layer atIndex:0];
        }else{
            NSLog(@"获取视频失败");
        }
    }
    main.layerInstructions = videoArr;
}

-(float)getTimeFromFrame:(NSDictionary *)dic{
    float second = [(NSNumber *) dic[@"second"] floatValue];
    float frame = [(NSNumber *)dic[@"frame"] floatValue];
    float startTime = second*1000+frame*40;
    return startTime;
}

@end
