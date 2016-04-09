//
//  CommonNavController.m
//  Doco
//
//  Created by developer on 15/4/14.
//  Copyright (c) 2015年 developer. All rights reserved.
//

#import "CommonNavController.h"

@implementation CommonNavController
- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    self.view.backgroundColor = [UIColor whiteColor];
    
    //1.appearance方法返回一个导航栏的外观对象
    //修改了这个外观对象，相当于修改了整个项目中的外观
//    UINavigationBar *bar = [UINavigationBar appearance];
//    bar.hidden = YES;
    self.navigationBarHidden = YES;

    //5.设置状态栏样式
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
    
    [UIApplication sharedApplication].statusBarOrientation = UIInterfaceOrientationPortrait;
    
//    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft animated:YES];
    
    
    //滑动返回
    __weak typeof (self) weakSelf = self;
    if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.interactivePopGestureRecognizer.delegate = weakSelf;
    }
    
}

////设置状态栏不透明，并与应用分离
//- (void)viewWillAppear:(BOOL)animated
//{
//    //判断当前设备的ios版本
//    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
//    {
//        CGRect viewBounds = [self.view bounds];
//        viewBounds.origin.y = 0;
//        viewBounds.size.height = viewBounds.size.height;
//        self.view.frame = viewBounds;
//    }
//    
//}


//- (BOOL)prefersStatusBarHidden
//{
//    if([self.topViewController isKindOfClass:[VideoDetailController class]]){
//        return self.topViewController.prefersStatusBarHidden;
//    }
//    return NO;
//}





#pragma mark Memory management
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
