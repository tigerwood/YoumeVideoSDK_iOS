//
//  YMTalkUtils.m
//  YmTalkTest
//
//  Created by zalejiang on 2017/11/27.
//  Copyright © 2017年 Youme. All rights reserved.
//

#import "YMTalkUtils.h"
#import <CoreVideo/CoreVideo.h>
#include <objc/runtime.h>
#import "libyuv.h"

@implementation YMTalkUtils


+(NSString *)formatedSpeed:(float)bytes elapsed_milli:(float)elapsed_milli {
    if (elapsed_milli <= 0) {
        return @"N/A";
    }
    
    if (bytes <= 0) {
        return @"0 KB/s";
    }
    
    float bytes_per_sec = ((float)bytes) * 1000.f /  elapsed_milli;
    if (bytes_per_sec >= 1000 * 1000) {
        return [NSString stringWithFormat:@"%.2f MB/s", ((float)bytes_per_sec) / 1000 / 1000];
    } else if (bytes_per_sec >= 1000) {
        return [NSString stringWithFormat:@"%.1f KB/s", ((float)bytes_per_sec) / 1000];
    } else {
        return [NSString stringWithFormat:@"%ld B/s", (long)bytes_per_sec];
    }
}


+(NSString*)strVersionFromInt:(uint32_t)nVersion {
    int main_ver = (nVersion >> 28) & 0xF;
    int minor_ver = (nVersion >> 22) & 0x3F;
    int release_number = (nVersion >> 14) & 0xFF;
    int build_number = nVersion & 0x00003FFF;
    
    return [NSString stringWithFormat:@"%d.%d.%d.%d", main_ver, minor_ver, release_number, build_number];
}


+(CVPixelBufferRef)i420FrameToPixelBuffer:(const uint8*)data width:(int)width height:(int)height
{
    if (data == nil) {
        return NULL;
    }
    CVPixelBufferRef pixelBuffer = NULL;
    NSDictionary *pixelBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSDictionary dictionary], (id)kCVPixelBufferIOSurfacePropertiesKey, nil];
    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                          width,
                                          height,
                                          kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                                          (__bridge CFDictionaryRef)pixelBufferAttributes,
                                          &pixelBuffer);
    
    if (result != kCVReturnSuccess) {
        NSLog(@"Failed to create pixel buffer: %d", result);
        return NULL;
    }
    result = CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    if (result != kCVReturnSuccess) {
        CFRelease(pixelBuffer);
        NSLog(@"Failed to lock base address: %d", result);
        return NULL;
    }
    uint8 *dstY = (uint8 *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    int dstStrideY = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    uint8* dstUV = (uint8*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    int dstStrideUV = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    
    int ret = I420ToNV12((const uint8*)data, width,
                         data+(width*height), (width+1) / 2,
                         data+(width*height) + (width+1) / 2 * ((height+1) / 2), (width+1) / 2,
                         dstY, dstStrideY, dstUV, dstStrideUV,
                         width, height);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    if (ret) {
        NSLog(@"Error converting I420 VideoFrame to NV12: %d", result);
        CFRelease(pixelBuffer);
        return NULL;
    }
    
    return pixelBuffer;
}

@end
