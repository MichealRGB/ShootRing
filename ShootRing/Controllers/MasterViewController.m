//
//  MasterViewController.m
//  ShootRing
//
//  Created by Micheal on 2017/5/23.
//  Copyright © 2017年 Micheal. All rights reserved.
//

#import "MasterViewController.h"
#import "DJProgressHUD.h"
#import "MHelpHandle.h"

@interface MasterViewController ()<NSTableViewDelegate,NSTableViewDataSource>

@property (weak) IBOutlet NSTableView *ringTableView;

@property (weak) IBOutlet NSButton *startButton;

@property (weak) IBOutlet NSImageView *ringImageView;

@property (nonatomic , copy) NSString *originalPath;

@property (nonatomic , strong) NSMutableArray *dataArr;

@property (nonatomic , strong) NSImage *originalImage;

@property (weak) IBOutlet NSTextField *scoreLabel;

@end

@implementation MasterViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self confirmOriginalImagePath];
}

- (IBAction)clearButtonDidPress:(id)sender {
    
    [self.dataArr removeAllObjects];
    
    [self.ringTableView reloadData];
    
    [self.scoreLabel setStringValue:@"0 环"];
    
    [self.ringImageView setImage:_originalImage];
}

- (IBAction)startButtonDidPress:(NSButton *)sender {
    
    [DJProgressHUD showStatus:@"正在处理请稍后" FromView:self.view];
    
    @weakify(self);
    [self m_SaveTheRingImageToPathCompletePath:^(NSString *filePath) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            @strongify(self);
 
            [MHelpHandle m_RunningPythonScriptsWithShellCode:[NSString stringWithFormat:@"cd ~; cd Desktop; cd ImageRender; python find_center2.py %@ %@",_originalPath,filePath] Complete:^(NSString *aString) {
                
                self.dataArr = [MHelpHandle m_ClearDataWithPythonResultString:aString];
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [DJProgressHUD dismiss];
                
                [self.ringTableView reloadData];
                
                [self.scoreLabel setStringValue:[MHelpHandle m_CalculatTotalRingsWithDataArr:self.dataArr]];
            });
        });
    }];
}

- (void)mouseDown:(NSEvent *)event{
    
    NSPoint point = [event locationInWindow];
    
    NSPoint afterPoint = [self.view convertPoint:point toView:self.ringImageView];
    
    NSImage *aImage = [MHelpHandle m_CompositeImageWithOverlayImage:[NSImage imageNamed:@"shootpoint1"] Onto:self.ringImageView.image AtThePoint:afterPoint];
    
    [self.ringImageView setImage:aImage];
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

    NSString *filePath = [NSString stringWithFormat:@"/Users/chao/Desktop/ImageRender/image1/file%@.jpg",[MHelpHandle m_GetCurrentDateWithString]];
    
    [imageData writeToFile:filePath atomically:NO];
    
    completePath(filePath);
}

- (void) confirmOriginalImagePath{
    
    _originalImage = [MHelpHandle m_CompositeImageWithOverlayImage:[NSImage imageNamed:@"shootpoint1"] Onto:[NSImage imageNamed:@"113"] AtThePoint:NSMakePoint(-10, -10)];
    
    [self.ringImageView setImage:_originalImage];
    
    // -- 获取原始图片地址
    [self m_SaveTheRingImageToPathCompletePath:^(NSString *filePath) {
        
        _originalPath = filePath;
    }];
}

#pragma mark -
#pragma mark - TableViewDelegate && DataSoure -
- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView{
    
    return [self.dataArr count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    
    return self.dataArr[row];
}

@end
