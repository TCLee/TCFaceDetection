//
//  TCAutoEnhanceViewController.m
//  TCFaceDetection
//
//  Created by Lee Tze Cheun on 8/23/12.
//  Copyright (c) 2012 Lee Tze Cheun. All rights reserved.
//

#import "TCAutoEnhanceViewController.h"
#import "MBProgressHUD.h"

#pragma mark - Private Interface

@interface TCAutoEnhanceViewController ()

@property (strong, nonatomic) CIContext *context;
@property (strong, nonatomic) UIImage *originalImage;
@property (strong, nonatomic) UIImage *enhancedImage;

@end

#pragma mark -

@implementation TCAutoEnhanceViewController

#pragma mark - View Controller Events

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Create the Core Image context to draw the auto-enhanced image.
    self.context = [CIContext contextWithOptions:nil];
    
    // Retain a reference to the original image before any
    // enhancements were made.
    self.originalImage = self.imageView.image;
}

- (void)viewDidUnload
{
    // Release the view controller's strong references.
    self.context = nil;
    self.originalImage = nil;
    self.enhancedImage = nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UI Actions

/* User toggled the auto-enhance switch to turn on/off auto-enhance. */
- (IBAction)autoEnhanceEnabled:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]]) {
        UISwitch *switchControl = (UISwitch *)sender;
        
        if (switchControl.isOn) {
            // If we've already auto-enhanced the photo, we'll just reuse
            // the previous result.
            if (self.enhancedImage) {
                self.imageView.image = self.enhancedImage;
            } else {
                // Apply the auto-enhance filters onto the image to improve
                // its quality.
                [self autoEnhancePhoto:self.imageView.image];                
            }
        } else {
            // Reset to original image.
            self.imageView.image = self.originalImage;
        }
    }
}

#pragma mark - Auto Enhance Photo

/* 
 Auto-enhance given photo to improve its quality.
 This method will auto-enhance the image asynchronously. 
 */
- (void)autoEnhancePhoto:(UIImage *)photo
{
    // Show a progress HUD. Auto-enhance will take quite a while to complete.
    MBProgressHUD *progressHUD = [MBProgressHUD showHUDAddedTo:self.imageView
                                                      animated:YES];
    progressHUD.dimBackground = YES;
    
    // Disable the switch control while performing auto-enhance.
    self.switchControl.enabled = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // Core Image only works with CIImage objects. So, we'll
        // create one from the UIImage instance.
        CIImage *inputImage = [CIImage imageWithCGImage:[photo CGImage]];
        
        // Ask CIImage for an array of filters to apply onto the photo
        // to improve the photo quality.
        NSArray *adjustmentFilters = [inputImage autoAdjustmentFilters];
        
        // Combine all the filters to apply on the photo.
        for (CIFilter *filter in adjustmentFilters) {
            [filter setValue:inputImage forKey:kCIInputImageKey];
            inputImage = [filter outputImage];
        }
        
        // Renders the filtered image as a Quartz 2D image.
        CGImageRef outputImage = [self.context createCGImage:inputImage
                                                    fromRect:[inputImage extent]];
        
        // Switch back to main thread to update the UI, after we're done processing.
        dispatch_async(dispatch_get_main_queue(), ^{
            // Display the auto-enhanced photo on the image view.
            self.imageView.image = [UIImage imageWithCGImage:outputImage];
            
            // Release the Quartz 2D image that the Core Image context created.
            CGImageRelease(outputImage);
            
            // Retain a reference to the auto-enhanced photo, so that we do not
            // need to process it again the next time.
            self.enhancedImage = self.imageView.image;
            
            // Re-enable the switch control.
            self.switchControl.enabled = YES;
            
            // Dismiss the progress HUD.
            [MBProgressHUD hideHUDForView:self.imageView animated:YES];
        });
    });
}

@end
