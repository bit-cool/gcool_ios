//
//  DoCoAudioRecorder.h
//  doco_ios_app
//
//  Created by developer on 15/11/25.
//  Copyright © 2015年 developer. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface DoCoAudioRecorder : NSObject

@property (nonatomic,strong) NSURL* outputURL;
@property (nonatomic,strong) id<AVAudioRecorderDelegate> delegate;

-(instancetype)initWithURL:(NSURL*)outputURL;
-(void)startRecord;
-(void)endRecord;

@end
