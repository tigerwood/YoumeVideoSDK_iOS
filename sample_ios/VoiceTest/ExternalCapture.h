//
//  ExternalCpature.h
//  YmTalkTestRef
//
//  Created by pinky on 2018/9/14.
//  Copyright © 2018年 Youme. All rights reserved.
//

#ifndef ExternalCpature_h
#define ExternalCpature_h

#import <Foundation/Foundation.h>
#import "AVCapture.h"

@interface ExternalCapture : NSObject<AVCapture>
-(void) startVideoCapture;
-(void) stopVideoCapture;
-(void) switchCamera;

-(void)setVideoFps:(int)fps;

-(void) startRecord;
-(void) stopRecord;

-(Boolean) isRecording;

-(void)onPause;
-(void)onResume;
@end
#endif /* ExternalCpature_h */
