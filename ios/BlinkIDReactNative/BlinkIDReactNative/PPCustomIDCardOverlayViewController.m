//
//  PPCustomIDCardOverlayViewController.m
//  BlinkIDReactNative
//
//  Created by Greyson Hensley on 7/14/17.
//  Copyright © 2017 Jura Skrlec. All rights reserved.
//
#import <MicroBlink/MicroBlink.h>
#import "PPCustomIDCardOverlayViewController.h"

@implementation PPCustomIDCardOverlayViewController : PPIDCardOverlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.idCardSubview.tooltipLabel.text = @"Scan the barcode";
    self.idCardSubview.viewfinderWidthToHeightRatio = 85.60 / 30;
}
@end
