//
//  AnimationTool.m
//  doco_ios_app
//
//  Created by developer on 15/4/18.
//  Copyright (c) 2015年 developer. All rights reserved.
//

#import "AnimationTool.h"

@implementation AnimationTool{
    NSString* path;
}

//曲线运动
+(CAKeyframeAnimation *)curveAnimation:(NSDictionary *)points duration:(float)duration beginTime:(float)beginTime timeFunction:(CAMediaTimingFunction *)timeFunction isAutoReverse:(BOOL)isAutoReverse repeatCount:(int)repeatCount{
    duration=duration/1000;
    UIBezierPath *bezierPath = [[UIBezierPath alloc] init];
    float startX = [(NSNumber *)points[@"startx"] floatValue];
    float startY = [(NSNumber *)points[@"starty"] floatValue];
    float endX = [(NSNumber *)points[@"endx"] floatValue];
    float endY = [(NSNumber *)points[@"endy"] floatValue];
    float controlX1 = [(NSNumber *)points[@"controlx1"] floatValue];
    float controlY1 = [(NSNumber *)points[@"controly1"] floatValue];
    float controlX2 = [(NSNumber *)points[@"controlx2"] floatValue];
    float controlY2 = [(NSNumber *)points[@"controly2"] floatValue];
    //起始点
    [bezierPath moveToPoint:CGPointMake(startX, startY)];
    //终点  两个控制点  左点  右点
    [bezierPath addCurveToPoint:CGPointMake(endX, endY) controlPoint1:CGPointMake(controlX1, controlY1) controlPoint2:CGPointMake(controlX2, controlY2)];
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    
    animation.calculationMode = kCAAnimationLinear;
    animation.keyPath = @"position";
    animation.duration = duration;
    if(beginTime==0){
        animation.beginTime = AVCoreAnimationBeginTimeAtZero;
    }else{
        animation.beginTime = beginTime;
    }
    animation.removedOnCompletion = NO;
    animation.autoreverses = isAutoReverse;
    animation.repeatCount = repeatCount;
    if (timeFunction) {
        animation.timingFunction = timeFunction;
    }
    animation.fillMode = kCAFillModeBoth;
    return animation;
}

//直线运动
-(CAKeyframeAnimation *)straightlineAnimation:(NSDictionary *)animation groupBeginTime:(NSNumber *)groupBeginTime{
    float starttime = [self getTimeFromFrame:animation[@"starttime"]];
    float duration = [self getTimeFromFrame:animation[@"duration"]];

    float groupBeginT = [groupBeginTime floatValue];
    starttime =starttime/1000;
    duration=duration/1000;
    NSMutableArray *values = [[NSMutableArray alloc]init];
    NSArray *points = animation[@"values"];
    NSArray *numtimes = animation[@"times"];
    NSMutableArray *times =[[NSMutableArray alloc]init];
    for(int i=0;i<numtimes.count;i++) {
        float t = [self getTimeFromFrame:numtimes[i]];
        t=(t/1000-starttime)/duration;
        NSNumber *time = [NSNumber numberWithFloat:t];
        [times addObject:time];
    }
    //先计算出关键帧的时间点，再计算starttime的相对值
    starttime -=groupBeginT;
    //获取坐标点
    for (NSDictionary *dic in points) {
        float x = [(NSNumber *)dic[@"x"]floatValue];
        float y = [(NSNumber *)dic[@"y"]floatValue];
        if (_isPortrait) {
            y=960-y;
        }else{
            y=540-y;
        }
        NSValue *value = [NSValue valueWithCGPoint:CGPointMake(x, y)];
        [values addObject:value];
    }
    
    CAKeyframeAnimation *keyAnimation = [CAKeyframeAnimation animation];
    
    keyAnimation.calculationMode = kCAAnimationLinear;
    keyAnimation.keyPath = @"position";
    keyAnimation.keyTimes = times;
    keyAnimation.values = values;
    keyAnimation.duration = duration;
    MyLog(@"straight的开始时间：%f",starttime);
    if(starttime==0){
        keyAnimation.beginTime = AVCoreAnimationBeginTimeAtZero;
    }else{
        keyAnimation.beginTime = starttime;
    }
    keyAnimation.removedOnCompletion = NO;
    keyAnimation.autoreverses = NO;
    keyAnimation.repeatCount = 1;
//    if (timeFunction) {
//        keyAnimation.timingFunction = timeFunction;
//    }
    keyAnimation.fillMode = kCAFillModeBoth;
    return keyAnimation;
}

//透明度动画
-(CAKeyframeAnimation *)opacityAnimation:(NSDictionary *)animation groupBeginTime:(NSNumber *)groupBeginTime{
    float starttime = [self getTimeFromFrame:animation[@"starttime"]];
    float duration = [self getTimeFromFrame:animation[@"duration"]];
    float groupBeginT = [groupBeginTime floatValue];
    MyLog(@"group的time:%f",groupBeginT);
    starttime =starttime/1000;
    duration=duration/1000;
    NSArray *numtimes = animation[@"times"];
    NSMutableArray *times =[[NSMutableArray alloc]init];
    for(int i=0;i<numtimes.count;i++) {
        float t = [self getTimeFromFrame:numtimes[i]];
        t=(t/1000-starttime)/duration;
        NSNumber *time = [NSNumber numberWithFloat:t];
        [times addObject:time];
        MyLog(@"opacity,time:%@",time);
    }
    //先计算出关键帧的时间点，再计算starttime的相对值
    starttime -=groupBeginT;
    NSArray *oldvalues = animation[@"values"];
    NSMutableArray *values = [[NSMutableArray alloc]init];

    
    for (NSNumber *num in oldvalues) {
        float value = [num floatValue]/100;
        [values addObject:[NSNumber numberWithFloat:value]];
    }
    
    CAKeyframeAnimation *keyAnimation = [CAKeyframeAnimation animation];
    
    keyAnimation.calculationMode = kCAAnimationLinear;
    keyAnimation.keyPath = @"opacity";
    keyAnimation.keyTimes = times;
    keyAnimation.values = values;
    keyAnimation.duration = duration;
    MyLog(@"opacity的开始时间：%f",starttime);
    MyLog(@"opacity的duration: %f",duration);
    if(starttime==0){
        keyAnimation.beginTime = AVCoreAnimationBeginTimeAtZero;
    }else{
        keyAnimation.beginTime = starttime;
    }
    keyAnimation.removedOnCompletion = NO;
    keyAnimation.autoreverses = NO;
    keyAnimation.repeatCount = 1;
//    if (timeFunction) {
//        keyAnimation.timingFunction = timeFunction;
//    }
    keyAnimation.fillMode = kCAFillModeBoth;
    return keyAnimation;
}

//旋转动画
-(CAKeyframeAnimation *)rotateAnimation:(NSDictionary *)animation groupBeginTime:(NSNumber *)groupBeginTime{
    float starttime = [self getTimeFromFrame:animation[@"starttime"]];
    float duration = [self getTimeFromFrame:animation[@"duration"]];
    float groupBeginT = [groupBeginTime floatValue];
    starttime =starttime/1000;
    duration=duration/1000;
    NSArray *numtimes = animation[@"times"];
    NSMutableArray *times =[[NSMutableArray alloc]init];
    for(int i=0;i<numtimes.count;i++) {
        float t = [self getTimeFromFrame:numtimes[i]];
        t=(t/1000-starttime)/duration;
        NSNumber *time = [NSNumber numberWithFloat:t];
        [times addObject:time];
        
    }
    //先计算出关键帧的时间点，再计算starttime的相对值
    starttime -=groupBeginT;
    NSArray *oldvalues = animation[@"values"];
    
    NSMutableArray *values = [[NSMutableArray alloc]init];
    
    for (NSNumber *num in oldvalues) {
        float value = -[num floatValue]/180*M_PI;
        [values addObject:[NSNumber numberWithFloat:value]];
    }
    
    CAKeyframeAnimation *keyAnimation = [CAKeyframeAnimation animation];
    
    keyAnimation.calculationMode = kCAAnimationLinear;
    keyAnimation.keyPath = @"transform.rotation";
    keyAnimation.keyTimes = times;
    keyAnimation.values = values;
    keyAnimation.duration = duration;
    MyLog(@"rotate的开始时间：%f",starttime);
    if(starttime==0){
        keyAnimation.beginTime = AVCoreAnimationBeginTimeAtZero;
    }else{
        keyAnimation.beginTime = starttime;
    }
    keyAnimation.removedOnCompletion = NO;
    keyAnimation.autoreverses = NO;
    keyAnimation.repeatCount = 1;
//    if (timeFunction) {
//        keyAnimation.timingFunction = timeFunction;
//    }
    keyAnimation.fillMode = kCAFillModeForwards;
    return keyAnimation;
}

//缩放动画
-(CAKeyframeAnimation *)scaleAnimation:(NSDictionary *)animation groupBeginTime:(NSNumber *)groupBeginTime{
    float starttime = [self getTimeFromFrame:animation[@"starttime"]];
    float duration = [self getTimeFromFrame:animation[@"duration"]];

    float groupBeginT = [groupBeginTime floatValue];
    
    starttime =starttime/1000;
    duration=duration/1000;
    NSArray *numtimes = animation[@"times"];
    NSMutableArray *times =[[NSMutableArray alloc]init];
    for(int i=0;i<numtimes.count;i++) {
        float t = [self getTimeFromFrame:numtimes[i]];
        t=(t/1000-starttime)/duration;
        NSNumber *time = [NSNumber numberWithFloat:t];
        [times addObject:time];
    }
    //先计算出关键帧的时间点，再计算starttime的相对值
    starttime -=groupBeginT;
    NSArray *scales = animation[@"values"];
    
    NSMutableArray *values = [[NSMutableArray alloc]init];

    for (NSDictionary *dic in scales) {
        float x = [(NSNumber *)dic[@"x"] floatValue]/100;
        float y = [(NSNumber *)dic[@"y"] floatValue]/100;
        MyLog(@"scale:%f,%f",x,y);
        CATransform3D trans = CATransform3DMakeScale(x, y, 1);
        NSValue *value = [NSValue valueWithCATransform3D:trans];
        [values addObject:value];
    }
    CAKeyframeAnimation *keyAnimation = [CAKeyframeAnimation animation];
    
    keyAnimation.calculationMode = kCAAnimationLinear;
    keyAnimation.keyPath = @"transform";
    keyAnimation.keyTimes = times;
    keyAnimation.values = values;
    keyAnimation.duration = duration;
    MyLog(@"scale的开始时间：%f",starttime);
    if(starttime==0){
        keyAnimation.beginTime = AVCoreAnimationBeginTimeAtZero;
    }else{
        keyAnimation.beginTime = starttime;
    }
    keyAnimation.removedOnCompletion = NO;
    keyAnimation.autoreverses = NO;
    keyAnimation.repeatCount = 1;
//    if (timeFunction) {
//        keyAnimation.timingFunction = timeFunction;
//    }
    keyAnimation.fillMode = kCAFillModeBoth;
    return keyAnimation;
}

//序列帧动画
-(CAKeyframeAnimation *)pngframeAnimation:(NSDictionary *)animation groupBeginTime:(NSNumber *)groupBeginTime{
    NSArray *numtimes = animation[@"times"];
    float starttime = [self getTimeFromFrame:animation[@"starttime"]];
    float duration = [self getTimeFromFrame:animation[@"duration"]];
    NSArray *values = animation[@"values"];
    
    NSString *pngName = animation[@"pngname"];
    NSMutableArray* images = [[NSMutableArray alloc]init];
    NSMutableArray* times = [[NSMutableArray alloc] init];
    [times addObject:[NSNumber numberWithFloat:0]];
    for (int n=0; n<numtimes.count - 1; n++) {
        float time1 = [self getTimeFromFrame:numtimes[n]]/1000;
        float time2 = [self getTimeFromFrame:numtimes[n+1]]/1000;
        int count = (time2 - time1) * 25;
        int value1 = [values[n] intValue];
        int value2 = [values[n+1] intValue];
        for(int i=0;i<count;i++){
            NSMutableString *fileName;
            if (value1 < value2) {
                fileName =[[NSMutableString alloc]initWithFormat:@"%@_%04d",pngName, i+value1];
                [times addObject:[NSNumber numberWithFloat:((time1 - starttime) + (float)(i/25.0f))/duration]];
            }else if(value1 > value2){
                fileName =[[NSMutableString alloc]initWithFormat:@"%@_%04d",pngName, value1-i];
                [times addObject:[NSNumber numberWithFloat:((time1 - starttime) + (float)(i/25.0f))/duration]];

            }else{
                break;
            }
            NSString *filePath = [path stringByAppendingPathComponent:pngName];
            filePath = [filePath stringByAppendingPathComponent:fileName];
            
            UIImage *coverImage = [UIImage imageWithContentsOfFile:filePath];
            [images addObject:(id)coverImage.CGImage];
        }
    }
    starttime -= [groupBeginTime floatValue];

    CAKeyframeAnimation *keyAnimation = [CAKeyframeAnimation animation];
    keyAnimation.calculationMode = kCAAnimationDiscrete;
    keyAnimation.removedOnCompletion = NO;
    keyAnimation.keyPath = @"contents";
    [keyAnimation setValues:images];
    [keyAnimation setKeyTimes:times];
    keyAnimation.duration = duration;
    keyAnimation.beginTime = starttime;
    keyAnimation.autoreverses = NO;
    keyAnimation.repeatCount = 1;
    keyAnimation.fillMode = kCAFillModeBoth;
    return keyAnimation;
}

//组合动画
-(CAAnimationGroup *)groupAnimation:(NSDictionary *)animations WithSegStartTime:(float)startTime

{
    float beginTime = [self getTimeFromFrame:animations[@"starttime"]]/1000;
    float duration = [self getTimeFromFrame:animations[@"duration"]];
    path = animations[@"paths"];
    
    NSMutableArray *groupAnimations = [[NSMutableArray alloc]init];
    for(int i=0;i < animations.count;i++){
        NSString *anikey = [NSString stringWithFormat:@"animation%d",i+1];
        if (!animations[anikey]) {
            break;
        }
        NSDictionary *animation = animations[anikey];
        NSString *name = animation[@"name"];
        NSString *funcName = [NSString stringWithFormat:@"%@Animation:groupBeginTime:",name];
        MyLog(@"%@",funcName);
        CAKeyframeAnimation *keyAnimation =[self performSelector:NSSelectorFromString(funcName) withObject:animation withObject:[NSNumber numberWithFloat:beginTime]];
        [groupAnimations addObject:keyAnimation];
    }
    
    duration/=1000;
    beginTime-=(startTime/1000);
    MyLog(@"group的开始时间：%f",beginTime);
    CAAnimationGroup *groupAnimation = [CAAnimationGroup animation];
    groupAnimation.animations = groupAnimations;
    groupAnimation.duration = duration;
    groupAnimation.fillMode = kCAFillModeBoth;
    if (beginTime==0) {
        groupAnimation.beginTime = AVCoreAnimationBeginTimeAtZero;
    }else{
        groupAnimation.beginTime = beginTime;
    }
    
    
    return groupAnimation;
    
}

-(void)test:(NSString *)aa bb:(NSString *)bb{
    MyLog(@"%@,%@",aa,bb);
}



//永久闪烁动画
+(CABasicAnimation *)opacityForever_Animation:(float)time

{
    
    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"opacity"];
    
    animation.fromValue=[NSNumber numberWithFloat:1.0];
    
    animation.toValue=[NSNumber numberWithFloat:0.0];
    
    animation.autoreverses=YES;
    
    animation.duration=time;
    
    animation.repeatCount=FLT_MAX;
    
    animation.removedOnCompletion=NO;
    
    animation.fillMode=kCAFillModeForwards;
    
    return animation;
    
}

//有闪烁次数的动画
+(CABasicAnimation *)opacityTimes_Animation:(float)repeatTimes durTimes:(float)time fromOpacity:(float)fromOpacity toOpacity:(float)toOpacity

{
    
    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"opacity"];
    
    animation.repeatCount=repeatTimes;
    
    animation.fromValue = [NSNumber numberWithFloat:fromOpacity];
    
    animation.toValue = [NSNumber numberWithFloat:toOpacity];
    
    animation.duration=time;
    
    animation.removedOnCompletion=NO;
    
    animation.fillMode=kCAFillModeForwards;
    
    animation.autoreverses=NO;
    
    return  animation;
    
}


//横向移动
+(CABasicAnimation *)moveX:(float)time X:(NSNumber *)x

{
    
    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    
    animation.toValue=x;
    
    animation.duration=time;
    
    animation.removedOnCompletion=NO;
    
    animation.fillMode=kCAFillModeForwards;
    
    return animation;
    
}

//纵向移动
+(CABasicAnimation *)moveY:(float)time Y:(NSNumber *)y

{
    
    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    
    animation.toValue=y;
    
    animation.duration=time;
    
    animation.removedOnCompletion=NO;
    
    animation.fillMode=kCAFillModeForwards;
    
    return animation;
    
}

//缩放
+(CABasicAnimation *)scale:(NSNumber *)Multiple orgin:(NSNumber *)orginMultiple durTimes:(float)time Rep:(float)repeatTimes

{
    
    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
    
    animation.fromValue=orginMultiple;
    
    animation.toValue=Multiple;
    
    animation.duration=time;
    
    animation.autoreverses=NO;
    
    animation.repeatCount=repeatTimes;
    
    animation.removedOnCompletion=NO;
    
    animation.fillMode=kCAFillModeForwards;
    
    return animation;
    
}

//路径动画
+(CAKeyframeAnimation *)keyframeAniamtion:(CGMutablePathRef)path durTimes:(float)time Rep:(float)repeatTimes

{
    
    CAKeyframeAnimation *animation=[CAKeyframeAnimation animationWithKeyPath:@"position"];
    
    animation.path=path;
    
    animation.removedOnCompletion=NO;
    
    animation.fillMode=kCAFillModeForwards;
    
    animation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    animation.autoreverses=NO;
    
    animation.duration=time;
    
    animation.repeatCount=repeatTimes;
    
    return animation;
    
}

//点移动
+(CABasicAnimation *)moveToPoint:(CGPoint )point

{
    
    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"transform.translation"];
    
    animation.toValue=[NSValue valueWithCGPoint:point];
    
    animation.removedOnCompletion=NO;
    
    animation.fillMode=kCAFillModeForwards;
    
    return animation;
    
}

+(CABasicAnimation *)moveFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint{
    
    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"transform.translation"];
    animation.fromValue = [NSValue valueWithCGPoint:fromPoint];
    animation.toValue=[NSValue valueWithCGPoint:toPoint];
    
    animation.removedOnCompletion=NO;
    
    animation.fillMode=kCAFillModeForwards;
    
    return animation;
}

//旋转
+(CABasicAnimation *)rotation:(float)dur degree:(float)degree direction:(int)direction repeatCount:(int)repeatCount

{
    
    CATransform3D rotationTransform  = CATransform3DMakeRotation(degree, 0, 0,direction);
    
    CABasicAnimation* animation;
    
    animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    
    
    
    animation.toValue= [NSValue valueWithCATransform3D:rotationTransform];
    
    animation.duration= dur;
    
    animation.autoreverses= NO;
    
    animation.cumulative= YES;
    
    animation.removedOnCompletion=NO;
    
    animation.fillMode=kCAFillModeForwards;
    
    animation.repeatCount= repeatCount;
    
    animation.delegate= self;
    
    
    
    return animation;
    
}

+(CABasicAnimation *)boundsFromRect:(CGRect)fromRect byRect:(CGRect)byRect toRect:(CGRect)toRect{
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"bounds"];
    anim.duration = 1.f;
    anim.fromValue = [NSValue valueWithCGRect:CGRectMake(0,0,10,10)];
    anim.toValue = [NSValue valueWithCGRect:CGRectMake(10,10,200,200)];
    anim.byValue  = [NSValue valueWithCGRect:byRect];
    //    anim.toValue = (id)[UIColor redColor].CGColor;
    //    anim.fromValue =  (id)[UIColor blackColor].CGColor;
    
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    anim.repeatCount = 1;
    anim.autoreverses = YES;
    return anim;
}

-(float)getTimeFromFrame:(NSDictionary *)dic{
    float second = [(NSNumber *)dic[@"second"] floatValue];
    float frame = [(NSNumber *)dic[@"frame"] floatValue];
    float startTime = second*1000+frame*40;
    return startTime;
}

@end
