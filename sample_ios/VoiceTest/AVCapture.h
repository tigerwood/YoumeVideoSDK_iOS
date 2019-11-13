//
//  AVCapture.h
//  YmTalkTestRef
//
//  Created by pinky on 2018/9/14.
//  Copyright © 2018年 Youme. All rights reserved.
//

#ifndef AVCapture_h
#define AVCapture_h

#import "AVCapture.h"

@protocol AVCapture

//开关摄像头
-(void) startVideoCapture;
-(void) stopVideoCapture;
//切换摄像头
-(void) switchCamera;

-(void)setVideoFps:(int)fps;

//开关麦克风
-(void) startRecord;
-(void) stopRecord;

-(Boolean) isRecording;

-(void)onPause;
-(void)onResume;

@end


#endif /* AVCapture_h */
