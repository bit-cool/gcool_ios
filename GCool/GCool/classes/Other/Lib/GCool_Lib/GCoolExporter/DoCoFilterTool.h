//
//  DoCoFilterTool.h
//  doco_ios_app
//
//  Created by developer on 15/11/18.
//  Copyright © 2015年 developer. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
    DoCoFilterType_None,
    DoCoFilterType_OldPhoto,
    DoCoFilterType_Adjustment,
    DoCoFilterType_Light,
    DoCoFilterType_MonoChrome,
}DoCoFilterType;

typedef enum{
    DoCoFilterStrength_Strong,
    DoCoFilterStrength_Weak,
    DoCoFilterStrength_None,
}DoCoFilterStrength;

@interface DoCoFilterTool : NSObject

@property (nonatomic) DoCoFilterType type;
@property (nonatomic) DoCoFilterStrength strength;

//初始化函数 type为滤镜类型 strength为滤镜效果强度
-(instancetype)initWithFilterType:(DoCoFilterType)type Stength:(DoCoFilterStrength)strength;
//公有滤镜加载接口
-(CIImage*)filtImage:(CIImage*)inputImage WithOption:(NSDictionary*)option;
@end
