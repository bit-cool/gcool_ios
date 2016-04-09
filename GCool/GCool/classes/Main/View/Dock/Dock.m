//
//  Dock.m
//  Doco
//
//  Created by developer on 15/4/14.
//  Copyright (c) 2015年 developer. All rights reserved.
//


#import "Dock.h"
#import "DockItem.h"

@interface Dock()

@end

@implementation Dock

#pragma mark 添加一个条目（选项卡）
- (void)addItemWithIcon:(NSString *)icon selectedIcon:(NSString *)selected title:(NSString *)title
{
    //1.创建item
    DockItem *item = [[DockItem alloc] init];
    [item setTitle:title forState:UIControlStateNormal];//文字
    [item setTitleColor:kDockItemNormalColor forState:UIControlStateNormal]; //文字颜色
    [item setTitleColor:kDockItemSelectColor forState:UIControlStateSelected]; //选中时文字颜色
    [item setImage:[UIImage imageNamed:icon] forState:UIControlStateNormal];//图标
    [item setImage:[UIImage imageNamed:selected] forState:UIControlStateSelected];// 选中的图标
    //监听item的点击
    [item addTarget:self action:@selector(itemClick:) forControlEvents:UIControlEventTouchDown];
    
    //2.添加item
    [self addSubview:item];
    
    //3.调整item的frame
    NSUInteger count = self.subviews.count;
//    if ( count == 1 ){
//        [self itemClick:item];
//    }
    
    CGFloat height = self.frame.size.height;
    CGFloat width = DEVICE_SIZE.width / kDockItemCount;
    for (NSInteger i = 0; i<count; i++)
    {
        DockItem *dockItem = self.subviews[i];
        dockItem.tag = i; // 绑定标记
        dockItem.frame = CGRectMake(width * i, 0, width, height);
    }
    
    [self itemClick:item];

}

#pragma mark 监听item点击
- (void)itemClick:(DockItem *)item
{
    //0.通知代理
    if ([_delegate respondsToSelector:@selector(dock:itemSelectedFrom:to:)]) {
        [_delegate dock:self itemSelectedFrom:_selectedItem.tag to:item.tag];
    }
    
    //1.取消选中当前选中的item
    _selectedItem.selected = NO;
    
    //2.选中点击的item
    item.selected = YES;
    
    //3.赋值
    _selectedItem = item;
    
    //4.
    _selectedIndex = _selectedItem.tag;
}
@end
