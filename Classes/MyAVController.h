#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreMotion/CoreMotion.h>
#import "CMAudio.h"

//opencv
@interface MyAVController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate> {
	AVCaptureSession *_captureSession;
	UIImageView *_imageView;
	CALayer *_customLayer;
	AVCaptureVideoPreviewLayer *_prevLayer;
    
    //    BOOL    _shouldTakeSnapshot;
    //
    //    int     _indPicture;
    float   time1,time2;
    
    double focalLengthInPixels[3];
    
    BOOL    useShortBeepSequence;
    
    //    IBOutlet UIStepper *setMaxFramesPerSecond;
    //    IBOutlet UILabel *maxFramesPerSecond;
    
}
//@property (retain, nonatomic) IBOutlet UILabel *maxFramesPerSecond;

@property (retain, nonatomic) IBOutlet UILabel *actualFramesPerSecond;
//@property (retain, nonatomic) IBOutlet UIStepper *setMaxFramesPerSecond;
@property (retain, nonatomic) IBOutlet UIStepper *maxFramesPerSecondSetter;
//@property (retain, nonatomic) IBOutlet UILabel *maxFramesPerSecond;
@property (retain, nonatomic) IBOutlet UILabel *maxFramesPerSecond;
@property (retain, nonatomic) IBOutlet UILabel *maxFramesPerSecondLabel;

//@property (retain, nonatomic) IBOutlet UIStepper *setMarkerID;
@property (retain, nonatomic) IBOutlet UIStepper *markerIDSetter;
@property (retain, nonatomic) IBOutlet UILabel *markerID;
//@property (retain, nonatomic) IBOutlet UIStepper *setMaxDistance;
@property (retain, nonatomic) IBOutlet UIStepper *maxDistanceSetter;
@property (retain, nonatomic) IBOutlet UILabel *markerIDLabel;

@property (retain, nonatomic) IBOutlet UILabel *maxDistance;
@property (retain, nonatomic) IBOutlet UILabel *maxDistanceLabel;

//@property (retain, nonatomic) IBOutlet UIStepper *setWhichLens; // 0: no additional lens; 1: wide angle; 2: fisheye
@property (retain, nonatomic) IBOutlet UIStepper *whichLensSetter;
@property (retain, nonatomic) IBOutlet UILabel *whichLens;
@property (retain, nonatomic) IBOutlet UILabel *whichLensLabel;

//@property (retain, nonatomic) IBOutlet UIStepper *setModalityForDirections; // 0: noDirections; 1: volume; 2: volume + speech
@property (retain, nonatomic) IBOutlet UIStepper *modalityForDirectionsSetter;
@property (retain, nonatomic) IBOutlet UILabel *modalityForDirections;
@property (retain, nonatomic) IBOutlet UILabel *modalityForDirectionLabel;

@property (retain, nonatomic) IBOutlet UIButton *snapshotButton;


@property CMAudio* theBeep1;
@property CMAudio* theBeep2;
@property CMAudio* theBeep2Short;

// RM 12/13
@property CMAudio* rotateUp;
@property CMAudio* rotateDown;
@property CMAudio* rotateLeft;
@property CMAudio* rotateRight;
@property CMAudio* rotateLeftAndUp;
@property CMAudio* rotateRightAndUp;
@property CMAudio* rotateLeftAndDown;
@property CMAudio* rotateRightAndDown;

@property CMMotionManager *motionManager;

@property (nonatomic, retain) NSFileHandle *outFileHandler;

@property BOOL IS_TOO_INCLINED;

@property BOOL CHECK_DISTANCE;
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

@property int nRecorded;
@property int framesPerSecond;
@property int frameCount;
@property float start_time;
@property float mainStartTime;
@property float startTimeExpLock;

@property int countFramesForLock;

@property double isTooInclinedStartTime;

@property double timeSinceLastDirection;

@property size_t height;
@property size_t width;

@property BOOL detectorIsRunning;

@property int centerRegionHalfSizeX;
@property int centerRegionHalfSizeY;

//@property (retain, nonatomic) IBOutlet UIStepper *maxFramesPerSecond;

/*!
 @brief	This method initializes the capture session
 */

- (MyAVController *) init;
- (void)initCapture;
//-(UIImage *) UIImageFromBits:(uint8_t *)planar_addr height:(size_t)height width:(size_t)width;
-(UIImage *) UIImageFromBits:(uint8_t *)planar_addr height:(size_t)height width:(size_t)width bytesPerRow: (size_t)bytesPerRow;

- (void) vibratePhone;

- (void) writeDataOut;

- (void) CMUtterDirections:(BOOL)check1:(BOOL)check2:(BOOL)check3:(BOOL)check4  ;

- (void) setSoundOnDetection;

- (void) handleTapGesture:(UITapGestureRecognizer *) sender;

- (void) setUI;
- (IBAction)CMsetMaxFramesPerSecond:(id)sender;
- (IBAction)CMSetMaxDistance:(id)sender;
- (IBAction)CMSetWhichLens:(id)sender;
- (IBAction)CMSetModalityForDirections:(id)sender;
- (IBAction)CMSetMarkerID:(id)sender;

@end

