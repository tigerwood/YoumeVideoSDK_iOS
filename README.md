# Video SDK for iOS 使用指南

游密实时视频SDK，如果需要用git克隆到本地需要运行命令语句：git lfs clone https://github.com/youmesdk/YoumeVideoSDK_iOS 

## 适用范围
本文档适用于游密实时音视频引擎（Video SDK）Xcode开发环境下接入。

## SDK目录概述
语音SDK中有两个子文件夹：include、lib,下面依次介绍下这两个子文件夹。

1. `include`：SDK的头文件。
  重点介绍inlude下的需要使用到的重要文件。
    * `YMVoiceService.h`封装了语音SDK的全部功能接口，集成方可通过[YMVoiceService getInstance]直接调用。
    * `VoiceEngineCallback.h`包含需要实现的语音SDK的回调接口协议。
    * `YouMeConstDefine.h`包含错误码定义等各类枚举类型定义。
2. `lib`：iOS库文件，包含libyoume_voice_engine.a、libYouMeCommon.a 和 libffmpeg3.3.a 文件。

## 开发环境集成
 将SDK放置到xcode工程目录下（可视实际情况自行放置），如下图所示：
  
  ![](https://youme.im/doc/images/talk_ios_xcode_project.png)

### iOS系统Xcode开发环境配置
添加头文件和依赖库:
1. 打开XCode工程，找到工程目录，新建一个文件夹（可命名为SDKInclude），然后将SDK下的include文件夹里的头文件夹都加入进来(右键点击选择“Add Files to ...”)

  ![](https://youme.im/doc/images/talk_ios_xcode_addFiles.png)

2. 添加库文件路径：Build Settings -> Search Paths -> Library Search Paths，直接将 SDK 的 ios 文件夹拖到 Xcode 需要填入的位置，然后路径会自动生成;
3. 添加依赖库：在Build Phases  -> Link Binary With Libraries下添加：`libyoume_voice_engine.a`、`libYouMeCommon.a`、`libffmpeg3.3.a`、`libc++.tbd`、`libsqlite3.0.tbd`、`libz.dylib`、`libz.1.2.5.tbd`、`libresolv.9.tbd`、`SystemConfiguration.framework`、`CoreTelephony.framework`、`VideoToolbox.framework`、`AVFoundation.framework`、`AudioToolBox.framework`、`CFNetwork.framework`。
4. 为iOS10以上版本添加录音权限配置
iOS10系统使用录音权限，需要在target的`info.plist`中新加`NSMicrophoneUsageDescription`键，值为字符串(授权弹窗出现时提示给用户)。首次录音时会向用户申请权限。配置方式如下：
![iOS10录音权限配置](https://youme.im/doc/images/im_iOS_record_config.jpg)
5. 为iOS10以上版本添加摄像头使用权限配置
iOS10系统使用摄像头权限，需要在target的`info.plist`中新加`NSCameraUsageDescription`键，值为字符串(授权弹窗出现时提示给用户)。首次开启摄像头时会向用户申请权限。

### 备注：
[详细接口介绍可查看“Video SDK for iOS API手册”文档](https://github.com/youmesdk/YoumeVideoSDK_iOS/blob/master/Video%20SDK%20for%20iOS-API%E6%89%8B%E5%86%8C.md)

实时视频Demo下载地址：->[Youme Video Demo for iOS](https://github.com/youmesdk/YoumeVideoDemo_iOS)

