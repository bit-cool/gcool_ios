//
//  ViewController.m
//  GCool
//
//  Created by developer on 16/4/6.
//  Copyright © 2016年 developer. All rights reserved.
//

#import "MainController.h"
#import "DockItem.h"
#import "CommonNavController.h"

#import "MyController.h"
#import "AMDController.h"
#import "RankController.h"
#import "CreateController.h"
#import "FoundController.h"

@interface MainController ()<DockDelegate,UINavigationControllerDelegate>

@end

@implementation MainController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self addAllChildControllers];
    [self addDockItems];
}

#pragma mark 初始化所有的子控制器
- (void)addAllChildControllers{
    
    //添加Create控制器
    
    //添加Rank控制器
    RankController *rank = [[RankController alloc]init];
    CommonNavController *rankNav = [[CommonNavController alloc]initWithRootViewController:rank];
    rankNav.delegate = self;
    [self addChildViewController:rankNav];
    
    //添加我的控制器
    MyController *my = [[MyController alloc] init];
    CommonNavController *myNav = [[CommonNavController alloc] initWithRootViewController:my];
    myNav.delegate = self;
    [self addChildViewController:myNav];
    
    

    
}

-(void)addDockItems{
    //Dock里面填充内容
    [_dock addItemWithIcon:@"plaza_gray" selectedIcon:@"plaza_blue" title:@"拍摄"];
    //    [_dock addItemWithIcon:@"friend_gray" selectedIcon:@"friend_blue" title:@"朋友"];
    [_dock addItemWithIcon:@"plaza_gray" selectedIcon:@"plaza_blue" title:@"排行榜"];
    [_dock addItemWithIcon:@"plaza_gray" selectedIcon:@"plaza_blue" title:@"发现"];
    [_dock addItemWithIcon:@"plaza_gray" selectedIcon:@"plaza_blue" title:@"AMD"];
    [_dock addItemWithIcon:@"plaza_gray" selectedIcon:@"plaza_blue" title:@"我"];
    
}

-(void)dock:(Dock *)dock itemSelectedFrom:(NSInteger)from to:(NSInteger)to{
    if (from == to) {
        return;
    }
    //如果是视频制作或者个人信息
    if (to == 0) {//视频制作
        
    }else if (to == kDockItemCount - 1){//个人信息
        
    }else{
        [super dock:dock itemSelectedFrom:from to:to];
    }
    
    
    
}

//控制状态栏的隐藏
//- (BOOL)prefersStatusBarHidden
//{
//    UIViewController *VC = self.selectedController;
//    if([VC isKindOfClass:[CommonNavController class]]){
//        return VC.prefersStatusBarHidden;
//    }
//    return NO;
//}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
