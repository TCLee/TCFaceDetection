//
//  TCFaceDetectionViewController.m
//  TCFaceDetection
//
//  Created by Lee Tze Cheun on 8/23/12.
//  Copyright (c) 2012 Lee Tze Cheun. All rights reserved.
//

#import "TCFaceDetectionViewController.h"
#import "MBProgressHUD.h"

#pragma mark - Private Interface

@interface TCFaceDetectionViewController ()

@property (strong, nonatomic) UIImage *originalImage;
@property (strong, nonatomic) UIImage *resultImage;

@end

#pragma mark -

@implementation TCFaceDetectionViewController

#pragma mark - View Controller Events

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Retain a reference to the original image.
    self.originalImage = self.imageView.image;
}

- (void)viewDidUnload
{
    // Release all the view controller's strong references.
    self.originalImage = nil;
    self.resultImage = nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UI Actions

/* User toggled the face detection switch to enable or disable face detection. */
- (IBAction)faceDetectionEnabled:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]]) {
        UISwitch *switchControl = (UISwitch *)sender;
        
        if (switchControl.isOn) {
            // If we've detected the faces before, we'll reuse the result.
            if (self.resultImage) {
                self.imageView.image = self.resultImage;
            } else {
                // Face detection enabled. Highlight faces on photo.
                [self findFacesOnPhoto:self.imageView.image];                
            }
        } else {
            // Face detection disabled. Reset to original image.
            self.imageView.image = self.originalImage;
        }
    }
}

#pragma mark - Face Detection

/* 
 Find all the faces on given photo and highlight them.
 This method with detect faces on the photo asynchronously.
 */
- (void)findFacesOnPhoto:(UIImage *)photo
{
    // Show a progress HUD while we attempt to detect faces on the photo.    
    MBProgressHUD *progreesHUD = [MBProgressHUD showHUDAddedTo:self.imageView
                                                      animated:YES];
    progreesHUD.dimBackground = YES;
    
    // Disable the switch control while performing face detection.
    self.switchControl.enabled = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // Core Image needs to work on a CIImage object.
        CIImage *image = [CIImage imageWithCGImage:[photo CGImage]];
        
        // Create a face detector to detect the faces in the photo.
        // We'll use the maximum accuracy for a still image.
        CIDetector *faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                                      context:nil
                                                      options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
        
        // Get all the face features detected in the photo.
        NSArray *features = [faceDetector featuresInImage:image];
        
        // Switch back to main thread to update the UI, after we're done processing.
        dispatch_async(dispatch_get_main_queue(), ^{
            // Draw the photo with the detected face features highlighted.
            [self drawPhoto:photo withHighlightedFaceFeatures:features];
            
            // Save the result image, so that we can reuse it.
            self.resultImage = self.imageView.image;
            
            // Re-enable the switch control.
            self.switchControl.enabled = YES;
            
            // Dismiss the progress HUD.
            [MBProgressHUD hideHUDForView:self.imageView animated:YES];
        });
    });
}

/* 
 Draw the photo with the detected face features highlighted.
 This method must be called from the main thread as it modifies the UI.
 */
- (void)drawPhoto:(UIImage *)photo withHighlightedFaceFeatures:(NSArray *)features
{
    // Get the grahics context to begin drawing.
    UIGraphicsBeginImageContextWithOptions(photo.size, YES, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Draw the photo to the current graphics context.
    [photo drawInRect:self.imageView.bounds];
    
    // Core Image coordinate system origin is at the bottom left corner and
    // UIKit is at the top left corner.
    // We need to translate the coordinates before drawing them to UIKit.
    CGContextTranslateCTM(context, 0, self.imageView.bounds.size.height);
    CGContextScaleCTM(context, 1.0f, -1.0f);        
    
    CGContextSetLineWidth(context, 1.5f);
    
    // Loop through all the detected faces in the photo.
    for (CIFaceFeature *faceFeature in features) {
        // Draw a highlight around the subject's face.
        [self drawFaceHighlightInContext:context atRect:[faceFeature bounds]];
        
        // Highlight the subject's left eye (if detected).
        if ([faceFeature hasLeftEyePosition]) {
            [self drawFeatureHighlightInContext:context atPoint:faceFeature.leftEyePosition];
        }
        
        // Highlight the subject's right eye (if detected).
        if ([faceFeature hasRightEyePosition]) {
            [self drawFeatureHighlightInContext:context atPoint:faceFeature.rightEyePosition];
        }
        
        // Highlight the subject's mouth (if detected).
        if ([faceFeature hasMouthPosition]) {
            [self drawFeatureHighlightInContext:context atPoint:faceFeature.mouthPosition];
        }
    }
    
    // Show the resulting image with face features highlighted on the UIImageView.
    self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
}

/* Draw a filled rectangle around the detected face's bounds rectangle. */
- (void)drawFaceHighlightInContext:(CGContextRef)context atRect:(CGRect)faceRect
{
    CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 0.3f);
    CGContextSetRGBStrokeColor(context, 0.0f, 1.0f, 0.0f, 1.0f);    
    CGContextAddRect(context, faceRect);
    CGContextDrawPath(context, kCGPathFillStroke);
}

/* Draw a circle around the center point of the detected face feature 
   (i.e. eyes and mouth). */
- (void)drawFeatureHighlightInContext:(CGContextRef)context atPoint:(CGPoint)featurePoint
{
    CGContextSetRGBStrokeColor(context, 1.0f, 0.0f, 0.0f, 1.0f);
    CGContextAddArc(context, featurePoint.x, featurePoint.y, 13.0f, 0, M_PI * 2, 1);
    CGContextDrawPath(context, kCGPathStroke);
}

@end
