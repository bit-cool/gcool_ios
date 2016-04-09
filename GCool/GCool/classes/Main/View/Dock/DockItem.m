//
//  DockItem.m
//  Doco
//
//  Created by developer on 15/4/14.
//  Copyright (c) 2015年 developer. All rights reserved.
//

#import "DockItem.h"

#define kDockItemWidth 29
//title占的比例
#define kTitleRatio 0.3

@implementation DockItem

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self){
        //1.文字居中
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        //2.文字大小
        self.titleLabel.font = [UIFont systemFontOfSize:12];
        
        //3.图片的内容模式
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        //4.设置背景
        [self setBackgroundImage:[UIImage imageNamed:@"dock_btn_bg_normal.png"] forState:UIControlStateNormal];
        [self setBackgroundImage:[UIImage imageNamed:@"dock_btn_bg_selected.png"] forState:UIControlStateSelected];
    }
    return self;
}

#pragma mark 覆盖父类在highlighted时的所有操作
- (void)setHighlighted:(BOOL)highlighted
{
    //[super setHighlighted:<#highlighted#>];
    //重写setHighlighted方法，使长按不触发父类的动作（变灰）
   
}

#pragma mark 调整内部ImageView的frame
- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
    CGFloat imageX = (contentRect.size.width - kDockItemWidth)/2;
    CGFloat imageY = contentRect.size.height * 0.1;
    CGFloat imageWidth = kDockItemWidth;
    CGFloat imageHeight = contentRect.size.height * 0.6;
    return CGRectMake(imageX, imageY, imageWidth, imageHeight);
}

#pragma mark 调整内部UILabel的frame
- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    CGFloat titleX = 0;
    CGFloat titleHeight = contentRect.size.height * kTitleRatio;
    CGFloat titleY = contentRect.size.height - titleHeight - 3;
    CGFloat titleWidth = contentRect.size.width;
    return CGRectMake(titleX, titleY, titleWidth, titleHeight);
}
@end
