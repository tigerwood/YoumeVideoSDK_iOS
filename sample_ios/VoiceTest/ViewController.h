//
//  ViewController.h
//  VoiceTest
//
//  Created by kilo on 16/7/12.
//  Copyright © 2016年 kilo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VoiceEngineCallback.h"
#import <AVFoundation/AVFoundation.h>
#import "CameraCaptureDemo.h"
#import "AudioQueuePlay.h"
#import "ParamSetting.h"
#import "AVCapture.h"
#import "ExternalCapture.h"
#import "InnerCapture.h"

@interface ViewController : UIViewController<VoiceEngineCallback,  IAudioRecordDelegate >
{
    NSString *mChannelID;
    NSString *mLocalUserId;
    NSString *mTips;
    int mMode;
    bool mIsTestServer;
    bool mCameraEnable;
    bool mInputVideoEnable;
    int mCurMixCount;
    
    bool mUseTcpMode;

    BOOL  enterdRoom;
    
    int renderMaxWidth;
    int renderMaxHeight;
    
    bool m_bUseExternalCapture ;
    id<AVCapture> m_capture;
    
    
   
@public
    ParamSetting* params;
}

+ (ViewController*) instance;
-(void)youmeEventLeavedAllWithErrCode:(NSNumber*)iErrorCodeNum  roomid:(NSString *)roomid param:(NSString*)param ;
- (void)handleInitEvent:(YouMeEvent_t)eventType errcode:(YouMeErrorCode_t)iErrorCode;
- (void)onYouMeEvent:(YouMeEvent_t)eventType errcode:(YouMeErrorCode_t)iErrorCode roomid:(NSString *)roomid param:(NSString*)param;

- (void)onPcmDataRemote: (int)channelNum samplingRateHz:(int)samplingRateHz bytesPerSample:(int)bytesPerSample data:(void*) data dataSizeInByte:(int)dataSizeInByte;
- (void)onPcmDataRecord: (int)channelNum samplingRateHz:(int)samplingRateHz bytesPerSample:(int)bytesPerSample data:(void*) data dataSizeInByte:(int)dataSizeInByte;
- (void)onPcmDataMix: (int)channelNum samplingRateHz:(int)samplingRateHz bytesPerSample:(int)bytesPerSample data:(void*) data dataSizeInByte:(int)dataSizeInByte;

- (void)onAudioFrameCallback: (NSString*)userId data:(void*) data len:(int)len timestamp:(uint64_t)timestamp;
- (void)onAudioFrameMixedCallback: (void*)data len:(int)len timestamp:(uint64_t)timestamp;

- (void)onVideoFrameCallback: (NSString*)userId data:(void*) data len:(int)len width:(int)width height:(int)height fmt:(int)fmt timestamp:(uint64_t)timestamp;
- (void)onVideoFrameMixedCallback: (void*) data len:(int)len width:(int)width height:(int)height fmt:(int)fmt timestamp:(uint64_t)timestamp;
- (void)onVideoFrameCallbackForGLES:(NSString*)userId  pixelBuffer:(CVPixelBufferRef)pixelBuffer timestamp:(uint64_t)timestamp;
- (void)onVideoFrameMixedCallbackForGLES:(CVPixelBufferRef)pixelBuffer timestamp:(uint64_t)timestamp;

- (void) OnRecordData:(AudioQueueBufferRef)recordBuffer;

@property (weak, nonatomic) IBOutlet UIButton *buttonSpeaker;
@property (weak, nonatomic) IBOutlet UIButton *buttonJoinChannel;
@property (weak, nonatomic) IBOutlet UIButton *btnSetTcpMode;
@property (weak, nonatomic) IBOutlet UIButton *btnOpenCamera;
@property (weak, nonatomic) IBOutlet UIButton *btnMic;

@property (weak, nonatomic) IBOutlet UILabel *labelVersion;
@property (weak, nonatomic) IBOutlet UILabel *labelCaptureMode;
@property (weak, nonatomic) IBOutlet UITextField *tfRoomID;
@property (weak, nonatomic) IBOutlet UITextField *tfToken;
@property (weak, nonatomic) IBOutlet UITextField *tfTips;
@property (weak, nonatomic) IBOutlet UILabel *tfavTips;

@property (weak, nonatomic) IBOutlet UILabel *labelDelay;

@property (retain, nonatomic) IBOutlet UITextField *localUserId;

@property (weak, nonatomic) IBOutlet   UIView  *videoResolutionView;

- (IBAction)onClickButtonSpeaker:(id)sender;

- (IBAction)onClickButtonHost:(id)sender;

- (IBAction)onClickButtonSetTcpMode:(id)sender;



//- (IBAction)onClickSwitchServer:(id)sender;

- (IBAction)onClickButtonOpenVideoEncoder:(id)sender;

- (IBAction)onClickButtonOpenMic:(id)sender;
- (IBAction)onClickButtonAddMixing:(id)sender;
- (IBAction)onClickButtonRemoveMixing:(id)sender;

- (IBAction)onClickParam:(id)sender;

- (IBAction)onClickButtonPlayFirstVideo:(id)sender;
- (IBAction)onClickButtonPlaySecondVideo:(id)sender;

@property (atomic, assign) BOOL mBInitOK;
@property (atomic, assign) BOOL mBInRoom;

@property (nonatomic, retain) UILabel *labelState;
@property (weak, nonatomic) IBOutlet UIButton *buttonCamera;

//- (void)createControl;
//- (AVCaptureDevice *)getFrontCamera;
- (void)startVideoCapture;
- (void)stopVideoCapture;

- (void) startRecord;
-  (void) stopRecord;


@end

static ViewController *sharedInstance;


