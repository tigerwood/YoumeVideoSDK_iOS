//
//  InnerCapture.m
//  YmTalkTest
//
//  Created by pinky on 2018/9/14.
//  Copyright © 2018年 Youme. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YMVoiceService.h"
#import "InnerCapture.h"

@implementation InnerCapture

-(void) startVideoCapture
{
    [[YMVoiceService getInstance] startCapture];
}

-(void) stopVideoCapture
{
    [[YMVoiceService getInstance] stopCapture];
}

-(void) switchCamera
{
    [[YMVoiceService getInstance] switchCamera];
}

-(void)setVideoFps:(int)fps
{
    [[YMVoiceService getInstance] setVideoFps:fps];
}

-(void) startRecord
{
     [[YMVoiceService getInstance] setMicrophoneMute: false];
}

-(void) stopRecord
{
   [[YMVoiceService getInstance] setMicrophoneMute: true];
}

-(Boolean) isRecording
{
    return ![[YMVoiceService getInstance] getMicrophoneMute];
}

-(void)onPause
{
    //内部采集在pauseChannel里处理
}
-(void)onResume
{
    //内部采集在resumeChannel里处理
}

@end
