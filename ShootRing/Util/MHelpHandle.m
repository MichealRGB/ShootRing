//
//  MHelpHandle.m
//  ShootRing
//
//  Created by Micheal on 2017/5/25.
//  Copyright © 2017年 Micheal. All rights reserved.
//

#import "MHelpHandle.h"

@implementation MHelpHandle

+ (NSString *) m_GetCurrentDateWithString{
    
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] * 1000;
    
    NSString *timeString = [NSString stringWithFormat:@"%f",interval];
    
    return timeString;
}

+ (void) m_RunningPythonScriptsWithShellCode:(NSString *)cmdString
                                    Complete:(void (^)(NSString *))complete{
    
    NSTask *task = [[NSTask alloc] init];
    
    [task setLaunchPath: @"/bin/bash"];
    
    // MARK :  -c 用来执行string-commands
    NSArray *arguments = [NSArray arrayWithObjects: @"-c", cmdString, nil];
    [task setArguments: arguments];
    
    NSPipe *pipe = [NSPipe pipe];
    
    [task setStandardOutput:pipe];
    
    NSFileHandle *fileHandle = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *resultData = [fileHandle readDataToEndOfFile];
    
    complete([[NSString alloc] initWithData:resultData encoding: NSUTF8StringEncoding]);
}

+ (NSImage *) m_CompositeImageWithOverlayImage:(NSImage *)overlayImage
                                          Onto:(NSImage *)backGroundImage
                                    AtThePoint:(NSPoint)touchPoint {
    
    NSImage *backGroundImageCopy = [backGroundImage copy];
    
    [backGroundImageCopy lockFocus];
    
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    
    [overlayImage drawInRect:NSMakeRect(touchPoint.x, touchPoint.y, [overlayImage size].width, [overlayImage size].width) fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
    
    [backGroundImageCopy unlockFocus];
    
    return backGroundImageCopy;
}

+ (NSMutableArray *) m_ClearDataWithPythonResultString:(NSString *)pString{
    
    NSMutableArray *tmpArr = [NSMutableArray array];
    
    pString = [pString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    tmpArr = [NSMutableArray arrayWithArray:[pString componentsSeparatedByString:@";"]];
    
    [tmpArr enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj && [obj isEqualToString:@""]) {
            
            [tmpArr removeObject:obj];
        }
    }];
    
    return tmpArr;
}

+ (NSString *) m_CalculatTotalRingsWithDataArr:(NSMutableArray *)dataArr{
    
    NSMutableArray *tmpArr = [NSMutableArray array];
    
    [dataArr enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (![obj isEqualToString:@""]) {
            
            obj = [obj stringByReplacingOccurrencesOfString:@"脱靶" withString:@"0"];
            
            NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
            
            int remainSecond = [[obj stringByTrimmingCharactersInSet:nonDigits] intValue];
            
            [tmpArr addObject:@(remainSecond)];
        }
    }];
    
    NSNumber *totalRings = [tmpArr valueForKeyPath:@"@sum.floatValue"];
    
    NSString *rString = [NSString stringWithFormat:@"%@环--%lu枪",[totalRings stringValue],(unsigned long)[tmpArr count]];
    
    return rString;
}

@end
