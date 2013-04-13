//#include <opencv2/opencv.hpp>
//#include <opencv2/core/core.hpp>
#import "MyAVController.h"
#import "CMDetect.hpp"
#import "CMAudio.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/AudioServices.h>
#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <math.h>
#include <stdlib.h>



#define MIN_FRAMES_N_FOR_EXP_LOCK   4
#define SECONDS_BEFORE_EXP_UNLOCK   1.
#define MAX_INCLINATION_ANGLE       35.
#define MIN_INCLINED_TIME_FOR_VIBRATION 1.
#define DIST_TO_BEEP_FASTER         1.
#define MARKER_HEIGHT               0.16
#define MIN_TIME_BETWEEN_DIRECTIONS 1.5
#define MAX_DIST_FOR_SUCCESS  0.3
#define MAX_ANGLE_TO_TARGET_IN_DEGREES 10
#define MIN_FRAME_RATE_WHEN_SET     1

//unfortunately I need this…
BOOL IS_VIBRATING = NO;
CMDetect theDetector;

int availableMarkerIDs[8] = {2,3,7,10,11,13,14,18};


////
@implementation MyAVController


- (IBAction)CMSetMarkerID:(id)sender {
    NSString *theText;
    theText = [NSString stringWithFormat:@"%d", (int)self.markerIDSetter.value];
    [self.markerID performSelectorOnMainThread : @ selector(setText : ) withObject:theText waitUntilDone:YES];
}

- (IBAction)CMSetLens:(id)sender {
    if (self.lensSetter.selectedSegmentIndex==1){
        self.whichLensSelected = 3;
    }
    else {
        self.whichLensSelected = 0;
     }
    unsigned int theSeed = 1 + self.lensSetter.selectedSegmentIndex + 2*self.fpsSetter.selectedSegmentIndex;
    srand(theSeed);
}

- (IBAction)CMSetFPS:(id)sender {
    if (self.fpsSetter.selectedSegmentIndex==1) {
        self.minFramePeriod = (double)CLOCKS_PER_SEC / (double)MIN_FRAME_RATE_WHEN_SET;
        useShortBeepSequence = YES;
    }
    else {
        self.minFramePeriod = 0.;
        useShortBeepSequence = NO;
    }
    unsigned int theSeed = 1 + self.lensSetter.selectedSegmentIndex + 2*self.fpsSetter.selectedSegmentIndex;
    srand(theSeed);
}

- (IBAction)CMForward:(id)sender {
    
    // select new marker
    int newID;
    
    newID = availableMarkerIDs[rand() % 8];
    self.markerIDSetter.value = (double) newID;
    NSString *theText = [NSString stringWithFormat:@"%d", (int)self.markerIDSetter.value];
    [self.markerID performSelectorOnMainThread : @ selector(setText : ) withObject:theText waitUntilDone:YES];
    self.detectorIsRunning = TRUE;
    [self CMLockScreen];    
    
}

- (void) CMLockScreen{
    [self.lensSetter setEnabled:NO];
    [self.fpsSetter setEnabled:NO];
    [self.markerIDSetter setEnabled:NO];
    self.markerIDSetter.tintColor = [UIColor clearColor];
    [self.markerID setEnabled:NO];
    [self.markerIDLabel setEnabled:NO];
    [self.snapshotButton setEnabled:NO];
    self.snapshotButton.titleLabel.textColor = [UIColor lightGrayColor];
    [self.forwardButton setEnabled:NO];
}

- (void) CMUnlockScreen{
    [self.lensSetter setEnabled:YES];
    self.markerIDSetter.tintColor = [UIColor lightGrayColor];
    [self.markerID setEnabled:YES];
    [self.markerIDLabel setEnabled:YES];
    [self.lensSetter setEnabled:YES];
    [self.fpsSetter setEnabled:YES];
    [self.snapshotButton setEnabled:YES];
    self.snapshotButton.titleLabel.textColor = [UIColor blackColor];
    [self.forwardButton setEnabled:YES];
}

- (BOOL) isAnySpeechPlaying{
    
    return self.turnDown.theAudio.isPlaying ||
        self.turnUp.theAudio.isPlaying ||
        self.turnRightAndUp.theAudio.isPlaying ||
        self.turnRightAndDown.theAudio.isPlaying ||
        self.turnRight.theAudio.isPlaying ||
        self.turnLeftAndUp.theAudio.isPlaying ||
        self.turnLeftAndDown.theAudio.isPlaying ||
        self.turnLeft.theAudio.isPlaying ||
        self.targetReached.theAudio.isPlaying||
        self.backUp.theAudio.isPlaying;
}

- (void) writeDataOut{
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"<Quintuple id=\"%d\">\n",++(self.nRecorded)] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"<Center>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"<X>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"%d",theDetector.outValues.center.iX] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"</X>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"<Y>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"%d",theDetector.outValues.center.iY] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"</Y>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"</Center>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat:          @"<Top>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"<X>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"%d",theDetector.outValues.top.iX] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"</X>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"<Y>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"%d",theDetector.outValues.top.iY] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"</Y>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"</Top>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat:          @"<Bottom>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"<X>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"%d",theDetector.outValues.bottom.iX] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"</X>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"<Y>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"%d",theDetector.outValues.bottom.iY] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"</Y>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"</Bottom>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat:          @"<Left>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"<X>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"%d",theDetector.outValues.left.iX] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"</X>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"<Y>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"%d",theDetector.outValues.left.iY] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"</Y>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"</Left>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat:          @"<Right>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"<X>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"%d",theDetector.outValues.right.iX] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"</X>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"<Y>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"%d",theDetector.outValues.right.iY] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"</Y>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"</Right>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"</Quintuple>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void) CMUtterDirections:(BOOL)check1 :(BOOL)check2 :(BOOL)check3 :(BOOL)check4
{
    // don't want to reduce volume if speaking modality selected
    
    if ((clock() - self.timeSinceLastDirection) > MIN_TIME_BETWEEN_DIRECTIONS * (double)CLOCKS_PER_SEC){
        self.timeSinceLastDirection = clock();
        [self.theBeep1 stopIt];
        [self.theBeep2 stopIt];
        [self.theBeep2Short stopIt];
        if ((!check2 && !check4)
            ||(theDetector.outValues.borderReached.top && theDetector.outValues.borderReached.left))
        {
            // NW
            [self.turnRightAndUp playIt];
        }
        else if ((!check1 && !check4)
                 ||(theDetector.outValues.borderReached.top && theDetector.outValues.borderReached.right))
        {
            // SW
            [self.turnRightAndDown playIt];
        }
        else if ((!check2 && !check3)
                 ||(theDetector.outValues.borderReached.bottom && theDetector.outValues.borderReached.left))
        {
            // NE
            [self.turnLeftAndUp playIt];
        }
        else if ((!check1 && !check3)
                 ||(theDetector.outValues.borderReached.bottom && theDetector.outValues.borderReached.right))
        {
            // SE
            [self.turnLeftAndDown playIt];
        }
        else if ((check1 && check2 && !check3)
            || theDetector.outValues.borderReached.bottom)
        {
            // W
                [self.turnLeft playIt];
        }
        else if ((check1 && check2 && !check4)
                 || theDetector.outValues.borderReached.top) {
            // E
                [self.turnRight playIt];
        }
        else if ((!check1 && check3 && check4)
                 || theDetector.outValues.borderReached.right){
            // S
                [self.turnDown playIt];
        }
        else if ((!check2 && check3 && check4)
                 || theDetector.outValues.borderReached.left){
            // N
                [self.turnUp playIt];
        }
     }
}

- (void) CMSoundOnDetection {
    BOOL check2 = _anglesToMarkerInDegrees.hor > - MAX_ANGLE_TO_TARGET_IN_DEGREES;
    BOOL check1 = _anglesToMarkerInDegrees.hor < MAX_ANGLE_TO_TARGET_IN_DEGREES;
    BOOL check4 = _anglesToMarkerInDegrees.ver > - MAX_ANGLE_TO_TARGET_IN_DEGREES;
    BOOL check3 = _anglesToMarkerInDegrees.ver < MAX_ANGLE_TO_TARGET_IN_DEGREES;
    
    [self CMUtterDirections:check1 :check2 :check3 :check4];
    
//    
//    switch ((int)self.modalityForDirectionsSetter.value) {
//        case 0:
//            self.theBeep1.theAudio.volume = 0.25;
//            self.theBeep2.theAudio.volume = 0.25;
//            self.theBeep2Short.theAudio.volume = 0.25;
//            break;
//        case 1:
//            if (check1 && check2 && check3 && check4) {
//                self.theBeep1.theAudio.volume = 0.25;
//                self.theBeep2.theAudio.volume = 0.25;
//                self.theBeep2Short.theAudio.volume = 0.25;
//            }
//            else {
//                self.theBeep1.theAudio.volume = 0.05;
//                self.theBeep2.theAudio.volume = 0.05;
//                self.theBeep2Short.theAudio.volume = 0.05;
//            }
//            break;
//        case 2:
//            self.theBeep1.theAudio.volume = 0.25;
//            self.theBeep2.theAudio.volume = 0.25;
//            self.theBeep2Short.theAudio.volume = 0.25;
//            [self CMUtterDirections:check1 :check2 :check3 :check4];
//            break;
//        default:
//            break;
//    }
    
    if ((self.distanceToMarker <= MAX_DIST_FOR_SUCCESS) && (!theDetector.outValues.borderReached.top)
        && (!theDetector.outValues.borderReached.bottom)&& (!theDetector.outValues.borderReached.left)&& (!theDetector.outValues.borderReached.right)) {
        if (![self isAnySpeechPlaying]) {
            [self.theBeep1 stopIt];
            [self.theBeep2 stopIt];
            [self.theBeep2Short stopIt];
            [self.targetReached playIt];
        }
    }
                       
    if (self.distanceToMarker > DIST_TO_BEEP_FASTER)
    {
            [self.theBeep2 stopIt];
            [self.theBeep2Short stopIt];
            if (![self isAnySpeechPlaying])
                [self.theBeep1 playIt];
        }
    else
    {
        [self.theBeep1 stopIt];
        if (useShortBeepSequence){
            [self.theBeep2 stopIt];
            if (![self isAnySpeechPlaying])
                [self.theBeep2Short playIt];
        }
        else{
            [self.theBeep2Short stopIt];
            if (![self isAnySpeechPlaying])
                [self.theBeep2 playIt];
        }
    }
}


// RM 12/3 - vibration routines
void MyAudioServicesSystemVibrationCompletionProc (
                                                   SystemSoundID  ssID,
                                                   void           *clientData
                                                   )
{
    IS_VIBRATING = NO;
}

- (void) vibratePhone {
    if (!IS_VIBRATING) {
        IS_VIBRATING = YES;
        AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate, nil, nil, MyAudioServicesSystemVibrationCompletionProc, (void*) self);
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}

- (id)init {
	self = [super init];
	if (self) {
		/*We initialize some variables (they might be not initialized depending on what is commented or not)*/
		_imageView = nil;
		_prevLayer = nil;
		_customLayer = nil;
        
        
	}
	return self;
}

- (void)viewDidLoad {
    
    // shouldn't I also do this?
    [super viewDidLoad];
	/*We intialize the capture*/
	[self initCapture];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 4;
    [self.view addGestureRecognizer:tapGesture];
    [tapGesture release];
    
    
}

- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
        if (self.detectorIsRunning) {
            self.detectorIsRunning = FALSE;
            [self CMUnlockScreen];
        }
        else{
            self.detectorIsRunning = TRUE;
            [self CMLockScreen];
        }
    }
}

- (void) computeDistanceToMarker {
    
    // Note: this is only called if a marker is found
    
    // First check if too close
    if (theDetector.outValues.borderReached.top || theDetector.outValues.borderReached.bottom ||
        theDetector.outValues.borderReached.left || theDetector.outValues.borderReached.right) {
        // impossible to compute distance - a border has been reached
        self.distanceToMarker = -1;
    }
    else {
        // this is a very simplified distance computation that assumes that the phone is centered in one of the two planes orthogonal to the marker 
        
        double markerImageHeightInPixels = sqrt((double) ((theDetector.outValues.right.iX -  theDetector.outValues.left.iX)*(theDetector.outValues.right.iX -  theDetector.outValues.left.iX) + (theDetector.outValues.right.iY -  theDetector.outValues.left.iY)*(theDetector.outValues.right.iY -  theDetector.outValues.left.iY)));
        double markerImageWidthInPixels = sqrt((double) ((theDetector.outValues.top.iX -  theDetector.outValues.bottom.iX)*(theDetector.outValues.top.iX -  theDetector.outValues.bottom.iX) + (theDetector.outValues.top.iY -  theDetector.outValues.bottom.iY)*(theDetector.outValues.top.iY -  theDetector.outValues.bottom.iY)));
        double maxHeightInPixels = MAX(markerImageHeightInPixels,markerImageWidthInPixels);
        self.distanceToMarker = (double)(focalLengthInPixels[self.whichLensSelected]  * MARKER_HEIGHT) / (double) maxHeightInPixels;
    }
}

- (void) computeAnglesToMarker {
    _anglesToMarkerInDegrees.hor = atan((double(theDetector.outValues.center.iX) - double(self.width) / 2.) / double(focalLengthInPixels[self.whichLensSelected])) * 180 / 3.14;
    _anglesToMarkerInDegrees.ver = atan((double(theDetector.outValues.center.iY) - double(self.height) / 2.) / double(focalLengthInPixels[self.whichLensSelected])) * 180. / 3.14;
}


- (void)initCapture {
    
    

    /* Various initializations - is this the right place? It looks like init is never called. */
    self.shouldTakeSnapshot = NO;
    
    self.motionManager = [[CMMotionManager alloc] init];
    
    NSString * path = [[NSBundle mainBundle] pathForResource:  @"CMUserParams" ofType: @"xml"];
    std::string userParsFileName = [path cStringUsingEncoding:1];
    
    // This must go somewhere else!
    
    NSString * path2  = [[NSBundle mainBundle] pathForResource:  @"iPhone-12-13-12" ofType: @"xml"];
    std::string classParsFileName = [path2 cStringUsingEncoding:1];
    
    theDetector.Init(userParsFileName,classParsFileName);
    
    self.theBeep1 = [[CMAudio alloc] initWithName:@"beep-1" andType:@"aif" andLooping:0];  
    self.theBeep2 = [[CMAudio alloc] initWithName:@"beep-2" andType:@"aif" andLooping:1];  
    self.theBeep2Short = [[CMAudio alloc] initWithName:@"beep-2" andType:@"aif" andLooping:3];
    
    // RM 12/13
    self.turnUp = [[CMAudio alloc] initWithName:@"turnUp" andType:@"wav" andLooping:NO];
    self.turnUp.theAudio.volume = 1.;
    self.turnDown = [[CMAudio alloc] initWithName:@"turnDown" andType:@"wav" andLooping:NO];
    self.turnDown.theAudio.volume = 1.;
   self.turnLeft = [[CMAudio alloc] initWithName:@"turnLeft" andType:@"wav" andLooping:NO];
    self.turnLeft.theAudio.volume = 1.;
    self.turnRight = [[CMAudio alloc] initWithName:@"turnRight" andType:@"wav" andLooping:NO];
    self.turnRight.theAudio.volume = 1.;
    self.turnLeftAndUp = [[CMAudio alloc] initWithName:@"turnLeftAndUp" andType:@"wav" andLooping:NO];
    self.turnLeftAndUp.theAudio.volume = 1.;
    self.turnRightAndUp = [[CMAudio alloc] initWithName:@"turnRightAndUp" andType:@"wav" andLooping:NO];
    self.turnRightAndUp.theAudio.volume = 1.;
    self.turnLeftAndDown = [[CMAudio alloc] initWithName:@"turnLeftAndDown" andType:@"wav" andLooping:NO];
    self.turnLeftAndDown.theAudio.volume = 1.;
    self.turnRightAndDown = [[CMAudio alloc] initWithName:@"turnRightAndDown" andType:@"wav" andLooping:NO];
    self.turnRightAndDown.theAudio.volume = 1.;
    self.targetReached = [[CMAudio alloc] initWithName:@"targetReached" andType:@"wav" andLooping:NO];
    self.targetReached.theAudio.volume = 1.;
    self.backUp = [[CMAudio alloc] initWithName:@"backUp" andType:@"wav" andLooping:NO];
    self.backUp.theAudio.volume = 1.;
    
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    NSString *outFilePath = [[NSString alloc] initWithFormat:@"%@",[documentsDir stringByAppendingPathComponent:@"Points.xml"]];
    
    //        BOOL openedFile = [[NSFileManager defaultManager] createFileAtPath:outFilePath contents:nil attributes:nil];
    [[NSFileManager defaultManager] createFileAtPath:outFilePath contents:nil attributes:nil];
    
    self.outFileHandler  = [NSFileHandle fileHandleForWritingToURL:
                        [NSURL fileURLWithPath:outFilePath] error:nil];
    
    self.IS_TOO_INCLINED = NO;
    
    focalLengthInPixels[0] = 627.;
    focalLengthInPixels[1] = 464.;
//    focalLengthInPixels[2] = 260.;
    focalLengthInPixels[2] = 330.;
    
    ////////

    
    [self.motionManager startAccelerometerUpdates];
    
	/*We setup the input*/
    
    
    AVCaptureDevice     *theDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput
										  deviceInputWithDevice:theDevice
										  error:nil];
    
    
    
	/*We setupt the output*/
	AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
	/*While a frame is processes in -captureOutput:didOutputSampleBuffer:fromConnection: delegate methods no other frames are added in the queue.
	 If you don't want this behaviour set the property to NO */
	captureOutput.alwaysDiscardsLateVideoFrames = YES;
    
	/*We create a serial queue to handle the processing of our frames*/
	dispatch_queue_t queue;
	queue = dispatch_queue_create("cameraQueue", NULL);
	[captureOutput setSampleBufferDelegate:self queue:queue];
	dispatch_release(queue);
    
	// Set the video output to store frame in YpCbCr planar so we can access the brightness in contiguios memory
	NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    // choice is kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange or RGBA
    
    //	NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
	NSNumber* value = [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] ;
    
    
    //kCVPixelFormatType_420YpCbCr8PlanarFullRange
	NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
	[captureOutput setVideoSettings:videoSettings];
    
	/*And we create a capture session*/
	self.captureSession = [[AVCaptureSession alloc] init];
	self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
    //    self.captureSession.sessionPreset = AVCaptureSessionPreset352x288;
    
    //    AVCaptureSessionPreset352x288;//;AVCaptureSessionPresetMedium;//AVCaptureSessionPreset640x480;//AVCaptureSessionPreset352x288;
	
    
	/*We add input and output*/
	[self.captureSession addInput:captureInput];
	[self.captureSession addOutput:captureOutput];
    
    
	/*We add the imageView*/
	self.imageView = [[UIImageView alloc] init];
    //	self.imageView.frame = CGRectMake(0, 0, 100,100);
    
    // RM
    //	self.imageView.frame = CGRectMake(0, 0, 320,240);
	self.imageView.frame = CGRectMake(0, 0, 240,320);
    [self.view addSubview:self.imageView];
    
    
    //Once startRunning is called the camera will start capturing frames
	[self.captureSession startRunning];
    
	[self.theBeep1.theAudio prepareToPlay];
	[self.theBeep2.theAudio prepareToPlay];
    

}




/*** RM 6/15 - test ***/
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    
    CMAccelerometerData *theAcceleration = self.motionManager.accelerometerData;
    
    // vibrate if inclination is MAX_INCLINATION_ANGLE degrees or more
    if (fabs(theAcceleration.acceleration.y) > 0.1 &&
        fabs(theAcceleration.acceleration.x) / fabs(theAcceleration.acceleration.y) > tan(MAX_INCLINATION_ANGLE *3.14/180.)) {
        if (! self.IS_TOO_INCLINED){
            self.IS_TOO_INCLINED = YES;
            self.isTooInclinedStartTime = (double)clock();
        }
        else {
            if (((double)clock() - self.isTooInclinedStartTime) / (double)CLOCKS_PER_SEC > MIN_INCLINED_TIME_FOR_VIBRATION) {
                [self vibratePhone];
            }
            
        }
    }
    else {
        self.IS_TOO_INCLINED = NO;
    }
    
    
    /*We create an autorelease pool because as we are not in the main_queue our code is
     not executed in the main thread. So we have to create an autorelease pool for the thread we are in*/
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    /*Lock the image buffer*/
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    self.width = CVPixelBufferGetWidth(imageBuffer);
    self.height = CVPixelBufferGetHeight(imageBuffer);
    
    // we should be able to allocate this buffer once and or all to save time (tried - didn't help)
    uint8_t *base = (uint8_t *) malloc(bytesPerRow * self.height * sizeof(uint8_t));
    memcpy(base, baseAddress, bytesPerRow * self.height);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    
    
    if (clock() - self.mainStartTime > self.minFramePeriod)
    {
        self.mainStartTime = clock();
        
        theDetector.AccessImage((unsigned char*)base, self.width, self.height ,bytesPerRow);
        
        theDetector.SetMarkerID(self.markerIDSetter.value);
        if ((theDetector.FindTarget()))
        {
            [self computeDistanceToMarker];
            [self computeAnglesToMarker];
            
            self.countFramesForLock++;
            if (self.countFramesForLock >= MIN_FRAMES_N_FOR_EXP_LOCK) {
                // good exposure - lock it!
                AVCaptureDevice     *theDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
                [theDevice lockForConfiguration:(nil)];
                theDevice.exposureMode = AVCaptureExposureModeLocked;
                theDevice.whiteBalanceMode  = AVCaptureWhiteBalanceModeLocked;
                [theDevice unlockForConfiguration];
                
                self.startTimeExpLock = clock();
            }
            
            [self writeDataOut];
            
            [self CMSoundOnDetection];
            
         }
        else   // not found
        {
            [self.theBeep1 stopIt];
            [self.theBeep2 stopIt];
            [self.theBeep2Short stopIt];
            
            self.countFramesForLock = 0;
            
            if (((clock() - self.startTimeExpLock) > SECONDS_BEFORE_EXP_UNLOCK * (double)CLOCKS_PER_SEC))
                
            {
                // unlock exposure
                AVCaptureDevice     *theDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
                if (theDevice.exposureMode == AVCaptureExposureModeLocked) {
                    [theDevice lockForConfiguration:(nil)];
                    theDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
                    theDevice.whiteBalanceMode  = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance   ;
                    [theDevice unlockForConfiguration];
                }
            }
        }
        ///// test 11/8/12 - show text
        // compute fps
        //     int  self.framesPerSecond = (int) (1/ ((clock() - self.start_time) / (double)CLOCKS_PER_SEC));
        if ((clock() - self.start_time) > (double)CLOCKS_PER_SEC) {
            self.framesPerSecond = self.frameCount;
            self.frameCount = 0;
            self.start_time = clock();
            [self.actualFramesPerSecond performSelectorOnMainThread : @ selector(setText : )
                                                          withObject:[NSString stringWithFormat:@"%d", (int)self.framesPerSecond]
                                                       waitUntilDone:NO];
        }
        else
            self.frameCount++;
        
        
        
    }
//    uint8_t *tp1, *tp2;
//    //     tp1 = baseAddress;
//    tp1 = base;
//    for (int iy=0;iy<height; iy++,tp1 += bytesPerRow){
//        tp2 = tp1;
//        for (int ix=0 ;ix<bytesPerRow;ix+=4,tp2+=4){
//            //            *tp2 = *(tp2+2);
//            //            *(tp2+2)=255;
//        }
//    }
    // RM - test
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    memcpy(baseAddress, base, bytesPerRow * self.height);
    free(base);
    
    /////
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, self.width, self.height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    
    //////
    ////////////
    
    //        NSString* fpsString = [NSString stringWithFormat:@"%i fps", self.framesPerSecond];
//    NSString* fpsString = [NSString stringWithFormat:@"%i cm %i in", (int)(self.distanceToMarker * 100.), (int)(self.distanceToMarker * 39.37)];
    NSString* fpsString = [NSString stringWithFormat:@"%i deg %i deg", (int)(_anglesToMarkerInDegrees.hor), (int)(_anglesToMarkerInDegrees.ver)];
    
    //
    
    
    char* text	= (char *)[fpsString cStringUsingEncoding:NSASCIIStringEncoding];
    CGContextSelectFont(context, "Arial", 25, kCGEncodingMacRoman);
    CGContextSetTextDrawingMode(context, kCGTextFill);
    CGContextSetRGBFillColor(context, 1, 0, 0, 1);
    
    
    //turn text
    CGContextSetTextMatrix(context, CGAffineTransformMakeRotation( M_PI/2 ));
    
//    CGContextShowTextAtPoint(context,30,400, text, strlen(text));
    CGContextShowTextAtPoint(context,30,30, text, strlen(text));
    
    
   
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    // UIImage *image = [UIImage imageWithCGImage:quartzImage];
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:(CGFloat)1 orientation:UIImageOrientationRight];
    
    if ((self.shouldTakeSnapshot) && ((clock() - time1) / (double)CLOCKS_PER_SEC) > 1.) {
        NSMutableString *imageName = [NSMutableString string];
        
        
        imageName = [NSMutableString stringWithFormat:@"%d",self.indPicture++]; //%d or %i both is ok.
        
        [imageName appendString:@".png"];
        // test RM 9/15 - save image
        NSData *pngData = UIImagePNGRepresentation(image);
        
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0]; //Get the docs directory
        NSString *filePath = [documentsPath stringByAppendingPathComponent:imageName]; //Add the file name
        
        [pngData writeToFile:filePath atomically:YES]; //
        self.shouldTakeSnapshot = NO;
        
    }
    
    
    // test RM 11/11
    AVCaptureDevice     *theDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    [theDevice lockForConfiguration:(nil)];
//    if (theDevice.exposureMode == AVCaptureExposureModeLocked) {
//        theDevice.exposureMode  = AVCaptureExposureModeContinuousAutoExposure;
//    }
//    else
//        theDevice.exposureMode = AVCaptureExposureModeLocked;
    [theDevice unlockForConfiguration];
    
    
    
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    //notice we use this selector to call our setter method 'setImg' Since only the main thread can update this
    
    //     if ((nFrames++ % 1) == 0){
    //         nFrames = 1;
    [self.imageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:YES];
    //     }
    
    
    
    [pool drain];
}

//-(UIImage *) UIImageFromBits:(uint8_t *)planar_addr height:(size_t)height width:(size_t)width {
-(UIImage *) UIImageFromBits:(uint8_t *)planar_addr height:(size_t)height width:(size_t)width bytesPerRow: (size_t)bytesPerRow{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    CGDataProviderRef  dataProvider = CGDataProviderCreateWithData(NULL, planar_addr,
                                                                   height * width, NULL);
    //        CGImageRef imageRef = CGImageCreate(width, height, 8, 8, width,
    //                                            colorSpace, kCGImageAlphaNone, dataProvider, NULL, NO, kCGRenderingIntentDefault);
    
    CGImageRef imageRef = CGImageCreate(width, height, 8, 8, width,
                                        colorSpace, kCGImageAlphaNone, dataProvider, NULL, NO, kCGRenderingIntentDefault);
    
    UIImage *ret = [[[UIImage alloc] initWithCGImage:imageRef] autorelease];
    
    CGImageRelease(imageRef);
    CGDataProviderRelease(dataProvider);
    CGColorSpaceRelease(colorSpace);
    return ret;
}
/*
 - (IplImage *)CreateGrayIplImageFromPlanar:(uint8_t *)planar_addr height:(size_t)height width:(size_t)width {
 //CGImageRef imageRef = image.CGImage;
 
 IplImage *iplimage = cvCreateImage(cvSize(width, height), IPL_DEPTH_8U, 1);
 memcpy(iplimage->imageData, planar_addr, height*width);
 
 return iplimage;
 }
 */

#pragma mark -
#pragma mark Memory management

- (void)viewDidUnload {
	self.imageView = nil;
	self.customLayer = nil;
	self.prevLayer = nil;
//    self.maxFramesPerSecondSetter = nil;
//    self.maxFramesPerSecond = nil;
    self.markerIDSetter = nil;
    self.markerID = nil;
    
    // should also set the outlets to nil…but instead it releases in dealloc!
}

- (void)dealloc {
	[self.captureSession release];
    [self.theBeep1 release];
    [self.theBeep2 release];
    [self.turnLeft release];
    [self.turnRight release];
    [self.turnUp release];
    [self.turnDown release];
    [self.turnLeftAndUp release];
    [self.turnLeftAndDown release];
    [self.turnRightAndUp release];
    [self.turnRightAndDown release];
    [self.targetReached release];
    [self.backUp release];
    
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"<NumberOfQuintuples>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"%d\n",self.nRecorded] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"</NumberOfQuintuples>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [self.outFileHandler closeFile];
    [self.motionManager stopAccelerometerUpdates];
    [self.motionManager release];
    [self.framesPerSecond release];
//    [_maxFramesPerSecondSetter release];
//    [_maxFramesPerSecond release];
    [_actualFramesPerSecond release];
    [_markerIDSetter release];
    [_markerID release];
//    [_setMaxDistance release];
//    [_maxDistance release];
//    [_whichLensSetter release];
//    [_whichLens release];
//    [_modalityForDirectionsSetter release];
//    [_modalityForDirections release];
//    [_maxFramesPerSecond release];
//    [_maxDistanceSetter release];
//    [_whichLensSetter release];
//    [_modalityForDirectionsSetter release];
    [_markerIDSetter release];
//    [_whichLensLabel release];
//    [_maxDistanceLabel release];
//    [_maxFramesPerSecondLabel release];
//    [_modalityForDirectionLabel release];
    [_markerIDLabel release];
    [_snapshotButton release];
    [_lensSetter release];
    [_fpsSetter release];
    [_fpsSetter release];
    [_forwardButton release];
    [super dealloc];
}


//- (IBAction)takeSnapshot:(id)sender {
//}
- (IBAction)takeSnapshot:(id)sender {
    
    self.shouldTakeSnapshot = YES;
    time1 = clock();
}
@end