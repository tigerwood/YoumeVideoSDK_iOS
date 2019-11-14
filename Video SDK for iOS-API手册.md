# Video SDK for iOS API接口手册

## 相关异步/同步处理方法介绍

游密语音引擎SDK接口调用都会立即返回,凡是本身需要较长耗时的接口调用都会采用异步回调的方式,所有接口都可以在主线程中直接使用。回调都在子线程中进行，请注意不要在回调中直接操作UI主线程。

## API调用说明

API的调用可使用“[YMVoiceService getInstance]”来直接操作，接口使用的基本流程为`初始化`->`收到初始化成功回调通知`->`加入语音频道`->`收到加入频道成功回调通知`->`使用其它接口`->`离开语音频道`->`反初始化`，要确保严格按照上述的顺序使用接口。

## 视频关键接口流程
1. 在收到`YOUME_EVENT_JOIN_OK`事件后

    开关麦克风：`[[YMVoiceService  getInstance] setMicrophoneMute:false];`
    开关扬声器：`[[YMVoiceService  getInstance] setSpeakerMute:false];`
    控制自己的摄像头打开：`[[YMVoiceService  getInstance] startCapture];`
    控制自己的摄像头关闭：`[[YMVoiceService  getInstance] stopCapture];`
    
2. 以上步骤完成，可以创建自己的视频流渲染View：
`[[YMVoiceService getInstance ] createRender:local_userid parentView:parentView];`
开启摄像头之后会渲染到返回的UIView里。
远端有视频流过来时，会通知 `YOUME_EVENT_OTHERS_VIDEO_ON` 事件，在该事件里创建视频渲染组件
`[[YMVoiceService getInstance ] createRender:other_userid parentView:parentView];`
远端视频会渲染在返回的UIView里，同时会在以下事件里收到对应的视频数据回调，不过可以不做处理：

```objectivec
// 软解
- (void)onVideoFrameCallback: (NSString*)userId data:(void*) data len:(int)len width:(int)width height:(int)height fmt:(int)fmt timestamp:(uint64_t)timestamp;
// 硬解
- (void)onVideoFrameCallbackForGLES:(NSString*)userId  pixelBuffer:(CVPixelBufferRef)pixelBuffer timestamp:(uint64_t)timestamp;
```
    
3. 其它API
    是否屏蔽他人视频： `[[YMVoiceService getInstance] maskVideoByUserId:(NSString*) userId mask:(bool) mask];`
    切换摄像头：`[[YMVoiceService getInstance] switchCamera];`
    删除渲染绑定：`[[YMVoiceService getInstance] deleteRender:userid];`

## 视频API说明

## 实现回调

使用者要遵守协议VoiceEngineCallback并实现相关函数（回调函数）。回调都在子线程中执行，不能用于更新UI等耗时操作。

*  首先要遵守协议VoiceEngineCallback来注册回调事件：

![注册](https://youme.im/doc/images/talk_ios_register.jpg)


* 然后具体实现回调方法：

``` objectivec
-(void) onYouMeEvent:(YouMeEvent_t)eventType errcode:(YouMeErrorCode_t)iErrorCode roomid:(NSString *)roomid param:(NSString *)param {
    switch (eventType)
    {
            //case案例只覆盖了部分，仅供参考，详情请查询枚举类型YouMeEvent
        case YOUME_EVENT_INIT_OK:
            //"初始化成功";
            break;
        case YOUME_EVENT_INIT_FAILED:
            // "初始化失败，错误码：" + errorCode;
            break;
        case YOUME_EVENT_JOIN_OK:
            //"加入频道成功";
            break;
        case YOUME_EVENT_LEAVED_ALL:
            // "离开频道成功"
            break;
        case YOUME_EVENT_JOIN_FAILED:
            //进入语音频道失败
       	     break;
        case YOUME_EVENT_REC_PERMISSION_STATUS:
            // "通知录音权限状态，成功获取权限时错误码为YOUME_SUCCESS，获取失败为YOUME_ERROR_REC_NO_PERMISSION（此时不管麦克风mute状态如何，都没有声音输出）";
            break;
        case YOUME_EVENT_RECONNECTING:
            //"断网了，正在重连";
            break;
        case YOUME_EVENT_RECONNECTED:
            // "断网重连成功";
            break;
        case  YOUME_EVENT_OTHERS_MIC_OFF:
            //其他用户的麦克风关闭：
            break;
        case YOUME_EVENT_OTHERS_MIC_ON:
            //其他用户的麦克风打开：
            break;
        case YOUME_EVENT_OTHERS_SPEAKER_ON:
            //其他用户的扬声器打开：
            break;
        case YOUME_EVENT_OTHERS_SPEAKER_OFF:
            //其他用户的扬声器关闭
            break;
        case YOUME_EVENT_OTHERS_VOICE_ON:
            //其他用户开始讲话
            break;
        case YOUME_EVENT_OTHERS_VOICE_OFF:
            //其他用户停止讲话
            break;
        case YOUME_EVENT_MY_MIC_LEVEL:
            //麦克风的语音级别，值把iErrorCode转为整形即是音量值
            break;
        case YOUME_EVENT_MIC_CTR_ON:
            //麦克风被其他用户打开
            break;
        case YOUME_EVENT_MIC_CTR_OFF:
            //麦克风被其他用户关闭
            break;
        case YOUME_EVENT_SPEAKER_CTR_ON:
            //扬声器被其他用户打开
            break;
        case YOUME_EVENT_SPEAKER_CTR_OFF:
            //扬声器被其他用户关闭
            break;
        case YOUME_EVENT_LISTEN_OTHER_ON:
            //取消屏蔽某人语音
            break;
        case YOUME_EVENT_LISTEN_OTHER_OFF:
            //屏蔽某人语音
            break;
        default:
            //"事件类型" + eventType + ",错误码" +errcode
            break;
    }
}
//RestAPI回调
- (void)onRequestRestAPI: (int)requestID iErrorCode:(YouMeErrorCode_t) iErrorCode  query:(NSString*) strQuery  result:(NSString*) strResult {
}
//获取频道用户列表回调
- (void)onMemberChange:(NSString*) channelID changeList:(NSArray*) changeList { 
    NSLog(@"isUpdate:%d", isUpdate);
    NSInteger count = [changeList count];
    NSLog(@"MemberChagne:%@, count:%ld",channelID, count );
    for( int i = 0 ; i < count ;i++ ){
        MemberChangeOC* change = [changeList objectAtIndex:i ];
        if( change.isJoin == 1 ){
            NSLog(@"%@ 进入", change.userID);
        }else{
            NSLog(@"%@ 离开了", change.userID );
        }
    }
}
//SDK内置连麦抢麦接口对应的回调
- (void)onBroadcast:(YouMeBroadcast_t)bc strChannelID:(NSString*)channelID strParam1:(NSString*)param1 strParam2:(NSString*)param2 strContent:(NSString*)content{
}
//音视频通话码率、丢包率回调
- (void) onAVStatistic:(YouMeAVStatisticType_t)type  userID:(NSString*)userID  value:(int) value {

}
```


## 设置日志等级
* **语法**

```
- (void) setLogLevel:(YOUME_LOG_LEVEL_t) level;
```

* **功能**
设置日志等级


* **参数说明**
`level`：日志等级。小于等于该等级的日志会打印。

###  设置用户自定义Log路径

* **语法**

```
- (YouMeErrorCode_t)setUserLogPath:(NSString *)path;
```

* **功能**
设置用户自定义Log路径

* **参数说明**
`path`:Log文件的路径

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

##  设置是否使用TCP

* **语法**

```
- (YouMeErrorCode_t)setTCPMode:(bool)bUseTcp;
```

* **功能**
设置是否使用TCP模式来收发数据，针对特殊网络没有UDP端口使用，必须在加入房间之前调用

* **参数说明**
`bUseTcp`:是否使用

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

## 初始化

* **语法**
```
-(YouMeErrorCode_t)initSDK:(id<VoiceEngineCallback>)delegate  appkey:(NSString*)appKey  appSecret:(NSString*)appSecret
        regionId:(YOUME_RTC_SERVER_REGION_t)regionId
           serverRegionName:(NSString*) serverRegionName;
```

* **功能**
初始化语音引擎，做APP验证和资源初始化。

* **参数说明**
`delegate`：实现了回调函数的委托对象
`appKey`：从游密申请到的 app key, 这个你们应用程序的唯一标识。
`appSecret`：对应 appKey 的私钥, 这个需要妥善保存，不要暴露给其他人。
`regionId`：设置首选连接服务器的区域码，如果在初始化时不能确定区域，可以填RTC_DEFAULT_SERVER，后面确定时通过 setServerRegion 设置。如果YOUME_RTC_SERVER_REGION定义的区域码不能满足要求，可以把这个参数设为 RTC_EXT_SERVER，然后通过后面的参数serverRegionName 设置一个自定的区域值（如中国用 "cn" 或者 “ch"表示），然后把这个自定义的区域值同步给游密，我们将通过后台配置映射到最佳区域的服务器。
`serverRegionName`：自定义的扩展的服务器区域名。不能为null，可为空字符串“”。只有前一个参数serverRegionId设为RTC_EXT_SERVER时，此参数才有效（否则都将当空字符串“”处理）。

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

* **异步回调**
```
// 涉及到的主要回调事件有：
// YOUME_EVENT_INIT_OK  - 表明初始化成功
// YOUME_EVENT_INIT_FAILED - 表明初始化失败，最常见的失败原因是网络错误或者 AppKey-AppSecret 错误
-(void)onYouMeEvent:(YouMeEvent_t)eventType errcode:(YouMeErrorCode_t)iErrorCode roomid:(NSString *)roomid param:(NSString *)param;
```

## 判断是否初始化完成

* **语法**
```
- (bool) isInited;
```

* **功能**
判断是否初始化完成

* **返回值**
true——初始化完成，false——初始化未完成。


## 语音频道管理

### 加入语音频道（单频道）

* **语法**
``` objectivec
- (YouMeErrorCode_t) joinChannelSingleMode:(NSString *)strUserID channelID:(NSString *)strChannelID userRole:(YouMeUserRole_t)userRole autoRecv:(bool)autoRecv;
```

* **功能**
加入语音频道（单频道模式，每个时刻只能在一个语音频道里面），多次调用，会进入最后调用指定的频道。

* **参数说明**
`strUserID`：全局唯一的用户标识，全局指在当前应用程序的范围内。
`strChannelID`：全局唯一的频道标识，全局指在当前应用程序的范围内。
`userRole`：用户在语音频道里面的角色，见YouMeUserRole定义。
`autoRecv`：进入房间后是否自动接收视频, 为 true 时自动接收，为 false 时，需要调用 `setUsersVideoInfo` 后才会接收对方的视频流。

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

* **异步回调**
``` objectivec
// 涉及到的主要回调事件有：
// YOUME_EVENT_JOIN_OK - 成功进入语音频道
// YOUME_EVENT_JOIN_FAILED - 进入语音频道失败，可能原因是网络或服务器有问题，或是bCheckRoomExist为true时频道还未创建
-(void)onYouMeEvent:(YouMeEvent_t)eventType errcode:(YouMeErrorCode_t)iErrorCode roomid:(NSString *)roomid param:(NSString *)param;
```

### 加入语音频道（多频道）

* **语法**
``` objectivec
- (YouMeErrorCode_t) joinChannelMultiMode:(NSString *)strUserID channelID:(NSString *)strChannelID userRole:(YouMeUserRole_t)userRole;
```

* **功能**
加入语音频道（多频道模式，可以同时听多个语音频道的内容，但每个时刻只能对着一个频道讲话）。

* **参数说明**
`strUserID`：全局唯一的用户标识，全局指在当前应用程序的范围内。
`strChannelID`：全局唯一的频道标识，全局指在当前应用程序的范围内。
`userRole`：用户在语音频道里面的角色，见YouMeUserRole定义。

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

* **异步回调**
``` objectivec
// 涉及到的主要回调事件有：
// YOUME_EVENT_JOIN_OK - 成功进入语音频道
// YOUME_EVENT_JOIN_FAILED - 进入语音频道失败，可能原因是网络或服务器有问题，或是bCheckRoomExist为true时频道还未创建
-(void)onYouMeEvent:(YouMeEvent_t)eventType errcode:(YouMeErrorCode_t)iErrorCode roomid:(NSString *)roomid param:(NSString *)param;
```

### 指定讲话频道

* **语法**
``` objectivec
-(YouMeErrorCode_t) speakToChannel:(NSString *)strChannelID;
```

* **功能**
多频道模式下，指定当前要讲话的频道。

* **参数说明**
`strChannelID`：全局唯一的频道标识，全局指在当前应用程序的范围内。

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

* **异步回调**
``` objectivec
// 涉及到的主要回调事件有：
// YOUME_EVENT_SPEAK_SUCCESS - 成功切入到指定语音频道
// YOUME_EVENT_SPEAK_FAILED - 切入指定语音频道失败，可能原因是网络或服务器有问题
-(void)onYouMeEvent:(YouMeEvent_t)eventType errcode:(YouMeErrorCode_t)iErrorCode roomid:(NSString *)roomid param:(NSString *)param;
```

### 退出指定的语音频道

* **语法**
```
-(YouMeErrorCode_t)leaveChannelMultiMode:(NSString *)strChannelID;
```
* **功能**
多频道模式下，退出指定的语音频道。

* **参数说明**
`strChannelID`：全局唯一的频道标识，全局指在当前应用程序的范围内。

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

* **异步回调**
```
//涉及到的主要回调事件有：
//YOUME_EVENT_LEAVED_ONE - 成功退出指定语音频道
-(void)onYouMeEvent:(YouMeEvent_t)eventType errcode:(YouMeErrorCode_t)iErrorCode roomid:(NSString *)roomid param:(NSString *)param;
```

### 退出所有语音频道

* **语法**
```
-(YouMeErrorCode_t)leaveChannelAll;
```

* **功能**
退出所有的语音频道（单频道模式下直接调用此函数离开频道即可）。

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

* **异步回调**
```
//涉及到的主要回调事件有：
//YOUME_EVENT_LEAVED_ALL - 成功退出所有语音频道
-(void)onYouMeEvent:(YouMeEvent_t)eventType errcode:(YouMeErrorCode_t)iErrorCode roomid:(NSString *)roomid param:(NSString *)param;
```

### 切换身份

* **语法**
```
- (YouMeErrorCode_t) setUserRole:(YouMeUserRole_t) eUserRole;
```

* **功能**
切换身份(仅支持单频道模式，进入房间以后设置)

* **参数说明**
`eUserRole`：用户身份

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

### 获取身份

* **语法**
```
- (YouMeUserRole_t) getUserRole;
```

* **功能**
获取身份(仅支持单频道模式)

* **返回值**
用户身份，参见YouMeUserRole类型定义

### 查询是否在某个语音频道内

* **语法**
```
- (bool) isInChannel:(NSString*) strChannelID;
```

* **功能**
查询是否在某个语音频道内

* **返回值**
true——在频道内，false——没有在频道内

### 查询是否在语音频道内

* **语法**
```
- (bool) isInChannel;
```

* **功能**
查询是否在语音频道内

* **返回值**
true——在频道内，false——没有在频道内

### 设置白名单用户

* **语法**
```
- (YouMeErrorCode_t) setWhiteUserList:(NSString*) channelID  whiteUserList:(NSString*) whiteUserList;
```

* **功能**
设置当前用户的语音消息接收白名单，其语音消息只会转发到白名单的用户，不设置该接口则默认转发至频道内所有人。

* **参数说明**
`strChannelID`：要设置的频道(兼容多频道模式，单频道模式下传入当前频道即可)。
`strWhiteUserList`：白名单用户列表, 以|分隔，如：User1|User2|User3；"all"表示转发至频道内所有人；""（空字符串）表示不转发至任何用户。

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

* **异步回调**
```
// 涉及到的主要回调事件有：
//YOUME_EVENT_SET_WHITE_USER_LIST_OK - 成功在指定语音频道设置白名单，有异常用户会返回错误码YOUME_ERROR_WHITE_SOMEUSER_ABNORMAL
//YOUME_EVENT_SET_WHITE_USER_LIST_FAILED - 在指定语音频道设置白名单失败，可能原因是网络或服务器有问题
-(void)onYouMeEvent:(YouMeEvent_t)eventType errcode:(YouMeErrorCode_t)iErrorCode roomid:(NSString *)roomid param:(NSString *)param;
```

## 设备状态管理

### 切换语音输出设备

* **语法**

```
-(YouMeErrorCode_t)setOutputToSpeaker:(bool)bOutputToSpeaker;
```
* **功能**
默认输出到扬声器，在加入房间成功后设置（iOS受系统限制，如果已释放麦克风则无法切换到听筒）

* **参数说明**
`bOutputToSpeaker `：true——输出到扬声器，false——输出到听筒。

* **返回值**
如果成功返回YOUME_SUCCESS，否则返回错误码，具体请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

### 设置扬声器状态

* **语法**
```
-(void)setSpeakerMute:(bool)mute;
```
* **功能**
打开/关闭扬声器。**该状态值在加入房间成功后设置才有效。**

* **参数说明**
`mute`:true——关闭扬声器，false——开启扬声器。


### 获取扬声器状态

* **语法**
```
(bool)getSpeakerMute;
```

* **功能**
获取当前扬声器状态。

* **返回值**
true——扬声器关闭，false——扬声器开启。


### 设置麦克风状态

* **语法**
```
-(void)setMicrophoneMute:(bool)mute;
```

* **功能**
打开／关闭麦克风。**该状态值在加入房间成功后设置才有效。**

* **参数说明**
`mute`:true——关闭麦克风，false——开启麦克风。


### 获取麦克风状态

* **语法**
```
(bool)getMicrophoneMute;
```

* **功能**
获取当前麦克风状态。

* **返回值**
true——麦克风关闭，false——麦克风开启。

### 设置是否通知别人麦克风和扬声器的开关

* **语法**
```
-(void)setAutoSendStatus:(bool)bAutoSend;
```

* **功能**
设置是否通知别人,自己麦克风和扬声器的开关状态

### 设置音量

* **语法**
```
-(void)setVolume:(unsigned int)uiVolume;
```

* **功能**
设置当前程序输出音量大小。建议该状态值在加入房间成功后按需再重置一次。

* **参数说明**
`uiVolume`:当前音量大小，范围[0-100]。

### 获取音量

* **语法**
```
(unsigned int)getVolume;
```

* **功能**
获取当前程序输出音量大小，此音量值为程序内部的音量，与系统音量相乘得到程序使用的实际音量。

* **返回值**
当前音量大小，范围[0-100]。

## 设置网络

### 设置是否允许使用移动网络

* **语法**
```
-(void)setUseMobileNetworkEnabled:(bool)bEnabled;
```

* **功能**
设置是否允许使用移动网络。在WIFI和移动网络都可用的情况下会优先使用WIFI，在没有WIFI的情况下，如果设置允许使用移动网络，那么会使用移动网络进行语音通信，否则通信会失败。

* **参数说明**
`bEnabled`:true——允许使用移动网络，false——禁止使用移动网络。


### 获取是否允许使用移动网络

* **语法**
```
(bool) getUseMobileNetworkEnabled;
```

* **功能**
获取是否允许SDK在没有WIFI的情况使用移动网络进行语音通信。

* **返回值**
true——允许使用移动网络，false——禁止使用移动网络，默认情况下允许使用移动网络。

## 控制他人麦克风

* **语法**
```
-(void) setOtherMicMute:(NSString *)strUserID  mute:(bool) mute;
```

* **功能**
控制他人的麦克风状态

* **参数说明**
`strUserID`：要控制的用户ID
`mute`：是否静音。true:静音别人的麦克风，false：开启别人的麦克风

* **返回值**
如果成功返回YOUME_SUCCESS，否则返回错误码，具体请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

## 控制他人扬声器

* **语法**
```
-(void) setOtherSpeakerMute: (NSString *)strUserID  mute:(bool) mute;
```

* **功能**
控制他人的扬声器状态

* **参数说明**
`strUserID`：要控制的用户ID
`mute`：是否静音。true:静音别人的扬声器，false：开启别人的扬声器

* **返回值**
如果成功返回YOUME_SUCCESS，否则返回错误码，具体请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

## 设置是否听某人的语音

* **语法**
```
-(void) setListenOtherVoice: (NSString *)strUserID  isOn:(bool) isOn;
```

* **功能**
设置是否听某人的语音。

* **参数说明**
`strUserID`：要控制的用户ID。
`on`：true表示开启接收指定用户的语音，false表示屏蔽指定用户的语音。

* **返回值**
无。

## 设置当麦克风静音时，是否释放麦克风设备

* **语法**
```
-(YouMeErrorCode_t) setReleaseMicWhenMute:(bool) enabled;
```

* **功能**
设置当麦克风静音时，是否释放麦克风设备（需要在初始化成功后，加入房间之前调用）

* **参数说明**
`enabled`： true--当麦克风静音时，释放麦克风设备，此时允许第三方模块使用麦克风设备录音。在Android上，语音通过媒体音轨，而不是通话音轨输出；false--不管麦克风是否静音，麦克风设备都会被占用。

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。



## 设置插入耳机时，是否自动退出系统通话模式

* **语法**
```
-(YouMeErrorCode_t) setExitCommModeWhenHeadsetPlugin:(bool) enabled;
```

* **功能**
设置插入耳机时，是否自动退出系统通话模式(禁用手机硬件提供的回声消除等信号前处理)
系统提供的前处理效果包括回声消除、自动增益等，有助于抑制背景音乐等回声噪音，减少系统资源消耗
由于插入耳机可从物理上阻断回声产生，故可设置禁用该效果以保留背景音乐的原生音质效果
注：Windows和macOS不支持该接口

* **参数说明**
`enabled`： true--当插入耳机时，自动禁用系统硬件信号前处理，拔出时还原；false--插拔耳机不做处理。

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

## 通话管理

### 暂停通话

* **语法**
```
-(YouMeErrorCode_t)pauseChannel;
```

* **功能**
暂停通话，释放对麦克风等设备资源的占用。当需要用第三方模块临时录音时，可调用这个接口。

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

* **异步回调**
```
// 主要回调事件：
// YOUME_EVENT_PAUSED - 暂停语音频道完成
-(void)onYouMeEvent:(YouMeEvent_t)eventType errcode:(YouMeErrorCode_t)iErrorCode roomid:(NSString *)roomid param:(NSString *)param;
```

### 恢复通话

* **语法**
```
-(YouMeErrorCode_t)resumeChannel;
```

* **功能**
恢复通话，调用PauseChannel暂停通话后，可调用这个接口恢复通话。

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

* **异步回调**
```
// 主要回调事件：
// YOUME_EVENT_RESUMED - 恢复语音频道完成
-(void)onYouMeEvent:(YouMeEvent_t)eventType errcode:(YouMeErrorCode_t)iErrorCode roomid:(NSString *)roomid param:(NSString *)param;
```

## 设置语音检测

* **语法**
```
-(YouMeErrorCode_t)setVadCallbackEnabled:(bool)enabled
```

* **功能**
设置是否开启语音检测回调，开启后频道内有人正在讲话与结束讲话都会发起相应回调通知。**该状态值在加入房间成功后设置才有效。**

* **参数说明**
`enabled`:true——打开，false——关闭。

* **返回值**
如果成功则返回YOUME_SUCCESS，其它具体参见[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。


## 设置是否开启讲话音量回调

* **语法**
```
-(YouMeErrorCode_t) setMicLevelCallback:(int) maxLevel;
```

* **功能**
设置是否开启讲话音量回调, 并设置相应的参数。

* **参数说明**
`maxLevel`:音量最大时对应的级别，最大可设100。根据实际需要设置小于100的值可以减少回调的次数（注意设置较高的值可能会产生大量回调，特别在Unity上会影响其它事件到达，一般建议不超过30）。比如你只在UI上呈现10级的音量变化，那就设10就可以了。设 0 表示关闭回调。

**返回值**
如果成功则返回YOUME_SUCCESS，其它具体参见[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。


## 设置是否开启远端语音音量回调

* **语法**
```
- (YouMeErrorCode_t) setFarendVoiceLevelCallback:(int) maxLevel;
```

* **功能**
设置是否开启远端语音音量回调, 并设置相应的参数

* **参数说明**
`maxLevel`:音量最大时对应的级别，最大可设100。比如你只在UI上呈现10级的音量变化，那就设10就可以了。设 0 表示关闭回调。

**返回值**
如果成功则返回YOUME_SUCCESS，其它具体参见[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。


## 背景音乐管理

### 播放背景音乐播放背景音乐

* **语法**
```
 (YouMeErrorCode_t)playBackgroundMusic:(NSString *)path  repeat:(bool)repeat;
```

* **功能**
播放指定的音乐文件。播放的音乐将会通过扬声器输出，并和语音混合后发送给接收方。这个功能适合于主播/指挥等使用。

* **参数说明**
`path`：音乐文件的路径。
`repeat`：是否重复播放，true——重复播放，false——只播放一次就停止播放。

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

* **异步回调**

```
// 主要回调事件：
// YOUME_EVENT_BGM_STOPPED - 通知背景音乐播放结束
// YOUME_EVENT_BGM_FAILED - 通知背景音乐播放失败
-(void)onYouMeEvent:(YouMeEvent_t)eventType errcode:(YouMeErrorCode_t)iErrorCode roomid:(NSString *)roomid param:(NSString *)param;
```

### 停止播放背景音乐

* **语法**
```
-(YouMeErrorCode_t)stopBackgroundMusic;
```

* **功能**
停止播放当前正在播放的背景音乐。
这是一个同步调用接口，函数返回时，音乐播放也就停止了。

* **返回值**
如果成功返回YOUME_SUCCESS，表明成功停止了音乐播放流程；否则返回错误码，具体请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

### 暂停播放背景音乐

* **语法**

```
- (YouMeErrorCode_t)pauseBackgroundMusic;
```

* **功能**
如果当前正在播放背景音乐的话，暂停播放

* **返回值**
如果成功返回YOUME_SUCCESS，表明成功停止了音乐播放流程；否则返回错误码，具体请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

### 恢复播放背景音乐

* **语法**

```
- (YouMeErrorCode_t)resumeBackgroundMusic;
```

* **功能**
如果当前正在播放背景音乐的话，恢复播放

* **返回值**
如果成功返回YOUME_SUCCESS，表明成功停止了音乐播放流程；否则返回错误码，具体请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

### 背景音乐是否在播放

* **语法**

```
- (bool) isBackgroundMusicPlaying;
```

* **功能**
是否在播放背景音乐

* **返回值**
true——正在播放，false——没有播放

### 设置背景音乐播放音量

* **语法**
```
-(YouMeErrorCode_t)setBackgroundMusicVolume:(unsigned int)bgVolume;
```

* **功能**
设定背景音乐的音量。这个接口用于调整背景音乐和语音之间的相对音量，使得背景音乐和语音混合听起来协调。
这是一个同步调用接口。

* **参数说明**
`bgVolume`:背景音乐的音量，范围 [0-100]。

* **返回值**
如果成功（表明成功设置了背景音乐的音量）返回YOUME_SUCCESS，否则返回错误码，具体请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

## 设置监听

* **语法**
```
-(YouMeErrorCode_t)setHeadsetMonitorMicOn:(bool)micEnabled BgmOn:(bool)bgmEnabled;
```

* **功能**
设置是否用耳机监听自己的声音，当不插耳机或外部输入模式时，这个设置不起作用
这是一个同步调用接口。

* **参数说明**
`micEnabled`:是否监听麦克风 true 监听，false 不监听。
`bgmEnabled`:是否监听背景音乐 true 监听，false 不监听。

* **返回值**
如果成功则返回YOUME_SUCCESS，其它具体参见[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

### 设置混响音效

* **语法**
```
-(YouMeErrorCode_t)setReverbEnabled:(bool)enabled;
```

* **功能**
设置是否开启混响音效，这个主要对主播/指挥有用。

* **参数说明**
`enabled`:true——打开，false——关闭。

* **返回值**
如果成功则返回YOUME_SUCCESS，其它具体参见[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

## 设置音频数据回调
 
```
- (void) setPcmCallbackEnable:(int)flag outputToSpeaker:(bool)bOutputToSpeaker;
```

* **功能**
设置是否开启音频pcm回调，以及开启哪种类型的pcm回调。
本接口可以在加入房间前，或者加入房间后调用。

* **参数说明**
`flag`:说明需要哪些类型的音频回调，共有三种类型的回调，分别是远端音频，录音音频，以及远端和录音数据的混合音频。flag格式形如`PcmCallbackFlag_Romote| PcmCallbackFlag_Record|PcmCallbackFlag_Mix`；

`bOutputToSpeaker`: 是否扬声器静音:true 不静音;false 静音

* **返回值**
如果成功则返回YOUME_SUCCESS，其它具体参见[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

* **相关回调接口**

  ```
  //pcm回调接口位于VoiceEngineCallback
  //以下3个回调分别对应于3种类型的音频pcm回调
  //开启后才会有
  
  //远端数据回调
  //channelNum:声道数
  //samplingRateHz:采样率
  //bytesPerSample:采样深度
  //data:pcm数据buffer
  //dataSizeInByte:buffer的大小
- (void)onPcmDataRemote: (int)channelNum samplingRateHz:(int)samplingRateHz bytesPerSample:(int)bytesPerSample data:(void*) data dataSizeInByte:(int)dataSizeInByte;
//录音数据回调
- (void)onPcmDataRecord: (int)channelNum samplingRateHz:(int)samplingRateHz bytesPerSample:(int)bytesPerSample data:(void*) data dataSizeInByte:(int)dataSizeInByte;
//远端和录音的混合数据回调
- (void)onPcmDataMix: (int)channelNum samplingRateHz:(int)samplingRateHz bytesPerSample:(int)bytesPerSample data:(void*) data dataSizeInByte:(int)dataSizeInByte;
  ```


## 设置时间戳

### 设置录音时间戳

* **语法**
```
-(void) setRecordingTimeMs:(unsigned int)timeMs;
```

* **功能**
设置当前录音的时间戳。当通过录游戏脚本进行直播时，要保证观众端音画同步，在主播端需要进行时间对齐。
这个接口设置的就是当前游戏画面录制已经进行到哪个时间点了。

* **参数说明**
`timeMs`:当前游戏画面对应的时间点，单位为毫秒。

* **返回值**
无。


### 设置播放时间戳

* **语法**
```
-(void) setPlayingTimeMs:(unsigned int)timeMs;
```

* **功能**
设置当前声音播放的时间戳。当通过录游戏脚本进行直播时，要保证观众端音画同步，游戏画面的播放需要和声音播放进行时间对齐。
这个接口设置的就是当前游戏画面播放已经进行到哪个时间点了。

* **参数说明**
`timeMs`:当前游戏画面播放对应的时间点，单位为毫秒。

* **返回值**
无。


## 设置服务器区域

* **语法**
```
-(void)setServerRegion:(YOUME_RTC_SERVER_REGION_OC)serverRegionId regionName:(NSString*)regionName bAppend:(bool)bAppend;
```

* **功能**
设置首选连接服务器的区域码.

* **参数说明**
`serverRegionId`：如果YOUME_RTC_SERVER_REGION定义的区域码不能满足要求，可以把这个参数设为 RTC_EXT_SERVER，然后通过后面的参数regionName 设置一个自定的区域值（如中国用 "cn" 或者 “ch"表示），然后把这个自定义的区域值同步给游密，我们将通过后台配置映射到最佳区域的服务器。
`regionName`：自定义的扩展的服务器区域名。不能为null，可为空字符串“”。只有前一个参数serverRegionId设为RTC_EXT_SERVER时，此参数才有效（否则都将当空字符串“”处理）。
`bAppend`：true表示添加，false表示替换。

##  RestApi——支持主播相关信息查询

* **语法**

```
- (YouMeErrorCode_t)requestRestApi:(NSString*) strCommand strQueryBody:(NSString*) strQueryBody requestID:(int*)requestID;
```

* **功能**
Rest API , 向服务器请求额外数据。支持主播信息，主播排班等功能查询。需要的话，请联系我们获取命令详情文档。

* **参数说明**
`strCommand`：请求的命令字符串。
`strQueryBody`：请求需要的数据,json格式。
`requestID`：回传id,回调的时候传回，标识消息。

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

* **代码示例**

```
NSString *jsonString = @"{\"ChannelID\":\"123456\",\"AreaID\":0}";
int requestID = 0;
[[YMVoiceService getInstance] requestRestApi:@"query_talk_channel_user_count"  strQueryBody:jsonString  requestID: &requestID];
```

* **异步回调**

```
// requestID:回传ID
// iErrorCode:错误码
// strQuery:回传查询请求，json格式。command字段回传strCommand, query字段回传strQueryBody
// strResult:查询结果，json格式。
-(void)onRequestRestAPI: (int)requestID iErrorCode:(YouMeErrorCode_t) iErrorCode  query:(NSString*) strQuery  result:(NSString*) strResult {
}
```

* **回调示例**

```
strQuery:{"command":"query_talk_channel_user_count","query":"{\"ChannelID\":\"123456\",\"AreaID\":0}"}
strResult:{"ActionStatus":"OK","ChannelID":"123456","ErrorCode":0,"ErrorInfo":"","UserCount":0}
```

##  安全验证码设置

* **语法**
```
-(void)setToken:(NSString*) token;
```

* **功能**
设置身份验证的token，需要配合后台接口。

* **参数说明**
`token`：身份验证用token，设置为NULL或者空字符串，清空token值，不进行身份验证。

##  查询频道用户列表

* **语法**
```
-(YouMeErrorCode_t) getChannelUserList:(NSString*) channelID maxCount:(int)maxCount notifyMemChange:(bool)notifyMemChange ;
```

* **功能**
查询频道当前的用户列表， 并设置是否获取频道用户进出的通知。（必须自己在频道中）

* **参数说明**
`channelID`：要查询的频道ID。
`maxCount`：想要获取的最大人数。-1表示获取全部列表。
`notifyMemChange`：其他用户进出房间时，是否要收到通知。

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

* **异步回调**
```
// channelID:频道ID
// changeList:查询获得的用户列表，或变更列表。
-(void)onMemberChange:(NSString*) channelID changeList:(NSArray*) changeList {    
}
```


### 抢麦相关设置

* **语法**

```
- (YouMeErrorCode_t) setGrabMicOption:(NSString*) channelID mode:(int)mode maxAllowCount:(int)maxAllowCount maxTalkTime:(int)maxTalkTime voteTime:(unsigned int)voteTime;
```

* **功能**
抢麦相关设置（抢麦活动发起前调用此接口进行设置）

* **参数说明**
`pChannelID`：抢麦活动的频道id
`mode`：抢麦模式（1:先到先得模式；2:按权重分配模式）
`maxAllowCount`：允许能抢到麦的最大人数
`maxTalkTime`：允许抢到麦后使用麦的最大时间（秒）
`voteTime`：抢麦仲裁时间（秒），过了X秒后服务器将进行仲裁谁最终获得麦（仅在按权重分配模式下有效）

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

### 发起抢麦活动

* **语法**

```
- (YouMeErrorCode_t) startGrabMicAction:(NSString*) channelID strContent:(NSString*) pContent;
```

* **功能**
抢麦相关设置（抢麦活动发起前调用此接口进行设置）

* **参数说明**
`pChannelID`：抢麦活动的频道id
`pContent`：游戏传入的上下文内容，通知回调会传回此内容（目前只支持纯文本格式）

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

### 停止抢麦活动

* **语法**

```
- (YouMeErrorCode_t) stopGrabMicAction:(NSString*) channelID strContent:(NSString*) pContent;
```

* **功能**
停止抢麦活动

* **参数说明**
`pChannelID`：抢麦活动的频道id
`pContent`：游戏传入的上下文内容，通知回调会传回此内容（目前只支持纯文本格式）

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

### 发起抢麦请求

* **语法**

```
- (YouMeErrorCode_t) requestGrabMic:(NSString*) channelID score:(int)score isAutoOpenMic:(bool)isAutoOpenMic strContent:(NSString*) pContent;
```

* **功能**
停止抢麦活动

* **参数说明**
`pChannelID`：抢麦的频道id
`score`：积分（权重分配模式下有效，游戏根据自己实际情况设置）
`isAutoOpenMic`：抢麦成功后是否自动开启麦克风权限
`pContent`：游戏传入的上下文内容，通知回调会传回此内容（目前只支持纯文本格式）

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

### 释放抢到的麦

* **语法**

```
- (YouMeErrorCode_t) releaseGrabMic:(NSString*) channelID;
```

* **功能**
释放抢到的麦

* **参数说明**
`pChannelID`：抢麦的频道id

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

### 连麦相关设置

* **语法**

```
- (YouMeErrorCode_t) setInviteMicOption:(NSString*) channelID waitTimeout:(int)waitTimeout maxTalkTime:(int)maxTalkTime;
```

* **功能**
连麦相关设置（角色是频道的管理者或者主播时调用此接口进行频道内的连麦设置）

* **参数说明**
`pChannelID`：连麦的频道id
`waitTimeout`：等待对方响应超时时间（秒）
`maxTalkTime`：最大通话时间（秒）

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

### 发起连麦请求

* **语法**

```
- (YouMeErrorCode_t) requestInviteMic:(NSString*) channelID strUserID:(NSString*)pUserID strContent:(NSString*) pContent;
```

* **功能**
发起与某人的连麦请求（主动呼叫）

* **参数说明**
`pUserID`：被叫方的用户id
`pContent`：游戏传入的上下文内容，通知回调会传回此内容（目前只支持纯文本格式）

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

### 回应连麦请求

* **语法**

```
- (YouMeErrorCode_t) responseInviteMic:(NSString*) pUserID isAccept:(bool)isAccept strContent:(NSString*) pContent;
```

* **功能**
对连麦请求做出回应（被动应答）

* **参数说明**
`pUserID`：主叫方的用户id
`isAccept`：是否同意连麦
`pContent`：游戏传入的上下文内容，通知回调会传回此内容（目前只支持纯文本格式）

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

### 停止连麦

* **语法**

```
- (YouMeErrorCode_t) stopInviteMic;
```

* **功能**
停止连麦

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。


## 广播消息
* **语法**

```
- (YouMeErrorCode_t) sendMessage:(NSString*) channelID  strContent:(NSString*) strContent  requestID:(int*) requestID;
```

* **功能**
在语音频道内，广播一个文本消息。


* **参数说明**
`pChannelID`：频道ID（自己需要进入这个频道）。
`pContent`：要广播的文本内容。
`requestID`：用于标识消息的ID。

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

* **异步回调**
发送方会收到YOUME_EVENT_SEND_MESSAGE_RESULT回调，通知发送消息的结果。
频道内其他人收到YOUME_EVENT_MESSAGE_NOTIFY回调，通知消息内容。

```
//VoiceEngineCallback
//event:YOUME_EVENT_SEND_MESSAGE_RESULT: 发送消息的结果回调，param为requestID的字符串
//event:YOUME_EVENT_MESSAGE_NOTIFY:频道内其他人收到消息的通知。param为文本内容
- (void)onYouMeEvent:(YouMeEvent_t)eventType errcode:(YouMeErrorCode_t)iErrorCode roomid:(NSString *)roomid param:(NSString *)param;
```


## 把人踢出房间
* **语法**

```
- (YouMeErrorCode_t) kickOtherFromChannel:(NSString*) userID  channelID:(NSString*)channelID   lastTime:(int) lastTime;
```

* **功能**
把人踢出房间。


* **参数说明**
`userID`：被踢的用户ID。
`channelID`：从哪个房间踢出（自己需要在房间）。
`lastTime`：踢出后，多长时间内不允许再次进入。

* **返回值**
返回YOUME_SUCCESS才会有异步回调通知。其它返回值请参考[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

* **异步回调**

```
//VoiceEngineCallback
//event:YOUME_EVENT_KICK_RESULT: 踢人方收到，发送消息的结果回调，param为被踢者ID
//event:YOUME_EVENT_KICK_NOTIFY: 被踢方收到，被踢通知，会自动退出所在频道。param: （踢人者ID，被踢原因，被禁时间）
- (void)onYouMeEvent:(YouMeEvent_t)eventType errcode:(YouMeErrorCode_t)iErrorCode roomid:(NSString *)roomid param:(NSString *)param;
```


### 摄像头操作

#### 启动摄像头采集 
* **语法**

```objectivec
- (YouMeErrorCode_t)startCapture;
```

* **返回值**

    错误码，YOUME_SUCCESS - 表示成功,其他 - 具体错误码
    
#### 停止摄像头采集
    
* **语法**

```objectivec
- (YouMeErrorCode_t)stopCapture;
```

* **返回值**

    错误码，YOUME_SUCCESS - 表示成功,其他 - 具体错误码
    
#### 切换前置/后置摄像头  


* **语法**

```objectivec
- (YouMeErrorCode_t)switchCamera;
```

* **返回值**

    错误码，YOUME_SUCCESS - 表示成功,其他 - 具体错误码
    
    
#### 设置启动摄像头（前/后） 
设置下一次调用startCapture时，采用前置摄像头采集还是后置摄像头。
默认为前置摄像头。

* **语法**

```objectivec
- (YouMeErrorCode_t)setCaptureFrontCameraEnable:(bool)enable;
```
* **参数说明**
    `enable`: true-前置摄像头，false-后置摄像头。

* **返回值**

   错误码，YOUME_SUCCESS - 表示成功,其他 - 具体错误码

### 视频参数

#### 设置视频帧率   

* **语法**

```objectivec
- (YouMeErrorCode_t)setVideoFps:(int)fps;
```

* **参数说明**
  `fps`: 帧率（3-30），默认15帧

* **返回值**

    错误码，YOUME_SUCCESS - 表示成功,其他 - 具体错误码
    
#### 设置本地视频渲染回调的分辨率  

* **语法**

```objectivec
- (YouMeErrorCode_t)setVideoLocalResolutionWidth:(int)width height:(int)height;
```

* **参数说明**
    `width`: 宽
    `height`: 高

* **返回值**

    错误码，YOUME_SUCCESS - 表示成功,其他 - 具体错误码
    
  
#### 设置网络传输分辨率
设置视频网络传输过程的分辨率（第一路高分辨率）。
接受方收到视频回调的分辨率，等于发送方设置的网络分辨率。

* **语法**

```objectivec
- (YouMeErrorCode_t)setVideoNetResolutionWidth:(int)width height:(int)height;
```

* **参数说明**
    `width`: 宽
    `height`: 高

* **返回值**

    错误码，YOUME_SUCCESS - 表示成功,其他 - 具体错误码 
    
#### 设置视频数据上行的码率范围
进房间前设置。

* **语法**

```objectivec
- (void) setVideoCodeBitrate:(unsigned int) maxBitrate  minBitrate:(unsigned int ) minBitrate;
```

* **参数说明**
    `maxBitrate`: 最大码率，单位kbps
    `minBitrate`: 最小码率，单位kbps
    
    
#### 获取视频数据上行的当前码率

* **语法**

```objectivec
- (unsigned int) getCurrentVideoCodeBitrate;
```
    
* **返回值**

    视频数据上行的当前码率 
    
#### 设置视频编码是否采用VBR动态码率方式
设置视频编码是否采用VBR动态码率方式。
需要在进入房间前设置。

* **语法**

```objectivec
- (YouMeErrorCode_t) setVBR:( bool) useVBR;
```

* **参数说明**
    `useVBR`: 默认为false，true表示使用VBR模式，允许码率在约1.5倍范围内波动
    
* **返回值**

    错误码，YOUME_SUCCESS - 表示成功,其他 - 具体错误码 

#### 设置是否同意开启硬编硬解  
实际是否开启硬解，还跟服务器配置及硬件是否支持有关，要全部支持开启才会使用硬解。并且如果硬编硬解失败，也会切换回软解。
进房间前设置。

* **语法**

```objectivec
- (void) setVideoHardwareCodeEnable:(bool) bEnable;
```

* **参数说明**
    `bEnable`: true:开启，false:不开启
    
#### 获取是否同意开启硬编硬解  
实际是否开启硬解，还跟服务器配置及硬件是否支持有关，要全部支持开启才会使用硬解。并且如果硬编硬解失败，也会切换回软解。
进房间前设置。

* **语法**

```objectivec
- (bool) getVideoHardwareCodeEnable;
```

* **返回值**
    true:开启，false:不开启
    
#### 设置视频数据等待超时时间  
设置无视频帧渲染的等待超时时间。连接中的视频，超过设置的timeout时间没有收到数据，会得到YOUME_EVENT_OTHERS_VIDEO_SHUT_DOWN通知。

* **语法**

```objectivec
- (void) setVideoNoFrameTimeout:(int) timeout;
```

* **参数说明**
    `timeout`: 单位毫秒
    
    
### 渲染
#### 创建渲染
* **语法**

```objectivec
-(UIView*) createRender:(NSString*) userId parentView:(UIView*)parentView;

```

* **参数说明**
    `userId`: userId 用户ID
    `parentView`: 渲染父视图
    
* **返回值**
    @return 返回渲染视图OpenGLESView对象
    
* **回调**
    参见`视频数据回调`
    
#### 删除渲染
* **语法**

```objectivec
-(void) deleteRender:(NSString*) userId;

```

* **参数说明**
    `userId`: 用户ID
    
#### 清除渲染背景
* **语法**

```objectivec
-(void) cleanRender:(NSString*) userId;
```

* **参数说明**
    `userId`: 用户ID

#### 删除所有渲染
* **语法**

```objectivec
-(void) deleteAllRender;
```

#### 设置渲染模式
* **语法**

```objectivec
- (int)setRenderMode:(NSString*)userId mode:(YouMeVideoRenderMode_t) mode;
```

* **参数说明**
    `userId`: 用户ID
    `mode`: YouMeVideoRenderMode枚举类型
    
#### 渲染视图
`OpenGLESView`

* **语法**

```objectivec
//显示视频数据到View
- (void)displayYUV420pData:(void *)data width:(NSInteger)w height:(NSInteger)h;

//显示视频数据到View
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;
 
//设置渲染的背景色
- (void)setRenderBackgroudColor:(UIColor*) color;
//清除画面，清除后显示背景色
- (void)clearFrame;
```


### 音视频数据回调
#### 远端视频数据回调-软解模式
* **语法**

```objectivec
//protocol VoiceEngineCallback
- (void)onVideoFrameCallback: (NSString*)userId data:(void*) data len:(int)len width:(int)width height:(int)height fmt:(int)fmt timestamp:(uint64_t)timestamp;
```

* **参数说明**

    `userId`: 远端视频数据对应的userId
    `data`: 视频数据
    `len`: 数据长度
    `width`: 视频宽
    `height`: 视频高
    `fmt`: 视频数据格式，参见YOUME_VIDEO_FMT。
    `timestamp`: 时间戳
    

#### 远端视频数据回调-硬解模式
* **语法**

```objectivec
//protocol VoiceEngineCallback
- (void)onVideoFrameCallbackForGLES:(NSString*)userId  pixelBuffer:(CVPixelBufferRef)pixelBuffer timestamp:(uint64_t)timestamp;
```

* **参数说明**

    `userId`: 远端视频数据对应的userId
    `pixelBuffer`: 视频数据
    `timestamp`: 时间戳

#### 本地视频/合流视频数据回调-软解模式
* **语法**

```objectivec
//protocol VoiceEngineCallback
- (void)onVideoFrameMixedCallback: (void*) data len:(int)len width:(int)width height:(int)height fmt:(int)fmt timestamp:(uint64_t)timestamp;
```

* **参数说明**

    `data`: 视频数据
    `len`: 数据长度
    `width`: 视频宽
    `height`: 视频高
    `fmt`: 视频数据格式，参见YOUME_VIDEO_FMT。
    `timestamp`: 时间戳

#### 本地视频/合流视频数据回调-硬解模式
* **语法**

```objectivec
//protocol VoiceEngineCallback
- (void)onVideoFrameMixedCallbackForGLES:(CVPixelBufferRef)pixelBuffer timestamp:(uint64_t)timestamp;
```

* **参数说明**

    `pixelBuffer`: 视频数据
    `timestamp`: 时间戳
    
#### 音频回调
* **语法**

```objectivec
//protocol VoiceEngineCallback
- (void)onAudioFrameCallback: (NSString*)userId data:(void*) data len:(int)len timestamp:(uint64_t)timestamp;

```

* **参数说明**

    `userId`: userID 
    `data`: 视频帧数据
    `Len`: 视频数据大小
    `timestamp`: 时间戳，毫秒

#### 合流音频回调
* **语法**

```objectivec
//protocol VoiceEngineCallback
- (void)onAudioFrameMixedCallback: (void*)data len:(int)len timestamp:(uint64_t)timestamp;

```

* **参数说明**

    `data`: 视频帧数据
    `Len`: 视频数据大小
    `timestamp`: 时间戳，毫秒

    
### 高低两路视频流
SDK支持向服务器上传品质不同的两路流（不同的分辨率和码率），观看方根据自己的情况，设置拉取不同的流。
默认不上传第二路流。
    
#### 设置网络传输分辨率
设置视频上传第二路流的网络传输过程的分辨率。
接受方收到视频回调的分辨率，等于发送方设置的网络分辨率。
默认不传第二路流。如果设置了第二路流的分辨率，则会上传。

* **语法**

```objectivec
- (YouMeErrorCode_t)setVideoNetResolutionForSecond:(int)width height:(int)height;
```

* **参数说明**
    `width`: 宽
    `height`: 高

* **返回值**

    错误码，YOUME_SUCCESS - 表示成功,其他 - 具体错误码 

#### 设置视频数据上行码率范围
设置第二路流的上行码率范围。
进房间前设置。

* **语法**

```objectivec
- (void) setVideoCodeBitrateForSecond:(unsigned int) maxBitrate  minBitrate:(unsigned int ) minBitrate;
```

* **参数说明**
    `maxBitrate`: 最大码率，单位kbps
    `minBitrate`: 最小码率，单位kbps

* **返回值**

    错误码，YOUME_SUCCESS - 表示成功,其他 - 具体错误码 

#### 设置视频大小流控制模式
进房间前设置。

* **语法**

```objectivec
- (YouMeErrorCode_t)setVideoNetAdjustmode:(int)mode;
```

* **参数说明**
    `mode`: 模式 0:自动调整，1:手动调整

* **返回值**

    错误码，YOUME_SUCCESS - 表示成功,其他 - 具体错误码 


### 设置音视频统计数据时间间隔

* **语法**

```
- (void) setAVStatisticInterval:(int) interval ;
```

* **功能**
设置音视频统计数据时间间隔, 按间隔回调 "onAVStatistic"。

* **参数说明**
`interval`: 时间间隔，单位毫秒

* **返回值**
无。


### 设置Audio传输质量

* **语法**

```
- (void) setAudioQuality:(YOUME_AUDIO_QUALITY_t)quality;
```

* **功能**
设置Audio的传输质量

* **参数说明**
`quality`:0: low 1: high

* **返回值**
无。

#### 设置小流视频编码是否采用VBR
设置小流视频编码是否采用VBR动态码率方式。
需要在进入房间前设置。

* **语法**

```objectivec
- (YouMeErrorCode_t) setVBRForSecond:( bool) useVBR;
```

* **参数说明**
    `useVBR`: 默认为false，true表示使用VBR模式，允许码率在约1.5倍范围内波动
    
* **返回值**

    错误码，YOUME_SUCCESS - 表示成功,其他 - 具体错误码 
    
#### 查询多个用户视频信息
查询多个用户支持哪种流。

* **语法**

```objectivec
- (YouMeErrorCode_t) queryUsersVideoInfo:(NSMutableArray*)userArray;
```

* **参数说明**
    `userArray`: 用户ID列表

* **返回值**

    错误码，YOUME_SUCCESS - 表示成功,其他 - 具体错误码 
    
* **回调**

```objectivec
//eventType:YOUME_EVENT_QUERY_USERS_VIDEO_INFO
- (void)onYouMeEvent:(YouMeEvent_t)eventType errcode:(YouMeErrorCode_t)iErrorCode roomid:(NSString *)roomid param:(NSString *)param;
```

    
#### 设置观看用户哪路流
设置观看用户的哪一路流。如果设置了不支持的流，则采用默认的第一路流。

* **语法**

```objectivec
- (YouMeErrorCode_t) setUsersVideoInfo:(NSMutableArray*)userArray resolutionArray:(NSMutableArray*)resolutionArray;
```

* **参数说明**
    `userArray`: 用户ID列表
    `resolutionArray`: 用户对应分辨率列表(每一项为"0"-第一路流/"1"-第二路流)

* **返回值**

    错误码，YOUME_SUCCESS - 表示成功,其他 - 具体错误码 


### 外部采集模式
#### 设置是否由外部输入音视频
默认使用内部采集。
如果使用外部采集，需要自己采集音视频，然后把数据传入SDK。
在Init之前调用。

* **语法**

```objectivec
- (void)setExternalInputMode:(bool)bInputModeEnabled;
```

* **参数说明**

  `bInputModeEnabled`: true:外部输入模式，false:SDK内部采集模式

### 设置外部输入模式的语音采样率

* **语法**

```
- (YouMeErrorCode_t) setExternalInputSampleRate:(YOUME_SAMPLE_RATE_t)inputSampleRate mixedCallbackSampleRate:(YOUME_SAMPLE_RATE_t)mixedCallbackSampleRate;
```

* **功能**
设置外部输入模式的语音采样率

* **参数说明**
`inputSampleRate`:输入语音采样率
`mixedCallbackSampleRate`:mix后输出语音采样率

* **返回值**
如果成功则返回YOUME_SUCCESS，其它具体参见[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。


#### 输入音频数据
* **语法**

```objectivec
- (BOOL)inputAudioFrame:(void *)data Len:(int)len Timestamp:(uint64_t)timestamp;
```

* **参数说明**
   `data`: 指向PCM数据的缓冲区
	`len`: 音频数据的大小
	`timestamp`: 时间戳，单位毫秒

* **返回值**	
	成功/失败
	
#### 输入视频数据
视频数据输入(房间内其它用户会收到YOUME_EVENT_OTHERS_VIDEO_INPUT_START事件)

* **语法**

```objectivec
- (BOOL)inputVideoFrame:(void *)data Len:(int)len Width:(int)width Height:(int)height Fmt:(int)fmt Rotation:(int)rotation Mirror:(int)mirror Timestamp:(uint64_t)timestamp;
```

* **参数说明**
  `data`: 视频帧数据
  `Len`: 视频数据大小
  `Width`: 视频图像宽
  `Height`: 视频图像高
  `Fmt`: 视频格式
  `Rotation`: 视频旋转角度
  `Mirror`: 是否镜像
  `Timestamp`: 时间戳，单位毫秒

* **返回值**	
	成功/失败
	
#### 输入视频数据2
视频数据输入(房间内其它用户会收到YOUME_EVENT_OTHERS_VIDEO_INPUT_START事件)

* **语法**

```objectivec
- (BOOL)inputPixelBuffer:(CVPixelBufferRef)PixelBufferRef Width:(int)width Height:(int)height Fmt:(int)fmt Rotation:(int)rotation Mirror:(int)mirror Timestamp:(uint64_t)timestamp;
```

* **参数说明**
  `data`: 视频帧数据
  `Width`: 视频图像宽
  `Height`: 视频图像高
  `Fmt`: 视频格式
  `Rotation`: 视频旋转角度
  `Mirror`: 是否镜像
  `Timestamp`: 时间戳，单位毫秒

* **返回值**	
	成功/失败
	
#### 停止视频输入
停止视频数据输入(在inputVideoFrame之后调用，房间内其它用户会收到YOUME_EVENT_OTHERS_VIDEO_INPUT_STOP事件)

* **语法**

```objectivec
- (void)stopInputVideoFrame;
```

### 视频数据合流

#### 设置合流总尺寸
把远端的视频和本地自己的视频合到一个画面，称为合流。本接口设置合流画面总的尺寸。

* **语法**

```objectivec
- (void)setMixVideoWidth:(int)width Height:(int)height;
```

* **参数说明**

    `width`: 宽
    `height`: 高

#### 设置user的合流位置 
设置user的视频数据在合流画面中展现的位置和尺寸。

* **语法**

```objectivec
- (void)addMixOverlayVideoUserId:(NSString*)userId PosX:(int)x PosY:(int)y PosZ:(int)z Width:(int)width Height:(int)height;
```

* **参数说明**

    `userId`: 宽
    `PosX`: x坐标
    `PosY`: y坐标
    `PosZ`: z坐标，影响视频的展示层级
    `Width`: 宽
    `Height`: 高

#### 取消user的合流
取消对user的合流。

```objectivec
- (void)removeMixOverlayVideoUserId:(NSString*)userId;
```

* **参数说明**

    `userId`:  user ID 
    
#### 取消所有user的合流
取消对所有user的合流。

```objectivec
- (void)removeAllOverlayVideo;
```

### 设置本地视频镜像模式

* **语法**

```
- (int)setLocalVideoMirrorMode:(YouMeVideoMirrorMode_t) mode;
```

* **参数**
`mode`:镜像模式，参见YouMeVideoMirrorMode类型

* **返回值**
无。

### 美颜
#### 开启美颜  

* **语法**

```objectivec
- (YouMeErrorCode_t) openBeautify:(bool) open ;
```

* **参数说明**
    `open`: true-开启美颜，false-关闭美颜 

* **返回值**

    错误码，YOUME_SUCCESS - 表示成功,其他 - 具体错误码 
    
#### 设置美颜强度  

* **语法**

```objectivec
- (YouMeErrorCode_t) beautifyChanged:(float) param ;
```

* **参数说明**
    `param`: 美颜参数，0.0 - 1.0 ，默认为0，几乎没有美颜效果，0.5左右效果明显

* **返回值**

    错误码，YOUME_SUCCESS - 表示成功,其他 - 具体错误码 

#### 瘦脸开关 

* **语法**

```objectivec
- (YouMeErrorCode_t) stretchFace:(bool) stretch ;
```

* **参数说明**
    `stretch`: true 开启瘦脸，false关闭，默认 false

* **返回值**

    错误码，YOUME_SUCCESS - 表示成功,其他 - 具体错误码 

#### 打开/关闭 外部扩展滤镜回调

* **语法**

```objectivec
-(bool)setExternalFilterEnabled:(bool)enabled;
```

* **参数说明**
    `enabled`: true 开启外部扩展滤镜回调，false关闭，默认 false

* **返回值**
    true:成功，false:失败


### 自定义数据类型

#### 数据回调

* **语法**

```objectivec
//protocol VoiceEngineCallback
- (void)onCustomDataCallback: (const void*)data len:(int)len timestamp:(uint64_t)timestamp;
```

* **参数说明**

    `data`: 视频帧数据
    `timestamp`: 时间戳，单位毫秒   


#### 输入用户自定义数据

* **语法**

```objectivec
- (YouMeErrorCode_t) inputCustomData:(const void *)data Len:(int)len Timestamp:(uint64_t)timestamp;
```

* **参数说明**
    `data`: 自定义数据，要广播的自定义数据
    `len`: 数据长度，不能大于1024
    `timestamp`: 时间戳

### 其他操作
#### 屏蔽他人视频

* **语法**

```objectivec
- (YouMeErrorCode_t) maskVideoByUserId:(NSString*) strUserId  mask:(bool) mask;
```

* **参数说明**
    `userId`: 用户ID
    `mask`: true - 屏蔽, false - 恢复不屏蔽

* **返回值**

    错误码，YOUME_SUCCESS - 表示成功,其他 - 具体错误码 

#### 翻译

* **语法**

```objectivec
-(YouMeErrorCode_t) translateText:(unsigned int*) requestID  text:(NSString*)text destLangCode:(YouMeLanguageCode_t)destLangCode srcLangCode:(YouMeLanguageCode_t)srcLangCode;
```

* **功能**
翻译一段文字为指定语言。

* **参数说明**
`requestID`: 翻译请求的ID，传出参数，用于在回调中确定翻译结果是对应哪次请求。
`text`: 要翻译的内容。
`destLangCode`:要翻译成什么语言。
`srcLangCode`:要翻译的是什么语言。

* **返回值**
如果成功则返回YOUME_SUCCESS，其它具体参见[YouMeErrorCode类型定义](/doc/TalkStatusCode.html#youmeerrorcode类型定义)。

* **回调**

```c++
//errorcode：错误码
//requestID：请求ID（与translateText接口输出参数requestID一致）
//text：翻译结果
//srcLangCode：源语言编码
//destLangCode：目标语言编码
- (void)onTranslateTextComplete:(YouMeErrorCode_t)errorcode requestID:(unsigned int)requestID  text:(NSString*)text  srcLangCode:(YouMeLanguageCode_t)srcLangCode destLangCode:(YouMeLanguageCode_t)destLangCode;
```


##  反初始化

* **语法**
```
-(YouMeErrorCode_t)unInit;
```

* **功能**
反初始化引擎，可在完全退出应用时调用，以释放SDK所有资源，运行中不建议反初始化，仅需进退频道即可。

* **返回值**
如果成功则返回YOUME_SUCCESS，其它具体参见[YouMeErrorCode类型定义](/doc/TalkIosStatusCode.php#YouMeErrorCode类型定义)。

