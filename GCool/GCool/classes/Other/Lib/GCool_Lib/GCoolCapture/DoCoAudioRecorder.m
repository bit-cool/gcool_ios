//
//  DoCoAudioRecorder.m
//  doco_ios_app
//
//  Created by developer on 15/11/25.
//  Copyright © 2015年 developer. All rights reserved.
//

#import "DoCoAudioRecorder.h"
@interface DoCoAudioRecorder()

@property (nonatomic,strong) AVAudioRecorder* recorder;
@property (nonatomic,strong) AVAudioSession* session;

@end
@implementation DoCoAudioRecorder
-(instancetype)initWithURL:(NSURL *)outputURL{
    self = [super init];
    if (self) {
        _outputURL = outputURL;
        NSError* error;
        _session = [AVAudioSession sharedInstance];
        [_session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
        [_session setActive:YES error:&error];
        
        NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] init];
        //1 ID号
        [recordSettings setObject:[NSNumber numberWithInt: kAudioFormatLinearPCM] forKey: AVFormatIDKey];
        //2 采样率
        [recordSettings setObject:[NSNumber numberWithFloat:44100] forKey: AVSampleRateKey];
        //3 通道的数目
        [recordSettings setObject:[NSNumber numberWithInt:2]forKey:AVNumberOfChannelsKey];
        //4 采样位数  默认 16
        [recordSettings setObject:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
        //5 是否使用BigEndian储存数据
        [recordSettings setObject:[NSNumber numberWithBool:NO]forKey:AVLinearPCMIsBigEndianKey];
        //6 采样信号是整数还是浮点数
        [recordSettings setObject:[NSNumber numberWithBool:NO]forKey:AVLinearPCMIsFloatKey];

        _recorder = [[AVAudioRecorder alloc] initWithURL:_outputURL settings:recordSettings error:&error];
        
        if (error) {
            MyLog(@"%@",error);
        }
    }
    return self;
}

-(void)startRecord{//开始录音
    if([_recorder prepareToRecord]){
        [_recorder record];
        MyLog(@"开始录音");
    }else{
        MyLog(@"recorder还没准备好");
    }
}

-(void)endRecord{//结束录音
    [_recorder stop];
}

-(void)setDelegate:(id<AVAudioRecorderDelegate>)delegate{//设置AVAudioRecorderDelegate
    _recorder.delegate = _delegate;
}

@end
