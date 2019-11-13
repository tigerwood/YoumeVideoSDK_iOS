//
//  ParamSetting.m
//  YmTalkTest
//
//  Created by zalejiang on 2017/11/27.
//  Copyright © 2017年 Youme. All rights reserved.
//

#import "ParamSetting.h"

@implementation ParamSetting

+(ParamSetting*)defaultParamSetting {
    ParamSetting* params = [[ParamSetting alloc]init];
    params->videoWidth = 480;
    params->videoHeight = 640;
    params->reportInterval = 5000;
    params->maxBitrate = 0;
    params->minBitrate = 0;
    params->farendLevel = 10;
    params->bHWEnable = true;
    params->bHighAudio = false ;
    params->push = false;
    params->fps = 20;
    params->fixQuality = false;
    
    return params;
}
@end
