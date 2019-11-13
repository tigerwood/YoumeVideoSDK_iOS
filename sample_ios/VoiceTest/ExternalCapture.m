//
//  ExternalCapture.m
//  YmTalkTest
//
//  Created by pinky on 2018/9/14.
//  Copyright © 2018年 Youme. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Foundation/Foundation.h>
#import "YMVoiceService.h"
#import "ExternalCapture.h"
#import "CameraCaptureDemo.h"
#import "AudioQueuePlay.h"

@interface ExternalCapture ()<IAudioRecordDelegate,ICameraRecordDelegate>
{
    bool m_InRecord;
    AudioRecordStream* record;
}
@property (retain, nonatomic) CameraCaptureDemo  *cameraCapture;
@end

@implementation ExternalCapture

-(instancetype)init
{
    self = [super init]; //用于初始化父类
    if (self) {
        self.cameraCapture = [[CameraCaptureDemo alloc] init];
        self.cameraCapture.cameraDataDelegate = self;
        
        m_InRecord = false;
        
        record = [[AudioRecordStream alloc] init ];
        record.recrodDelegate = self;
    }
    
    return self;
}

-(void) startVideoCapture
{
   [_cameraCapture startVideoCapture];
}

-(void) stopVideoCapture
{
    [_cameraCapture stopVideoCapture];
    [[YMVoiceService getInstance] stopInputVideoFrame];
}

-(void) switchCamera
{
    [_cameraCapture switchCamere];
}

-(void)setVideoFps:(int)fps
{
    [_cameraCapture setFps: fps ];
}

-(void) startRecord
{
    if( m_InRecord == false ){
        m_InRecord = true;
        [ record Start];
    }
}

-(void) stopRecord
{
    if( m_InRecord == true ){
        [ record Stop];
        m_InRecord = false;
    }
}

-(Boolean) isRecording
{
    return m_InRecord;
}

////////////////////////////外部采集，采集的数据处理//////////////////////////////////////////////////////////////
#pragma mark - 录音回调
- (void) OnRecordData:(AudioBufferList *)recordBuffer
{
    UInt64 recordTime = [[NSDate date] timeIntervalSince1970];
    AudioBuffer buffer = recordBuffer->mBuffers[0];
    [[YMVoiceService getInstance] inputAudioFrame:buffer.mData Len:buffer.mDataByteSize Timestamp:recordTime ];
}


#pragma mark - 摄像头数据回调
- (void) OnCameraCaptureData:(void*) buffer Len:(int)bufferSize Width:(int)width Height:(int)height Fmt:(int)Fmt Rotation:(int)rotationDegree Mirror:(int)mirror Timestamp:(uint64_t)recordTime{
    //if (mInputVideoEnable) {
    [[YMVoiceService getInstance] inputVideoFrame:buffer Len:bufferSize Width:width Height:height Fmt:Fmt Rotation:rotationDegree Mirror:mirror Timestamp:recordTime];
    //}
}

- (void) OnCameraCaptureData:(CVPixelBufferRef) pixelbuffer Mirror:(int)mirror Timestamp:(uint64_t)recordTime;
{
    [[YMVoiceService getInstance] inputPixelBuffer:pixelbuffer Width:0 Height:0 Fmt:0 Rotation:0 Mirror:mirror Timestamp:recordTime];
}

-(void)onPause
{
    if( m_InRecord )
    {
        [self stopRecord];
    }
}
-(void)onResume
{
    if( m_InRecord )
    {
        [self startRecord];
    }
}

@end
