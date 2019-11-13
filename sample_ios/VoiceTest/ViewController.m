//
//  ViewController.m
//  VoiceTest
//
//  Created by kilo on 16/7/12.
//  Copyright © 2016年 kilo. All rights reserved.
//

#import "ViewController.h"
#import "YMVoiceService.h"
#import "LFLiveKit.h"
#import "libyuv.h"
#import <Bugly/Bugly.h>
#import "YMTalkUtils.h"
#import "ParamViewController.h"
#import "NSObject+SelectorOnMainThreadMutipleObjects.h"
#import "OpenGLESView.h"

#define video_view_max   3

@interface UserViewInfo : NSObject
{
@public
    NSString* userId;
    UIView* glView;
}
@end
@implementation UserViewInfo
@end

//为了收到ScrollView里的点击事件
@implementation UIScrollView (UITouch)

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    //    [[self nextResponder] touchesBegan:touches withEvent:event];
    [super touchesBegan:touches withEvent:event];
}
@end


@interface ViewController () <LFLiveSessionDelegate>
{
    Boolean m_bChoosedMode;
}

// OpenGL ES
@property (nonatomic , strong)  UIView* mGL20ViewFullScreen;

@property (atomic,strong) NSMutableArray *userList;
@property (atomic,strong) NSMutableArray *viewList;
@property (retain, nonatomic) IBOutlet UIView *videoGroup;

@property (nonatomic, strong) LFLiveDebug *debugInfo;
@property (nonatomic, strong) LFLiveSession *session;

@property (nonatomic, strong) NSString* strLocalUserID;
@property (nonatomic, strong) NSString* strFullUserID;
@property (nonatomic, strong) NSString* strMixUserID;

@property (nonatomic,assign) BOOL startPush;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *layoutVideoViewHeight;

//默认内部采集模式
@property (nonatomic,assign) Boolean m_bExternalCaptureMode;


@end

@implementation ViewController

+ (ViewController*) instance
{
    return sharedInstance;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
    }
    m_bChoosedMode = false;
    self.m_bExternalCaptureMode = false;
    mIsTestServer = false;
    
    return self;
}


-(void)initParam {
    
    //默认参数
    params = [ParamSetting defaultParamSetting];
    
    enterdRoom = false;
    self.userList = [NSMutableArray new];
    self.viewList = [NSMutableArray new];
    self.startPush = NO;
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /***   默认分辨率368 ＊ 640  音频：44.1 iphone6以上48  双声道  方向竖屏 ***/
    LFLiveVideoConfiguration *videoConfiguration = [LFLiveVideoConfiguration defaultConfiguration];

    LFLiveAudioConfiguration *audioConfig = [LFLiveAudioConfiguration defaultConfiguration];
    
    _session = [[LFLiveSession alloc] initWithAudioConfiguration:audioConfig videoConfiguration:videoConfiguration captureType:LFLiveInputMaskAll];
    _session.delegate = self;
    _session.showDebugInfo = NO;
    _session.preView = nil;
    
    mChannelID = @"752015105";
    
    int value = (arc4random() % 1000) + 1;
    mLocalUserId = [NSString stringWithFormat:@"user_%d",value];
    
    mMode = 0;
    mCameraEnable = false;
    
    mUseTcpMode = false;
    
    self.mBInRoom = false;
    self.mBInitOK = false;
}

-(void)setExternalModeAndServer:(Boolean) bUseExternal test:(Boolean)test
{
    self.m_bExternalCaptureMode = bUseExternal;
    mIsTestServer = test ;
    //更新version显示,加上test标识
    NSString* testServer = mIsTestServer?@"t":@"n";
    NSString* strVersion = [NSString stringWithFormat:@"ver:%@_%@", [YMTalkUtils strVersionFromInt:[[YMVoiceService getInstance] getSDKVersion]], testServer];
    _labelVersion.text = strVersion;
    
    _labelCaptureMode.text = m_bUseExternalCapture ? @"外部采集":@"内部采集";
    
    [self YMSDKSetup];
}

-(void)showModeChoose
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"选择Demo" message:@"选择采集模式和是否测试服" preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* externalAction = [UIAlertAction actionWithTitle:@"外部采集" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self setExternalModeAndServer:true test:false];
    }];
    
    UIAlertAction* innerAction = [UIAlertAction actionWithTitle:@"内部采集" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self setExternalModeAndServer:false  test:false];
    }];
    
    UIAlertAction* innerTestAction = [UIAlertAction actionWithTitle:@"内部采集-测试服" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self setExternalModeAndServer:false  test:true];
    }];
    
    UIAlertAction* externalTestAction = [UIAlertAction actionWithTitle:@"外部采集-测试服" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self setExternalModeAndServer:true  test:true];
    }];
    
    [alert addAction: innerAction];
    [alert addAction: externalAction];
    [alert addAction: innerTestAction];
    [alert addAction: externalTestAction];
    
    [self presentViewController: alert  animated:YES completion:nil];
}


//2 主播扬声器没模式,5 离开房间,6 切换服务器
const int ANCHOR_SPEAKER_MODE = 2;
const int NOT_INROOM_MODE = 5;

-(void)YMSDKSetup {
    //默认测服
    if( mIsTestServer )
    {
        [[YMVoiceService getInstance]setTestServer:mIsTestServer];
    }
    
    //========================== 设置为外部输入音视频的模式 =========================================================
    if( self.m_bExternalCaptureMode )
    {
        [[YMVoiceService getInstance] setExternalInputMode:true];
        // 设置外部输入的采样率为48k
        [[YMVoiceService getInstance] setExternalInputSampleRate:SAMPLE_RATE_48 mixedCallbackSampleRate:SAMPLE_RATE_48];
        m_capture = [[ExternalCapture alloc] init];
    }
    else{
        m_capture = [[InnerCapture alloc] init];
    }
    
    
    //========================== 设置Log等级 =========================================================
    [[YMVoiceService getInstance] setLogLevelforConsole:LOG_INFO forFile:LOG_INFO];
    //========================== 设置用户自定义Log路径 =========================================================
    //[[YMVoiceService getInstance] setUserLogPath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"ymrtc_userlog.txt"]];
    //========================== 设置音视频质量统计数据的回调频率 =========================================================
    [[YMVoiceService getInstance] setAVStatisticInterval: 5000 ];
    //========================== 初始化YoumeService =========================================================
    [[YMVoiceService getInstance] initSDK: self appkey:strAppKey
                                appSecret:strAppSecret
                                 regionId:RTC_CN_SERVER
                         serverRegionName:@"cn" ];
    
    // 设置视频无渲染帧超时等待时间，单位毫秒
    [[YMVoiceService getInstance] setVideoNoFrameTimeout: 5000];
    //========================== END初始化YoumeService ==========================================================
}

- (void)viewDidLoad {
    [super viewDidLoad];
    sharedInstance = self;
    [self initParam];
    
    [self configUI];
    
    //处理点击视频放大
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleClickTap:)]];
    
    // 监听前后台切换暂停
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeYMVoiceService:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseYMVoiceService:) name:UIApplicationWillResignActiveNotification object:nil];
}

-(void)viewDidAppear:(BOOL)animated
{

    [super viewWillAppear:animated];
    //进入界面，先选择是外部采集模式，还是内部采集模式,还是是否测试服
    if( !m_bChoosedMode )
    {
        [self showModeChoose];
        m_bChoosedMode = true ;
    }
}


////////////////////////////////ui 更新////////////////////////////////
-(void)configUI {
    //==========================     Demo的简单UI      ==========================================================
    //获取版本号显示到相应标签
    NSString* strVersion = [NSString stringWithFormat:@"ver:%@", [YMTalkUtils strVersionFromInt:[[YMVoiceService getInstance] getSDKVersion]]];
    _labelVersion.text = strVersion;
    
    mTips = @"No tips Now!";
    
    _tfTips.text = mTips;
    _tfTips.enabled = false;
    _tfRoomID.text = mChannelID;
    _localUserId.text = mLocalUserId;
    
    _tfavTips.text = @"avTips";
    _tfTips.text = @"";
    
    _buttonSpeaker.enabled = false;
    
    //==========================     Demo的简单UI      ==========================================================
    
    //==========================      创建渲染组件      ==========================================================
    int renderViewMargin = 5;
    CGRect r = [[UIScreen mainScreen]bounds];
    renderMaxWidth =  ( r.size.width - renderViewMargin * 3 ) / 3 ;
//    renderMaxHeight = ( r.size.height - renderViewMargin * 3 ) / 2  ;
    
    //最大的框设置成方形的把，方便后面的判断
    //renderMaxWidth = renderMaxWidth < renderMaxHeight ? renderMaxWidth : renderMaxHeight;
    renderMaxHeight = renderMaxWidth*16/9.f;
    
    self.videoGroup.layer.borderWidth = 1;
    self.videoGroup.layer.borderColor = [[UIColor blackColor] CGColor];
    
    int videoGroupHeight =  renderMaxHeight * 2  + renderViewMargin * 3 ;
    self.layoutVideoViewHeight.constant = videoGroupHeight;
    
    int renderViewHeight = renderMaxHeight;
    int renderViewWidth = renderMaxWidth;
    
    for (int i = 0; i < video_view_max; i++) {
        UIView* view = [[UIView alloc] initWithFrame:CGRectMake(i*renderViewMargin + i*renderViewWidth, renderViewMargin, renderViewWidth, renderViewHeight)];
        [view setBackgroundColor:[UIColor blackColor]];
        [self.videoGroup addSubview:view];
        UserViewInfo *info = [UserViewInfo alloc];
        info->glView = view;
        [self.viewList addObject: info];
    }
    
    //全屏显示的view
    self.mGL20ViewFullScreen =  [[UIView alloc] initWithFrame:CGRectMake(0, 0, r.size.width, r.size.height)];
    [self.view addSubview:self.mGL20ViewFullScreen];
    self.mGL20ViewFullScreen.hidden = true ;
    
    //==========================      创建渲染组件 End   ==========================================================
}

//sdk inited成功，刷新界面
-(void)initedUI
{
    [self.buttonJoinChannel setEnabled:YES];
}

//sdk 开始加入房间，刷新界面
-(void)joiningUI
{
    [self.buttonJoinChannel setTitle:@"进入频道中" forState:UIControlStateDisabled];
    [self.buttonJoinChannel setEnabled:NO];
    [self.buttonSpeaker setEnabled:NO];
    [self.btnMic setEnabled:NO];
    [self.btnOpenCamera setEnabled:NO];
}
//sdk 加入房间成功，刷新界面
-(void)joinedUI
{
    [self.buttonJoinChannel setTitle:@"离开频道" forState:UIControlStateNormal];
    [self.buttonJoinChannel setEnabled:YES];
    [self.buttonSpeaker setEnabled:YES];
    [self.btnMic setEnabled:YES];
    [self.btnOpenCamera setEnabled:YES];
}
//sdk 开始离开房间，刷新界面
-(void)leavingUI
{
    [self.buttonJoinChannel setTitle:@"离开频道中" forState:UIControlStateDisabled];
    [self.buttonJoinChannel setEnabled:NO];
    [self.buttonSpeaker setEnabled:NO];
    [self.btnMic setEnabled:NO];
    [self.btnOpenCamera setEnabled:NO];
}

-(void)leavedUI
{
    [self refreshUI];
    [self.buttonSpeaker setEnabled:NO];
    [self.btnMic setEnabled:NO];
    [self.btnOpenCamera setEnabled:NO];
}

- (void)refreshUI{
    _buttonSpeaker.enabled = false;
    mCameraEnable = false;
    [_buttonSpeaker setTitle:@"关闭扬声器" forState:UIControlStateNormal];
    [self.buttonJoinChannel setTitle:@"进入频道" forState:UIControlStateNormal];
    [self.buttonJoinChannel setEnabled:YES];
    [_buttonSpeaker setTitle:@"关闭扬声器" forState:UIControlStateNormal];
    [self.btnMic setTitle:@"关闭麦克风" forState:UIControlStateNormal];
}


////////////////////////////////ui 事件处理////////////////////////////////
-(void)handleClickTap:(UITapGestureRecognizer*)gest {
    [self.view endEditing:YES];
    
    if( self.mGL20ViewFullScreen.hidden == false )
    {
        //点击放大显示的画面，缩回
        for (UserViewInfo* info in self.viewList) {
            if(info->userId && [info->userId compare:self.strFullUserID] == NSOrderedSame)
            {
                [[YMVoiceService getInstance] deleteRender:self.strFullUserID glView:nil];
                [[YMVoiceService getInstance] createRender:self.strFullUserID parentView:info->glView singleMode:YES];
                break;
            }
        }
        self.strFullUserID = nil;
        self.mGL20ViewFullScreen.hidden = YES;
    }
    else {
        //放大显示点击的画面
        CGPoint pt = [gest locationInView:self.videoGroup ];
        if( [self.videoGroup pointInside:pt  withEvent:nil ])
        {
            for (UserViewInfo* info in self.viewList) {
                if(info->userId){
                    CGPoint pt = [gest locationInView:info->glView ];
                    if( [info->glView  pointInside:pt  withEvent:nil ]){
                        [[YMVoiceService getInstance] deleteRender:info->userId glView:nil];
                        [[YMVoiceService getInstance] createRender:info->userId parentView:self.mGL20ViewFullScreen singleMode:YES];
                        self.mGL20ViewFullScreen.hidden = NO;
                        self.strFullUserID = info->userId;
                        break;
                    }
                }
            }
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)applyParam
{
    [m_capture setVideoFps: params->fps ];
    
    if( params->videoWidth >= 0 && params->videoHeight >= 0   )
    {
        [[YMVoiceService getInstance] setVideoNetResolutionWidth:params->videoWidth height:params->videoHeight];
    }
    [[YMVoiceService getInstance] setAVStatisticInterval: params->reportInterval];
    [[YMVoiceService getInstance] setVideoCodeBitrate: params->maxBitrate  minBitrate:params->minBitrate];
    [[YMVoiceService getInstance] setVideoCodeBitrateForSecond: params->maxBitrate*0.6  minBitrate:params->minBitrate*0.6];
    
    // if( params->bHighAudio ){
    //     [[YMVoiceService getInstance] setAudioQuality:HIGH_QUALITY];
    // }
    // else{
    //     [[YMVoiceService getInstance] setAudioQuality:LOW_QUALITY];
    // }
    
    if( params->bHWEnable ){
        [[YMVoiceService getInstance] setVideoHardwareCodeEnable: TRUE ];
    }
    else{
        [[YMVoiceService getInstance] setVideoHardwareCodeEnable: false ];
    }
    
    if( params->fixQuality )
    {
        [[YMVoiceService getInstance] setVBR:true];
    }
    else{
        [[YMVoiceService getInstance] setVBR:false];
    }
}

//主播扬声器模式
-(void)joinChannel{
    NSString* strUserID = _localUserId.text;
    self->mChannelID = _tfRoomID.text;
    _tfTips.text = @"正进入频道";
    
    //使用选择的参数对SDK进行设置
    [self applyParam];
    
    [[YMVoiceService getInstance] setFarendVoiceLevelCallback: params->farendLevel ];
//    [[YMVoiceService getInstance] setVideoPreDecodeCallbackEnable:true needDecodeandRender:true];
    
    NSString *str = _tfToken.text;
    [[YMVoiceService getInstance] setToken:str];
    [[YMVoiceService getInstance] setVideoNetAdjustmode:1]; // 模式 0:自动调整，1:手动调整
    [[YMVoiceService getInstance] joinChannelSingleMode:strUserID channelID:mChannelID userRole:YOUME_USER_HOST autoRecv:true];
    [[YMVoiceService getInstance] setAutoSendStatus: true ];
    enterdRoom = true;
    
}

-(void)leaveChannel
{
    _tfTips.text = @"正离开频道";
    [self.userList removeAllObjects];
    [[YMVoiceService getInstance] leaveChannelAll];
}

- (IBAction)onClickButtonSetTcpMode:(id)sender
{
    if( mMode = 0 && mMode != NOT_INROOM_MODE )
    {
        return ;
    }
    
    self->mUseTcpMode = !self->mUseTcpMode;
    [[YMVoiceService getInstance] setTCPMode: self->mUseTcpMode];
    if( self->mUseTcpMode )
    {
        [self.btnSetTcpMode setTitle:@"Tcp Mode" forState:UIControlStateNormal];
    }
    else{
        [self.btnSetTcpMode setTitle:@"Udp Mode" forState:UIControlStateNormal];
    }
    
}

//主播频道按钮处理函数
- (IBAction)onClickButtonHost:(id)sender {
    [[YMVoiceService getInstance] setDelegate:self];
    
    if(![[YMVoiceService getInstance] isInChannel:mChannelID]){
        [self joinChannel];
        [self joiningUI];
        mMode = ANCHOR_SPEAKER_MODE;
        
        [self.btnSetTcpMode setEnabled: false];
    }else{
        [self leavingUI];
        [self stopCamptureAndPush];
        [m_capture stopRecord];
        _tfavTips.text = @"";
        [self leaveChannel];
        [self.buttonJoinChannel setEnabled:NO];
        mMode = NOT_INROOM_MODE;
        [self.btnSetTcpMode setEnabled: true];
    }
    
}

- (void)resetAllRender
{
    for (UserViewInfo* info in self.viewList) {
        if(info->userId)
            info->userId = nil;
    }
    [self.userList removeAllObjects];
    
    [[YMVoiceService getInstance] deleteAllRender];
    [[YMVoiceService getInstance] removeAllOverlayVideo];
    
}

//点击空白屏幕收起编辑键盘
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    [self.view endEditing:YES];
}

- (void)onRequestRestAPI: (int)requestID iErrorCode:(YouMeErrorCode_t) iErrorCode  query:(NSString*) strQuery  result:(NSString*) strResult
{
    NSLog(@"do nothing");
}


- (void)onMemberChange:(NSString*) channelID changeList:(NSArray*) changeList isUpdate:(bool) isUpdate
{
    NSLog(@"isUpdate:%d", isUpdate);
    NSInteger count = [changeList count];
    NSLog(@"MemberChagne:%@, count:%ld",channelID, count );
    
    for( int i = 0 ; i < count ;i++ ){
        MemberChangeOC* change = [changeList objectAtIndex:i ];
        if( change.isJoin == 1 ){
            NSLog(@"%@ 进入", change.userID);
            
           
        }
        else{
            NSLog(@"%@ 离开了", change.userID );
            for (UserViewInfo * info in self.viewList) {
                if (info->userId && [info->userId compare:change.userID] == NSOrderedSame) {
                    info->userId = nil;
                    [[YMVoiceService getInstance ] deleteRender:change.userID glView:nil];
                    if(self.strMixUserID && [self.strMixUserID compare:change.userID] == 0)
                    {
                        [[YMVoiceService getInstance] removeMixOverlayVideoUserId:change.userID];
                        self.strMixUserID = nil;
                    }
                    break;
                }
            }
        }
    }
}

- (void)onPcmDataRemote: (int)channelNum samplingRateHz:(int)samplingRateHz bytesPerSample:(int)bytesPerSample data:(void*) data dataSizeInByte:(int)dataSizeInByte {
    
//    NSString *txtPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"dump_onPcmDataRemote.pcm"];
//
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    if(![fileManager fileExistsAtPath:txtPath isDirectory:FALSE]){
//        [fileManager createFileAtPath:txtPath contents:nil attributes:nil];
//    }
//    NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:txtPath];
//    [handle seekToEndOfFile];
//    [handle writeData:[NSData dataWithBytes:data length:dataSizeInByte]];
//    [handle closeFile];
    
}

- (void)onPcmDataRecord: (int)channelNum samplingRateHz:(int)samplingRateHz bytesPerSample:(int)bytesPerSample data:(void*) data dataSizeInByte:(int)dataSizeInByte {
    
    //    NSString *txtPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"dump_onPcmDataRecord.pcm"];
    //
    //    NSFileManager *fileManager = [NSFileManager defaultManager];
    //    if(![fileManager fileExistsAtPath:txtPath isDirectory:FALSE]){
    //        [fileManager createFileAtPath:txtPath contents:nil attributes:nil];
    //    }
    //    NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:txtPath];
    //    [handle seekToEndOfFile];
    //    [handle writeData:[NSData dataWithBytes:data length:dataSizeInByte]];
    //    [handle closeFile];
    
}

- (void)onPcmDataMix: (int)channelNum samplingRateHz:(int)samplingRateHz bytesPerSample:(int)bytesPerSample data:(void*) data dataSizeInByte:(int)dataSizeInByte {
    
    //    NSString *txtPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"dump_onPcmDataMix.pcm"];
    //
    //    NSFileManager *fileManager = [NSFileManager defaultManager];
    //    if(![fileManager fileExistsAtPath:txtPath isDirectory:FALSE]){
    //        [fileManager createFileAtPath:txtPath contents:nil attributes:nil];
    //    }
    //    NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:txtPath];
    //    [handle seekToEndOfFile];
    //    [handle writeData:[NSData dataWithBytes:data length:dataSizeInByte]];
    //    [handle closeFile];
    
}


- (void)onAudioFrameCallback: (NSString*)userId data:(void*) data len:(int)len timestamp:(uint64_t)timestamp {
}

- (void)onAudioFrameMixedCallback: (void*)data len:(int)len timestamp:(uint64_t)timestamp {
    // 播放
    //[record play:[NSData dataWithBytes:data length:len]];
    //推流
    if( self.startPush ){
        // Create a CM Sample Buffer
        [self.session pushAudio:[NSData dataWithBytes:data length:len]];
    }
}

- (void)onVideoFrameCallback: (NSString*)userId data:(void*) data len:(int)len width:(int)width height:(int)height fmt:(int)fmt timestamp:(uint64_t)timestamp{
}

- (void)onVideoFrameMixedCallback: (void*) data len:(int)len width:(int)width height:(int)height fmt:(int)fmt timestamp:(uint64_t)timestamp{
}
- (void)onVideoFrameCallbackForGLES:(NSString*)userId  pixelBuffer:(CVPixelBufferRef)pixelBuffer timestamp:(uint64_t)timestamp{
    
}
- (void)onVideoFrameMixedCallbackForGLES:(CVPixelBufferRef)pixelBuffer timestamp:(uint64_t)timestamp{
    size_t width =  (size_t)CVPixelBufferGetWidth(pixelBuffer);
    size_t height = (size_t)CVPixelBufferGetHeight(pixelBuffer);
}
- (void) onAVStatistic:(YouMeAVStatisticType_t)type  userID:(NSString*)userID  value:(int) value
{
    static NSString* mStrNotify = @"";
    static int64_t avNotifyTime = 0;
    
    NSTimeInterval curTime =  [[NSDate date] timeIntervalSince1970]  ;
    
    if( curTime - avNotifyTime > 2  )
    {
        mStrNotify = @"";
    }
    
    if( type == YOUME_AVS_VIDEO_CODERATE )
    {
        NSLog(@"onAVStatistic: user: %@ video code:%d", userID, value * 8 / 1000 );
    }
    
    mStrNotify = [mStrNotify stringByAppendingFormat:@"%d,%@,%d\n" , type, userID, value ];
    
    avNotifyTime = curTime;
    
    dispatch_async (dispatch_get_main_queue (), ^{
        _tfavTips.text = mStrNotify;
        
    });
}

- (void)onVideoPreDecodeDataForUser:(const char *)userId data:(const void*)data len:(int)dataSizeInByte 
{
//    NSString *txtPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"dump_predecode.h264"];
//
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    if(![fileManager fileExistsAtPath:txtPath isDirectory:FALSE]){
//        [fileManager createFileAtPath:txtPath contents:nil attributes:nil];
//    }
//    NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:txtPath];
//    
//    [handle seekToEndOfFile];
//    [handle writeData:[NSData dataWithBytes:data length:dataSizeInByte]];
//    [handle closeFile];
}


- (IBAction)onClickButtonSpeaker:(id)sender {
    if(![[YMVoiceService getInstance] getSpeakerMute]){
        [[YMVoiceService getInstance] setSpeakerMute:true];
        [_buttonSpeaker setTitle:@"启用扬声器" forState:UIControlStateNormal];
    } else {
        //开启扬声器
        [[YMVoiceService getInstance] setSpeakerMute:false];
        [_buttonSpeaker setTitle:@"关闭扬声器" forState:UIControlStateNormal];
    }
}

- (IBAction)onClickButtonOpenMic:(id)sender
{
    if( ! [m_capture isRecording] ){
        [m_capture startRecord];
        [self.btnMic setTitle:@"关闭麦克风" forState:UIControlStateNormal];
    }else{
        [m_capture stopRecord];
        [self.btnMic setTitle:@"打开麦克风" forState:UIControlStateNormal];
    }
}

- (IBAction)onClickButtonAddMixing:(id)sender {

    [[YMVoiceService getInstance] addMixOverlayVideoUserId: _localUserId.text PosX:0 PosY:0 PosZ:0 Width:MIX_WIDTH Height:MIX_HEIGHT];
    
}

- (IBAction)onClickButtonRemoveMixing:(id)sender {
    
    [[YMVoiceService getInstance] removeMixOverlayVideoUserId:_localUserId.text];
}

- (IBAction)onClickButtonSwitchCamera:(id)sender {
    [m_capture switchCamera];
}

- (IBAction)onClickButtonPlayFirstVideo:(id)sender {
    
    NSMutableArray * userArray = [[NSMutableArray alloc] init];
    NSMutableArray * resolutionArray = [[NSMutableArray alloc] init];
    for(int i = 0; i < [self.userList count]; ++i)
    {
        [userArray addObject: [self.userList objectAtIndex:i] ];
        [resolutionArray addObject:@"0" ];
    }
    [[YMVoiceService getInstance] pauseChannel];
}

- (IBAction)onClickButtonPlaySecondVideo:(id)sender {
    NSMutableArray * userArray = [[NSMutableArray alloc] init];
    NSMutableArray * resolutionArray = [[NSMutableArray alloc] init];
    for(int i = 0; i < [self.userList count]; ++i)
    {
        [userArray addObject: [self.userList objectAtIndex:i] ];
        [resolutionArray addObject:@"1" ];
    }
    [[YMVoiceService getInstance] resumeChannel];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    ParamViewController *paramView  = (ParamViewController *)segue.destinationViewController;//要跳转的vc
    
    paramView->params = params;
    paramView->bInited = enterdRoom;
}

- (IBAction)onClickButtonCamera:(id)sender {
    NSLog(@"onClickButtonCamera is called.");
    if (self.mBInRoom) {
        if( !mCameraEnable ){
            [m_capture startVideoCapture];
            mCameraEnable = true;
            if( params->push ){
                //启动推流
                LFLiveStreamInfo *streamInfo = [LFLiveStreamInfo new];
                streamInfo.url = PUSH_ADDRESS;
                [self.session startLive:streamInfo];
                self.startPush = YES;
            }
            [self.btnOpenCamera setTitle:@"关闭摄像头" forState:UIControlStateNormal];
        }else{
            [self stopCamptureAndPush];
        }
    }
}

-(void)stopCamptureAndPush
{
    if( params->push || self.startPush ){
        [self.session stopLive];
        self.startPush = NO;
    }
    mCameraEnable= false;
    [self stopVideoCapture];
    [self.btnOpenCamera setTitle:@"打开摄像头" forState:UIControlStateNormal];

}

- (void)startVideoCapture{
    [m_capture startVideoCapture];
    mCameraEnable = true;
}
- (void)stopVideoCapture
{
    [m_capture stopVideoCapture];

    //移除localView里面的内容
    for (UIView *view in [self.view subviews]) {
        if ((view.tag == 10001) || (view.tag == 10002) || (view.tag == 10003) || (view.tag == 10004) || (view.tag == 10005) || (view.tag == 10006)) {
            [view removeFromSuperview];
        }
    }
    mCameraEnable = false;
}

///////////////////////////////////////////////////////////////////



//////////////////////////////////////////////
// SessionDelegate
#pragma mark - LFStreamingSessionDelegate
/** live status changed will callback */
- (void)liveSession:(nullable LFLiveSession *)session liveStateDidChange:(LFLiveState)state {
    NSLog(@"liveStateDidChange: %ld", state);
}

/** live debug info callback */
- (void)liveSession:(nullable LFLiveSession *)session debugInfo:(nullable LFLiveDebug *)debugInfo {
    NSLog(@"debugInfo uploadSpeed: %@", [YMTalkUtils formatedSpeed:debugInfo.currentBandwidth elapsed_milli:debugInfo.elapsedMilli]);
}

/** callback socket errorcode */
- (void)liveSession:(nullable LFLiveSession *)session errorCode:(LFLiveSocketErrorCode)errorCode {
    NSLog(@"errorCode: %ld", errorCode);
}


/////////////////////////////////////////////////////
// 回调逻辑处理
//监听会议相关
#pragma mark - Event回调处理
- (void)onYouMeEvent:(YouMeEvent_t)eventType errcode:(YouMeErrorCode_t)iErrorCode  roomid:(NSString *)roomid param:(NSString*)param
{
    NSLog(@"onYouMeEvent: type:%d, err:%d, room:%@,param:%@", eventType, iErrorCode, roomid, param );
    
    NSDictionary* dictPramEventMap = @{
                                       @(YOUME_EVENT_INIT_OK) : NSStringFromSelector(@selector(youmeEventInitOKWithErrCode:roomid:param:)),
                                       @(YOUME_EVENT_INIT_FAILED) : NSStringFromSelector(@selector(youmeEventInitFailedWithErrCode:roomid:param:)),
                                       @(YOUME_EVENT_JOIN_OK) : NSStringFromSelector(@selector(youmeEventJoinOKWithErrCode:roomid:param:)),
                                       @(YOUME_EVENT_JOIN_FAILED) : NSStringFromSelector(@selector(youmeEventJoinFailedWithErrCode:roomid:param:)),
                                       @(YOUME_EVENT_LEAVED_ALL) : NSStringFromSelector(@selector(youmeEventLeavedAllWithErrCode:roomid:param:)),
                                       @(YOUME_EVENT_OTHERS_VIDEO_ON) : NSStringFromSelector(@selector(youmeEventOthersVideoOnWithErrCode:roomid:param:)),
                                       @(YOUME_EVENT_FAREND_VOICE_LEVEL) : NSStringFromSelector(@selector(youmeEventFarendVoiceLevelOnWithErrCode:roomid:param:)),
                                       @(YOUME_EVENT_OTHERS_VIDEO_INPUT_START) : NSStringFromSelector(@selector(youmeEventOthersVideoInputStartOnWithErrCode:roomid:param:)),
                                       @(YOUME_EVENT_OTHERS_VIDEO_INPUT_STOP) : NSStringFromSelector(@selector(youmeEventOthersVideoInputStopOnWithErrCode:roomid:param:)),
                                       @(YOUME_EVENT_OTHERS_VIDEO_SHUT_DOWN) : NSStringFromSelector(@selector(youmeEventOthersVideoShutDownWithErrCode:roomid:param:)),
                                       @(YOUME_EVENT_RESUMED) :NSStringFromSelector(@selector(youmeEventResume:roomid:param:)),
                                       @(YOUME_EVENT_PAUSED) :NSStringFromSelector(@selector(youmeEventPause:roomid:param:))
                                       };
    
    if ([dictPramEventMap objectForKey:@(eventType)]) {
        [self performSelectorOnMainThread:NSSelectorFromString([dictPramEventMap objectForKey:@(eventType)])
                               withObject:@(iErrorCode)
                               withObject:roomid
                               withObject:param
                            waitUntilDone:TRUE];
    } else {
        dispatch_async (dispatch_get_main_queue (), ^{
            NSString* strTmp = @"Evt: %d, err:%d, param:%@ ,room:%@ ";
            
            NSString* showInfo = [NSString stringWithFormat: strTmp, eventType, iErrorCode, param, roomid ];
            [self.tfTips setText:showInfo];
        });
    }
    
}


// 会议相关回调逻辑处理
-(void)youmeEventInitOKWithErrCode:(NSNumber*)iErrorCodeNum  roomid:(NSString *)roomid param:(NSString*)param {
    // SDK验证成功
    self.mBInitOK = TRUE;
    //设置服务器区域，在请求进入频道前调用生效
    [[YMVoiceService getInstance] setServerRegion:RTC_CN_SERVER regionName:@"" bAppend:false];
    [self.tfTips setText:@"SDK验证成功!"];
}

-(void)youmeEventInitFailedWithErrCode:(NSNumber*)iErrorCodeNum  roomid:(NSString *)roomid param:(NSString*)param {
    //SDK验证失败
    self.mBInitOK = FALSE;
    [self.tfTips setText:@"SDK验证失败!"];
    
}


-(void)youmeEventJoinOKWithErrCode:(NSNumber*)iErrorCodeNum  roomid:(NSString *)roomid param:(NSString*)param {
    self.mBInRoom = true;
    self.strLocalUserID = param;
    //设置混流画布
    [[YMVoiceService getInstance] setMixVideoWidth:MIX_WIDTH Height:MIX_HEIGHT];
    [[YMVoiceService getInstance] addMixOverlayVideoUserId: self.strLocalUserID PosX:0 PosY:0 PosZ:0 Width:MIX_WIDTH Height:MIX_HEIGHT];
    //美颜
    [[YMVoiceService getInstance] openBeautify:true];
    [[YMVoiceService getInstance] beautifyChanged:0.8f];
    
    _buttonSpeaker.enabled = true;
    [[YMVoiceService getInstance] setSpeakerMute:false];
    
    //todopinky:
    [[YMVoiceService getInstance]setPcmCallbackEnable: ( PcmCallbackFlag_Remote  | PcmCallbackFlag_Record | PcmCallbackFlag_Mix)  outputToSpeaker: true  ];
    
    //取左上角的渲染view用来显示本地画面
    UserViewInfo * info = self.viewList[2];
    info->userId = mLocalUserId;
    [[YMVoiceService getInstance ] createRender:mLocalUserId parentView:info->glView singleMode:YES];
    
    // 与内部采集自动开麦一致
    if (self.m_bExternalCaptureMode){
        if( ! [m_capture isRecording] ){
            [m_capture startRecord];
        }
    }
    
    [self.tfTips setText:@"加入房间成功!"];
    [self joinedUI];
}

-(void)youmeEventJoinFailedWithErrCode:(NSNumber*)iErrorCodeNum  roomid:(NSString *)roomid param:(NSString*)param {
    self.mBInRoom = false;
    NSString* strErrorCode = [NSString stringWithFormat:@"加入房间失败,errcode:%ld", [iErrorCodeNum integerValue]];
    [self.tfTips setText:strErrorCode];
    [self leavedUI];
}


-(void)youmeEventLeavedAllWithErrCode:(NSNumber*)iErrorCodeNum  roomid:(NSString *)roomid param:(NSString*)param {
    self.mBInRoom = false;
    switch (mMode) {
        case ANCHOR_SPEAKER_MODE:
        {
            break;
        }
        case NOT_INROOM_MODE:
        {
            NSString* strTmp = @"已离开房间,errcode:";
            NSString* strErrorCode = [NSString stringWithFormat:@"%ld",[iErrorCodeNum integerValue]];
            mTips = [strTmp stringByAppendingString:strErrorCode];
            NSLog(mTips);
            dispatch_async (dispatch_get_main_queue (), ^{
                [self resetAllRender];
                [self.tfTips setText:mTips];
                
            });
            self.strMixUserID = nil;
            [[YMVoiceService getInstance] removeAllOverlayVideo];
            break;
        }
        default:
            break;
    }
    
    [self leavedUI];
}

-(void)youmeEventOthersVideoOnWithErrCode:(NSNumber*)iErrorCodeNum  roomid:(NSString *)roomid param:(NSString*)param {
    NSString* userId = param;
    for (UserViewInfo * info in self.viewList) {
        if (info->userId && [info->userId compare:userId] == 0) {
            return;
        }
    }
    for (UserViewInfo * info in self.viewList) {
        if (!info->userId) {
            info->userId = userId;
            [[YMVoiceService getInstance ] createRender:userId parentView:info->glView singleMode:YES];
            if(!self.strMixUserID){
                self.strMixUserID = userId;
                [[YMVoiceService getInstance ] addMixOverlayVideoUserId:userId PosX:10 PosY:10 PosZ:1 Width:120 Height:160];
            }
            break;
        }
    }
}

-(void)youmeEventFarendVoiceLevelOnWithErrCode:(NSNumber*)iErrorCodeNum  roomid:(NSString *)roomid param:(NSString*)param {
    //远端音量回调
}

-(void)youmeEventOthersVideoInputStartOnWithErrCode:(NSNumber*)iErrorCodeNum  roomid:(NSString *)roomid param:(NSString*)param {
    for (NSString* userid in self.userList) {
        if(![param compare:userid])
            break;
    }
    [self.userList addObject:param];
    NSLog(@"User:%@ start video input", param  );
}

-(void)youmeEventOthersVideoInputStopOnWithErrCode:(NSNumber*)iErrorCodeNum  roomid:(NSString *)roomid param:(NSString*)param {
    [self.userList removeObject:param];
    NSLog(@"User:%@ stop video input", param  );
}

-(void)youmeEventOthersVideoShutDownWithErrCode:(NSNumber*)iErrorCodeNum  roomid:(NSString *)roomid param:(NSString*)param {
    
    for (UserViewInfo * info in self.viewList) {
        if (info->userId && [info->userId compare:param] == NSOrderedSame) {
            info->userId = nil;
            [[YMVoiceService getInstance ] deleteRender:param glView:nil];
            if(self.strMixUserID && [self.strMixUserID compare:param] == 0)
            {
                [[YMVoiceService getInstance] removeMixOverlayVideoUserId:param];
                self.strMixUserID = nil;
            }
            break;
        }
    }
    
}

-(void)youmeEventResume:(NSNumber*)iErrorCodeNum  roomid:(NSString *)roomid param:(NSString*)param  {
    [m_capture onResume];
}

-(void)youmeEventPause:(NSNumber*)iErrorCodeNum  roomid:(NSString *)roomid param:(NSString*)param {
    [m_capture onPause];
}

#pragma mark - 前后台切换监听
-(void)resumeYMVoiceService:(NSNotification*)notify {
    [[YMVoiceService getInstance] resumeChannel];
}

-(void)pauseYMVoiceService:(NSNotification*)notify {
    [[YMVoiceService getInstance] pauseChannel];
}



@end
