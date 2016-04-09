//
//  Dock.h
//  Doco
//
//  Created by developer on 15/4/14.
//  Copyright (c) 2015年 developer. All rights reserved.
//  底部的Dock

#import <UIKit/UIKit.h>
@class DockItem;
@class Dock;

@protocol DockDelegate <NSObject>
@optional  //声明的方法不用实现
- (void)dock:(Dock *)dock itemSelectedFrom:(NSInteger)from to:(NSInteger)to;

@end

@interface Dock : UIView

//添加一个条目（选项卡）
- (void)addItemWithIcon:(NSString *)icon selectedIcon:(NSString *)selected title:(NSString *)title;

//代理
@property (nonatomic, weak) id<DockDelegate> delegate;
@property(nonatomic,strong)DockItem *selectedItem;
@property (nonatomic, assign) NSInteger selectedIndex;

@end

