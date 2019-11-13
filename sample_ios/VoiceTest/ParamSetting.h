//
//  ParamSetting.h
//  YmTalkTest
//
//  Created by zalejiang on 2017/11/27.
//  Copyright © 2017年 Youme. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ParamSetting : NSObject
{
@public
int videoWidth;
int videoHeight;
int fps;
int reportInterval;
int maxBitrate;
int minBitrate;
int farendLevel;
bool bHWEnable;
bool bHighAudio;
bool push;
bool fixQuality;

}

+(ParamSetting*)defaultParamSetting;
@end
