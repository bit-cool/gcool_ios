//
//  AnimationTool.h
//  doco_ios_app
//
//  Created by developer on 15/4/18.
//  Copyright (c) 2015年 developer. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface AnimationTool : NSObject

@property(nonatomic,assign)BOOL isPortrait;

+(CABasicAnimation *)moveX:(float)time X:(NSNumber *)x;

-(CAAnimationGroup *)groupAnimation:(NSDictionary *)animations WithSegStartTime:(float)startTime;

+(CABasicAnimation *)opacityTimes_Animation:(float)repeatTimes durTimes:(float)time fromOpacity:(float)fromOpacity toOpacity:(float)toOpacity;

+(CABasicAnimation *)scale:(NSNumber *)Multiple orgin:(NSNumber *)orginMultiple durTimes:(float)time Rep:(float)repeatTimes;

//直线运动
-(CAKeyframeAnimation *)straightlineAnimation:(NSDictionary *)animation groupBeginTime:(NSNumber *)groupBeginTime;

+(CAKeyframeAnimation *)curveAnimation:(NSDictionary *)points duration:(float)duration beginTime:(float)beginTime timeFunction:(CAMediaTimingFunction *)timeFunction isAutoReverse:(BOOL)isAutoReverse repeatCount:(int)repeatCount;

//透明度动画
-(CAKeyframeAnimation *)opacityAnimation:(NSDictionary *)animation groupBeginTime:(NSNumber *)groupBeginTime;

//旋转动画
-(CAKeyframeAnimation *)rotateAnimation:(NSDictionary *)animation groupBeginTime:(NSNumber *)groupBeginTime;

//缩放动画
-(CAKeyframeAnimation *)scaleAnimation:(NSDictionary *)animation groupBeginTime:(NSNumber *)groupBeginTime;

//序列帧动画
 -(CAKeyframeAnimation *)pngframeAnimation:(NSDictionary *)animation groupBeginTime:(NSNumber *)groupBeginTime;

@end
