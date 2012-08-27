//
//  TCFaceDetectionViewController.h
//  TCFaceDetection
//
//  Created by Lee Tze Cheun on 8/23/12.
//  Copyright (c) 2012 Lee Tze Cheun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreImage/CoreImage.h>
#import <QuartzCore/QuartzCore.h>

@interface TCFaceDetectionViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UISwitch *switchControl;

- (IBAction)faceDetectionEnabled:(id)sender;

@end
