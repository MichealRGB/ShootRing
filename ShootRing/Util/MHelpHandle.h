//
//  MHelpHandle.h
//  ShootRing
//
//  Created by Micheal on 2017/5/25.
//  Copyright © 2017年 Micheal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#ifndef weakify
#if DEBUG
#if __has_feature(objc_arc)
#define weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
#else
#define weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
#endif
#else
#if __has_feature(objc_arc)
#define weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
#else
#define weakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
#endif
#endif
#endif

#ifndef strongify
#if DEBUG
#if __has_feature(objc_arc)
#define strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
#else
#define strongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
#endif
#else
#if __has_feature(objc_arc)
#define strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
#else
#define strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
#endif
#endif
#endif

@interface MHelpHandle : NSObject

// MARK : 获取当前时间戳
+ (NSString *) m_GetCurrentDateWithString;

// MARK : 运行python返回结果
+ (void) m_RunningPythonScriptsWithShellCode:(NSString *)cmdString
                                    Complete:(void (^)(NSString *))complete;

// MARK : 合并点和原靶图
+ (NSImage *) m_CompositeImageWithOverlayImage:(NSImage *)overlayImage
                                          Onto:(NSImage *)backGroundImage
                                    AtThePoint:(NSPoint)touchPoint;

+ (NSMutableArray *) m_ClearDataWithPythonResultString:(NSString *)pString;

// MARK : 计算最后的得分和次数
+ (NSString *) m_CalculatTotalRingsWithDataArr:(NSMutableArray *)dataArr;

@end
