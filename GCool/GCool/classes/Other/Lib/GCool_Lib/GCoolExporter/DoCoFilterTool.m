//
//  DoCoFilterTool.m
//  doco_ios_app
//
//  Created by developer on 15/11/18.
//  Copyright © 2015年 developer. All rights reserved.
//

#import "DoCoFilterTool.h"
//#import "opencv2/opencv.hpp"
//#import "OpenCV.h"
@interface DoCoFilterTool()

@property (nonatomic) CIDetector* detector;

@end

@implementation DoCoFilterTool

#pragma public
-(instancetype)initWithFilterType:(DoCoFilterType)type Stength:(DoCoFilterStrength)strength{
    self = [super init];
    if (self) {
        _type = type;
        _strength = strength;
    }
    return self;
}

-(CIImage*)filtImage:(CIImage *)inputImage WithOption:(NSDictionary *)option{
    CIImage* outputImage;
    switch (_type) {
        case DoCoFilterType_Adjustment:{
            outputImage = [self filtAdjustmentWithImage:inputImage Option:option];
            break;
        }
        case DoCoFilterType_OldPhoto:{
            outputImage = [self filtOldPhotoWithImage:inputImage Option:option];
            break;
        }
        case DoCoFilterType_Light:{
            outputImage = [self filtLightWithImage:inputImage Option:option];
            break;
        }
        case DoCoFilterType_MonoChrome:{
            outputImage = [self filtMonoWithImage:inputImage Option:option];
            break;
        }
        default:
            break;
    }
    return outputImage;
}

#pragma private
//皮肤美化滤镜
-(CIImage*)filtAdjustmentWithImage:(CIImage*)image Option:(NSDictionary*)option{
    
    NSArray* faces = [self faceDetectWithImage:image];
    CIImage* outputImage;
    CIImage* mask;
    CIFilter* filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    
    switch (_strength) {
        case DoCoFilterStrength_Strong:{
            [filter setValue:[NSNumber numberWithFloat:3.0] forKey:@"inputRadius"];
            break;
        }
        case DoCoFilterStrength_Weak:{
            [filter setValue:[NSNumber numberWithFloat:1.5] forKey:@"inputRadius"];
            break;
        }
        default:
            break;
    }
    [filter setValue:image forKey:kCIInputImageKey];
    outputImage = filter.outputImage;
    
//    NSArray<AVMetadataFaceObject*>* faces = option[@"faces"];
    if (faces.count <= 0) {
        
        filter = [CIFilter filterWithName:@"CIScreenBlendMode"];
        [filter setValue:image forKey:kCIInputBackgroundImageKey];
        [filter setValue:outputImage forKey:kCIInputImageKey];
        outputImage = filter.outputImage;
        return outputImage;
        
    }
    for (CIFaceFeature* face in faces) {
        CGRect rect = face.bounds;
//        CGFloat centerX = image.extent.size.width * (rect.origin.x + rect.size.width/2);
//        CGFloat centerY = image.extent.size.height * (1 - rect.origin.y - rect.size.height /2);
//        CGFloat radius = MAX(rect.size.width*image.extent.size.width/2, rect.size.height*image.extent.size.height/2);
//        MyLog(@"img%@face%@",[NSValue valueWithCGRect:image.extent],[NSValue valueWithCGRect:rect]);
        CGFloat centerX = rect.size.width/2 + rect.origin.x;
        CGFloat centerY = rect.size.height/2 + rect.origin.y;
        CGFloat radius = MAX(rect.size.width, rect.size.height);
               filter = [CIFilter filterWithName:@"CIRadialGradient" withInputParameters:@{
                                                                                    @"inputRadius0":[NSNumber numberWithDouble:radius],
                                                                                    @"inputRadius1":[NSNumber numberWithDouble:radius+1],
                                                                                    @"inputColor0":[CIColor colorWithRed:0 green:1 blue:0 alpha:1],
                                                                                    @"inputColor1":[CIColor colorWithRed:0 green:0 blue:0 alpha:0],
                                                                                    kCIInputCenterKey : [CIVector vectorWithX:centerX Y:centerY]}];
        CIImage* radia = [filter.outputImage imageByCroppingToRect:image.extent];
        if (mask == nil) {
            mask = radia;
        }else{
            filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
            [filter setValue:radia forKey:kCIInputImageKey];
            [filter setValue:mask forKey:kCIInputBackgroundImageKey];
            mask = filter.outputImage;
        }
    }
    
    filter = [CIFilter filterWithName:@"CIBlendWithMask"];
    [filter setValue:image forKey:kCIInputBackgroundImageKey];
    [filter setValue:outputImage forKey:kCIInputImageKey];
    [filter setValue:mask forKey:kCIInputMaskImageKey];
    outputImage = filter.outputImage;
    
    filter = [CIFilter filterWithName:@"CIScreenBlendMode"];
    [filter setValue:image forKey:kCIInputBackgroundImageKey];
    [filter setValue:outputImage forKey:kCIInputImageKey];
    outputImage = filter.outputImage;
    
    return outputImage;
}

//老照片滤镜
-(CIImage*)filtOldPhotoWithImage:(CIImage*)image Option:(NSDictionary*)option{
    CIImage* outputImage;
    CIFilter* filter = [CIFilter filterWithName:@"CISepiaTone"];
    switch (_strength) {
        case DoCoFilterStrength_Strong:{
            [filter setValue:[NSNumber numberWithFloat:1] forKey:@"inputIntensity"];
            break;
        }
        case DoCoFilterStrength_Weak:{
            [filter setValue:[NSNumber numberWithFloat:0.5] forKey:@"inputIntensity"];
            break;
        }
        default:
            break;
    }
    [filter setValue:image forKey:kCIInputImageKey];
    outputImage = filter.outputImage;
    return outputImage;
}
//亮度滤镜
-(CIImage*)filtLightWithImage:(CIImage*)image Option:(NSDictionary*)option{
    CIImage* outputImage;
    CIFilter* filter = [CIFilter filterWithName:@"CIColorControls"];
    switch (_strength) {
        case DoCoFilterStrength_Strong:{
            [filter setValue:[NSNumber numberWithFloat:0.25] forKey:@"inputBrightness"];
            break;
        }
        case DoCoFilterStrength_Weak:{
            [filter setValue:[NSNumber numberWithFloat:0.125] forKey:@"inputBrightness"];
            break;
        }
        default:
            break;
    }
    [filter setValue:image forKey:kCIInputImageKey];
    outputImage = filter.outputImage;
    return outputImage;
}
//黑白滤镜
-(CIImage*)filtMonoWithImage:(CIImage*)image Option:(NSDictionary*)option{
    CIImage* outputImage;
    CIFilter* filter;
    filter = [CIFilter filterWithName:@"CIColorMonochrome"];
    [filter setValue:image forKey:kCIInputImageKey];
    outputImage = filter.outputImage;
    return outputImage;
}

-(NSArray*)faceDetectWithImage:(CIImage*)image{
    if (!_detector) {
        _detector = [CIDetector detectorOfType:CIDetectorTypeFace context:[CIContext contextWithOptions:nil] options:@{CIDetectorAccuracy : CIDetectorAccuracyLow, CIDetectorTracking:[NSNumber numberWithBool:YES]}];
    }
    NSArray* faces = [_detector featuresInImage:image];
    
    return faces;
}

-(id)copy{
    DoCoFilterTool* tool = [[DoCoFilterTool alloc] initWithFilterType:self.type Stength:self.strength];
    return tool;
}

@end
