//
//  DockController.m
//  Doco
//
//  Created by developer on 15/4/14.
//  Copyright (c) 2015年 developer. All rights reserved.
//

#import "DockController.h"
#import "Dock.h"


@interface DockController () <DockDelegate>
@end

@implementation DockController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor blackColor]];
        
    //1.添加Dock
    [self addDock];
}

#pragma mark 初始化Dock
- (void)addDock
{
    Dock *dock = [[Dock alloc] init];
    dock.frame = CGRectMake(0, DEVICE_SIZE.height - kDockHeight, DEVICE_SIZE.width, kDockHeight);
    dock.delegate = self;
    [self.view addSubview:dock];
    _dock = dock;
}

#pragma mark dock的代理方法
- (void)dock:(Dock *)dock itemSelectedFrom:(NSInteger)from to:(NSInteger)to
{
    if ( to < 0 || to >= self.childViewControllers.count ) return;
    
    //0.移除旧控制器的view
    UIViewController * oldViewController = self.childViewControllers[from];
    //从父控制器中移除（没有消失，只是不显示，他一直存在于MainController中）
    [oldViewController.view removeFromSuperview];
        
    //1.取出即将显示的控制器
    UIViewController * newViewController= self.childViewControllers[to];
    CGFloat width = DEVICE_SIZE.width;
    CGFloat height = DEVICE_SIZE.height - kDockHeight;
    newViewController.view.frame = CGRectMake(0, 0, width, height);
    
    //2.添加新控制器的view到MainController上面
    [self.view addSubview:newViewController.view];
        
    _selectedController = newViewController;
    
}


#pragma mark Memory management
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}
@end
