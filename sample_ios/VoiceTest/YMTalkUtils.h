//
//  YMTalkUtils.h
//  YmTalkTest
//
//  Created by zalejiang on 2017/11/27.
//  Copyright © 2017年 Youme. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "libyuv.h"
#import <CoreVideo/CoreVideo.h>

@interface YMTalkUtils : NSObject
+(NSString *)formatedSpeed:(float)bytes elapsed_milli:(float)elapsed_milli;
+(NSString*)strVersionFromInt:(uint32_t)nVersion;
+(CVPixelBufferRef)i420FrameToPixelBuffer:(const uint8*)data width:(int)width height:(int)height;
@end
