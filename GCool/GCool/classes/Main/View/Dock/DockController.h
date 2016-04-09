//
//  DockController.h
//  Doco
//
//  Created by developer on 15/4/14.
//  Copyright (c) 2015年 developer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Dock.h"
@interface DockController : UIViewController
{
    Dock *_dock;
}
@property (nonatomic, readonly) UIViewController *selectedController;
- (void)dock:(Dock *)dock itemSelectedFrom:(NSInteger)from to:(NSInteger)to;
@end