//
//  MasterViewController.m
//  ShootRing
//
//  Created by Micheal on 2017/5/23.
//  Copyright © 2017年 Micheal. All rights reserved.
//

#import "MasterViewController.h"

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

@interface MasterViewController ()<NSTableViewDelegate,NSTableViewDataSource>

@property (weak) IBOutlet NSTableView *ringTableView;

@property (weak) IBOutlet NSButton *startButton;

@property (weak) IBOutlet NSImageView *ringImageView;

@property (nonatomic , copy) NSString *originalPath;

@property (nonatomic , strong) NSMutableArray *dataArr;

@property (nonatomic , strong) NSImage *originalImage;


@end

@implementation MasterViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    _originalImage = [self m_CompositeImageWithOverlayImage:[NSImage imageNamed:@"shootpoint1"] Onto:[NSImage imageNamed:@"113"] AtThePoint:NSMakePoint(-10, -10)];
    
    [self.ringImageView setImage:_originalImage];
    
    // -- 获取原始图片地址
    [self m_SaveTheRingImageToPathCompletePath:^(NSString *filePath) {
        
        _originalPath = filePath;
    }];
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView{
    
    return [self.dataArr count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    
    return self.dataArr[row];
}

- (IBAction)clearButtonDidPress:(id)sender {
    
    [self.dataArr removeAllObjects];
    
    [self.ringTableView reloadData];
    
    [self.ringImageView setImage:_originalImage];
}

- (IBAction)startButtonDidPress:(NSButton *)sender {
    
    @weakify(self);
    [self m_SaveTheRingImageToPathCompletePath:^(NSString *filePath) {
        @strongify(self);
        [self m_RunningPythonScriptsWithShellCode:[NSString stringWithFormat:@"cd ~; cd Desktop; cd ImageRender; python find_center2.py %@ %@",_originalPath,filePath] Complete:^(NSString *aString) {
            
            aString = [aString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            
            self.dataArr = [NSMutableArray arrayWithArray:[aString componentsSeparatedByString:@";"]];
        }];
    }];
    
    [self.ringTableView reloadData];
}

- (void)mouseDown:(NSEvent *)event{
    
    NSPoint point = [event locationInWindow];
    
    NSPoint afterPoint = [self.view convertPoint:point toView:self.ringImageView];
    
    // -- 需要加判断 要不然飞出去
    NSImage *aImage = [self m_CompositeImageWithOverlayImage:[NSImage imageNamed:@"shootpoint1"] Onto:self.ringImageView.image AtThePoint:afterPoint];
    
    [self.ringImageView setImage:aImage];
}

/**
 合并点和原靶

 @param overlayImage <#overlayImage description#>
 @param backGroundImage <#backGroundImage description#>
 @param touchPoint <#touchPoint description#>
 @return <#return value description#>
 */
- (NSImage *) m_CompositeImageWithOverlayImage:(NSImage *)overlayImage
                                          Onto:(NSImage *)backGroundImage
                                    AtThePoint:(NSPoint)touchPoint {
    
    NSImage *backGroundImageCopy = [backGroundImage copy];
    
    [backGroundImageCopy lockFocus];
    
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    
    [overlayImage drawInRect:NSMakeRect(touchPoint.x, touchPoint.y, [overlayImage size].width, [overlayImage size].width) fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
    
    [backGroundImageCopy unlockFocus];
    
    return backGroundImageCopy;
}

/**
 储存图片

 @param completePath <#completePath description#>
 */
- (void) m_SaveTheRingImageToPathCompletePath:(void (^)(NSString *))completePath{
    
    NSImage *viewImage = [[NSImage alloc] initWithData:[self.ringImageView dataWithPDFInsideRect:[self.ringImageView bounds]]];
    
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:[viewImage TIFFRepresentation]];

    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];

    NSData *imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];

    NSString *filePath = [NSString stringWithFormat:@"/Users/chao/Desktop/ImageRender/image1/file%@.jpg",[self m_GetCurrentDateWithString]];
    
    [imageData writeToFile:filePath atomically:NO];
    
    completePath(filePath);
}

- (void) m_RunningPythonScriptsWithShellCode:(NSString *)cmdString
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

- (NSString *) m_GetCurrentDateWithString{
    
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] * 1000;
    
    NSString *timeString = [NSString stringWithFormat:@"%f",interval];
    
    return timeString;
}

@end
