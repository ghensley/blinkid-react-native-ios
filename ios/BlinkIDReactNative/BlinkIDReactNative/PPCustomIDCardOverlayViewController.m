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

- (void)setTooltip: (NSString*) tooltipText {
    self.tooltipText = tooltipText;
}

- (void)setRatio: (CGFloat) boxRatio {
    self.boxRatio = boxRatio;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.idCardSubview.tooltipLabel.text = self.tooltipText;
    self.idCardSubview.viewfinderWidthToHeightRatio = self.boxRatio;
}
@end
