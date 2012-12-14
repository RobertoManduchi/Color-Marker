#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
//opencv

/*!
 @class	AVController 
 @author Benjamin Loulier
 
 @brief    Controller to demonstrate how we can have a direct access to the camera using the iPhone SDK 4
 */
@interface MyAVController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate> {
	AVCaptureSession *_captureSession;
	UIImageView *_imageView;
	CALayer *_customLayer;
	AVCaptureVideoPreviewLayer *_prevLayer;
    
    BOOL    _shouldTakeSnapshot;
    
    int     _indPicture;
    float   time1,time2;
    
    
//    IBOutlet UIStepper *setMaxFramesPerSecond;
//    IBOutlet UILabel *maxFramesPerSecond;
    
}
//@property (retain, nonatomic) IBOutlet UILabel *maxFramesPerSecond;
@property (retain, nonatomic) IBOutlet UILabel *actualFramesPerSecond;
@property (retain, nonatomic) IBOutlet UIStepper *setMaxFramesPerSecond;
@property (retain, nonatomic) IBOutlet UILabel *maxFramesPerSecond;
@property (retain, nonatomic) IBOutlet UIStepper *setMarkerID;
@property (retain, nonatomic) IBOutlet UILabel *markerID;
@property (retain, nonatomic) IBOutlet UIStepper *setMaxDistance;
@property (retain, nonatomic) IBOutlet UILabel *maxDistance;
@property (retain, nonatomic) IBOutlet UIStepper *setWhichLens; // 0: no additional lens; 1: wide angle; 2: fisheye
@property (retain, nonatomic) IBOutlet UILabel *whichLens;
@property (retain, nonatomic) IBOutlet UIStepper *setModalityForDirections; // 0: noDirections; 1: volume; 2: volume + speech
@property (retain, nonatomic) IBOutlet UILabel *modalityForDirections;

// I think that this should be in the @interface
- (IBAction)takeSnapshot:(id)sender;

@property (nonatomic) BOOL shouldTakeSnapshot;
@property (nonatomic) int indPicture;

/*!
 @brief	The capture session takes the input from the camera and capture it
 */
@property (nonatomic, retain) AVCaptureSession *captureSession;

/*!
 @brief	The UIImageView we use to display the image generated from the imageBuffer
 */
@property (nonatomic, retain) UIImageView *imageView;
/*!
 @brief	The CALayer we use to display the CGImageRef generated from the imageBuffer
 */
@property (nonatomic, retain) CALayer *customLayer;
/*!
 @brief	The CALAyer customized by apple to display the video corresponding to a capture session
 */
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *prevLayer;

/*!
 @brief	This method initializes the capture session
 */
- (void)initCapture;
//-(UIImage *) UIImageFromBits:(uint8_t *)planar_addr height:(size_t)height width:(size_t)width;
-(UIImage *) UIImageFromBits:(uint8_t *)planar_addr height:(size_t)height width:(size_t)width bytesPerRow: (size_t)bytesPerRow;
@end

