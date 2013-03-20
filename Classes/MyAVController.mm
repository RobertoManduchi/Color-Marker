//#include <opencv2/opencv.hpp>
//#include <opencv2/core/core.hpp>
#import "MyAVController.h"
#import "CMDetect.hpp"
#import "CMAudio.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/AudioServices.h>
#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>



#define MIN_FRAMES_N_FOR_EXP_LOCK   4
#define SECONDS_BEFORE_EXP_UNLOCK   1.
#define MAX_INCLINATION_ANGLE       35.
#define MIN_INCLINED_TIME_FOR_VIBRATION 1.
#define DIST_TO_BEEP_FASTER         1.
#define MARKER_HEIGHT               0.16
//#define HALF_RELATIVE_WIDTH_CENTER  0.1
#define TAN_HALF_CENTER_ANGLE  0.15
#define MIN_TIME_BETWEEN_DIRECTIONS 1.5

//unfortunately I need this…
BOOL IS_VIBRATING = NO;
CMDetect theDetector;



////
@implementation MyAVController

- (IBAction)CMsetMaxFramesPerSecond:(id)sender{
    NSString *theText;
    if (self.maxFramesPerSecondSetter.value == 10)
        theText = @"- - -";
    else
        theText = [NSString stringWithFormat:@"%d", (int)self.maxFramesPerSecondSetter.value];
    
    if (self.maxFramesPerSecondSetter.value == 1)
        useShortBeepSequence = TRUE;
    else
        useShortBeepSequence = FALSE;
    
    [self.maxFramesPerSecond performSelectorOnMainThread : @ selector(setText : ) withObject:theText waitUntilDone:YES];
}

// Should change name - originally set max distance, now toggles between distance interface on or off
- (IBAction)CMSetMaxDistance:(id)sender {
    NSString *theText;
    if (self.maxDistanceSetter.value == 0){
//        theText = @"- - -";
        theText = @"OFF";
        self.CHECK_DISTANCE = FALSE;
    }
    else{
//        theText = [NSString stringWithFormat:@"%d", (int)self.maxDistanceSetter.value];
    theText = [NSString stringWithFormat:@"ON"];
    self.CHECK_DISTANCE = TRUE;
    }
    
    [self.maxDistance performSelectorOnMainThread : @ selector(setText : ) withObject:theText waitUntilDone:YES];
}

- (IBAction)CMSetWhichLens:(id)sender {
    NSString *theText;
    
    switch ((int)self.whichLensSetter.value) {
        case 0:
            theText = @"- - -";
            break;
        case 1:
            theText = @"wide";
            break;
        case 2:
            theText = @"fish";
            break;
        default:
            break;
    }

    // Set the center region
    self.centerRegionHalfSizeX = (int)(TAN_HALF_CENTER_ANGLE * focalLengthInPixels[(int)self.whichLensSetter.value]);
    self.centerRegionHalfSizeY = (int)(TAN_HALF_CENTER_ANGLE * focalLengthInPixels[(int)self.whichLensSetter.value]);
    
    
    [self.whichLens performSelectorOnMainThread : @ selector(setText : ) withObject:theText waitUntilDone:YES];
}

- (IBAction)CMSetModalityForDirections:(id)sender {
    NSString *theText;

    switch ((int)self.modalityForDirectionsSetter.value) {
        case 0:
            theText = @"no dir";
            break;
        case 1:
            theText = @"volume";
            break;
        case 2:
            theText = @"speech";
            break;
        default:
            break;
    }
    [self.modalityForDirections performSelectorOnMainThread : @ selector(setText : ) withObject:theText waitUntilDone:YES];
}

- (IBAction)CMSetMarkerID:(id)sender {
    NSString *theText;
    theText = [NSString stringWithFormat:@"%d", (int)self.markerIDSetter.value];
    [self.markerID performSelectorOnMainThread : @ selector(setText : ) withObject:theText waitUntilDone:YES];
}


- (void) setUI{
    // User interface. This is the *wrong* approach - should use a delegate instead.
    NSString *theText;
    
//    switch ((int)self.setWhichLens.value) {
//        case 0:
//            theText = @"- - -";
//            break;
//        case 1:
//            theText = @"wide";
//            break;
//        case 2:
//            theText = @"fish";
//            break;
//        default:
//            break;
//    }
//    [self.whichLens performSelectorOnMainThread : @ selector(setText : ) withObject:theText waitUntilDone:YES];
//    
//    switch ((int)self.setModalityForDirections.value) {
//        case 0:
//            theText = @"no dir";
//            break;
//        case 1:
//            theText = @"volume";
//            break;
//        case 2:
//            theText = @"speech";
//            break;
//        default:
//            break;
//    }
//    [self.modalityForDirections performSelectorOnMainThread : @ selector(setText : ) withObject:theText waitUntilDone:YES];
//    
//    if ((int)self.setMaxDistance != [self.maxDistance.text intValue]) {
//        NSString *theText;
//        if (self.setMaxDistance.value == 0)
//            theText = @"- - -";
//        else
//            theText = [NSString stringWithFormat:@"%d", (int)self.setMaxDistance.value];
//        
//        [self.maxDistance performSelectorOnMainThread : @ selector(setText : ) withObject:theText waitUntilDone:YES];
//    }
//
//    if ((int)self.setMarkerID != [self.markerID.text intValue]) {
//        NSString *theText;
//        theText = [NSString stringWithFormat:@"%d", (int)self.setMarkerID.value];
//        [self.markerID performSelectorOnMainThread : @ selector(setText : ) withObject:theText waitUntilDone:YES];
//        
//    }
//
//    if ((int)self.maxFramesPerSecond.value != [self.maxFramesPerSecond.text intValue]) {
//        NSString *theText;
//        if (self.maxFramesPerSecond.value == 10)
//            theText = @"- - -";
//        else
//            theText = [NSString stringWithFormat:@"%d", (int)self.maxFramesPerSecond.value];
//        
//        if (self.maxFramesPerSecond.value == 1)
//            useShortBeepSequence = TRUE;
//        else
//            useShortBeepSequence = FALSE;
//        
//        [self.maxFramesPerSecond performSelectorOnMainThread : @ selector(setText : ) withObject:theText waitUntilDone:YES];
//    }
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
    
    if ((int)self.modalityForDirectionsSetter.value == 1) {
        self.theBeep1.theAudio.volume = 0.05;
        self.theBeep2.theAudio.volume = 0.05;
        self.theBeep2Short.theAudio.volume = 0.05;
    }
    if ((int)self.modalityForDirectionsSetter.value == 2) {
        self.theBeep1.theAudio.volume = 0.25;
        self.theBeep2.theAudio.volume = 0.25;
        self.theBeep2Short.theAudio.volume = 0.25;
        if (check1 && check2 && !check3)
        {
            // W
            if ((clock() - self.timeSinceLastDirection) > MIN_TIME_BETWEEN_DIRECTIONS * (double)CLOCKS_PER_SEC){
                self.timeSinceLastDirection = clock();
                [self.rotateLeft playIt];
            }
        }
        else if (check1 && check2 && !check4) {
            // E
            if ((clock() - self.timeSinceLastDirection) > MIN_TIME_BETWEEN_DIRECTIONS * (double)CLOCKS_PER_SEC){
                self.timeSinceLastDirection = clock();
                [self.rotateRight playIt];
            }
        }
        else if (!check1 && check3 && check4){
            // S
            if ((clock() - self.timeSinceLastDirection) > MIN_TIME_BETWEEN_DIRECTIONS * (double)CLOCKS_PER_SEC){
                self.timeSinceLastDirection = clock();
                [self.rotateDown playIt];
            }
        }
        else if (!check2 && check3 && check4){
            // N
            if ((clock() - self.timeSinceLastDirection) > MIN_TIME_BETWEEN_DIRECTIONS * (double)CLOCKS_PER_SEC){
                self.timeSinceLastDirection = clock();
                [self.rotateUp playIt];
            }
        }
        else if (!check2 && !check4){
            // NW
            if ((clock() - self.timeSinceLastDirection) > MIN_TIME_BETWEEN_DIRECTIONS * (double)CLOCKS_PER_SEC){
                self.timeSinceLastDirection = clock();
//                [self.rotateLeftAndUp playIt];
                [self.rotateRightAndUp playIt];
            }
        }
        else if (!check1 && !check4){
            // SW
            if ((clock() - self.timeSinceLastDirection) > MIN_TIME_BETWEEN_DIRECTIONS * (double)CLOCKS_PER_SEC){
                self.timeSinceLastDirection = clock();
                [self.rotateRightAndDown playIt];
            }
        }
        else if (!check2 && !check3){
            // NE
            if ((clock() - self.timeSinceLastDirection) > MIN_TIME_BETWEEN_DIRECTIONS * (double)CLOCKS_PER_SEC){
                self.timeSinceLastDirection = clock();
//                [self.rotateRightAndUp playIt];
                [self.rotateLeftAndUp playIt];
            }
        }
        else if (!check1 && !check3){
            // SE
            if ((clock() - self.timeSinceLastDirection) > MIN_TIME_BETWEEN_DIRECTIONS * (double)CLOCKS_PER_SEC){
                self.timeSinceLastDirection = clock();
                [self.rotateLeftAndDown playIt];
            }
        }
    }
    
}

- (void) setSoundOnDetection {
//    BOOL check1 = (theDetector.outValues.center.iX < theDetector.IMAGE_W * (0.5+HALF_RELATIVE_WIDTH_CENTER));
//    BOOL check2 = (theDetector.outValues.center.iX > theDetector.IMAGE_W * (0.5-HALF_RELATIVE_WIDTH_CENTER));
//    BOOL check3 = (theDetector.outValues.center.iY < theDetector.IMAGE_H * (0.5+HALF_RELATIVE_WIDTH_CENTER));
//    BOOL check4 = (theDetector.outValues.center.iY > theDetector.IMAGE_H * (0.5-HALF_RELATIVE_WIDTH_CENTER));
    BOOL check1 = (theDetector.outValues.center.iX < theDetector.IMAGE_W * 0.5+self.centerRegionHalfSizeX);
    BOOL check2 = (theDetector.outValues.center.iX > theDetector.IMAGE_W * 0.5-self.centerRegionHalfSizeX);
    BOOL check3 = (theDetector.outValues.center.iY < theDetector.IMAGE_H * 0.5+self.centerRegionHalfSizeY);
    BOOL check4 = (theDetector.outValues.center.iY > theDetector.IMAGE_H * 0.5-self.centerRegionHalfSizeY);
    
    
    if (check1 && check2 && check3 && check4) {
        // center region
        self.theBeep1.theAudio.volume = 0.25;
        self.theBeep2.theAudio.volume = 0.25;
        self.theBeep2Short.theAudio.volume = 0.25;
    }
    else{
        switch ((int)self.modalityForDirectionsSetter.value) {
            case 0:
                self.theBeep1.theAudio.volume = 0.25;
                self.theBeep2.theAudio.volume = 0.25;
                self.theBeep2Short.theAudio.volume = 0.25;
                break;
            case 1:
                self.theBeep1.theAudio.volume = 0.05;
                self.theBeep2.theAudio.volume = 0.05;
                self.theBeep2Short.theAudio.volume = 0.05;
                break;
            case 2:
                [self CMUtterDirections:check1 :check2 :check3 :check4];
            default:
                break;
        }
    }
    
    // check if we reached the goal
    if (theDetector.outValues.bottom.iY -  theDetector.outValues.top.iY >= 0.6*self.height){
    // do something
    }
            
    
    
    // look at the marker's apparent height - remember we are in landscape mode
    double markerImageHeightInPixels = sqrt((double) ((theDetector.outValues.right.iX -  theDetector.outValues.left.iX)*(theDetector.outValues.right.iX -  theDetector.outValues.left.iX) + (theDetector.outValues.right.iY -  theDetector.outValues.left.iY)*(theDetector.outValues.right.iY -  theDetector.outValues.left.iY)));
    
    if (((markerImageHeightInPixels  / MARKER_HEIGHT) < (focalLengthInPixels[(int)self.whichLensSetter.value] / DIST_TO_BEEP_FASTER)) || self.maxDistanceSetter.value==0)
    {
        // it is furhter away than 1 meter
        
        // check if it is within the max distance
//        if ((double)self.maxDistanceSetter.value == 0 ||
        // not anymore - we don't set a max distance anymore
        
//        if (markerImageHeightInPixels  / MARKER_HEIGHT >
//            focalLengthInPixels[(int)self.whichLensSetter.value] / (double)self.maxDistanceSetter.value ||
//            theDetector.outValues.right.iX == self.height ||
//            theDetector.outValues.left.iX == 0
//            )
        {
            [self.theBeep1 playIt];
            [self.theBeep2 stopIt];
            [self.theBeep2Short stopIt];
        }
//        else{
//            [self.theBeep1 stopIt];
//            [self.theBeep2 stopIt];
//            [self.theBeep2Short stopIt];
//        }
    }
    else
    {
        if (useShortBeepSequence){
            [self.theBeep2Short playIt];
            [self.theBeep2 stopIt];
        }
        else{
            [self.theBeep2 playIt];
            [self.theBeep2Short stopIt];
        }
            
        [self.theBeep1 stopIt];
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
////////////

// RM 12/5 - trying new beeping modality
//
//SystemSoundID   beep1ID, beep2ID;
//
//CFURLRef urlBeep1, urlBeep2;
//
//
//void MyAudioServicesSystemSoundCompletionProc (
//                                               SystemSoundID  ssID,
//                                               void           *clientData
//                                               )
//{
//    IS_BEEPING = NO;
//}
//
//- (void) beepPhone: (int) whichBeep {
//
//    SystemSoundID theBeepID;
//
//    if (!IS_BEEPING) {
//        IS_BEEPING = YES;
//        if (whichBeep==1) {
//            theBeepID = beep1ID;
//        }
//        else {
//             theBeepID = beep2ID;
//        }
//        AudioServicesAddSystemSoundCompletion(theBeepID, nil, nil, MyAudioServicesSystemSoundCompletionProc, (void*) self);
//        AudioServicesPlaySystemSound(theBeepID);
//    }
//}
//

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
            
            self.whichLensSetter.enabled = TRUE;
            self.whichLensSetter.tintColor = [UIColor lightGrayColor];
            self.whichLens.textColor = [UIColor grayColor];
            self.whichLensLabel.textColor = [UIColor blackColor];
            
            self.maxFramesPerSecondSetter.enabled = TRUE;
            self.maxFramesPerSecondSetter.tintColor = [UIColor lightGrayColor];
            self.maxFramesPerSecond.textColor = [UIColor grayColor];
            self.maxFramesPerSecondLabel.textColor = [UIColor blackColor];
            
            self.markerIDSetter.enabled = TRUE;
            self.markerIDSetter.tintColor = [UIColor lightGrayColor];
            self.markerID.textColor = [UIColor grayColor];
            self.markerIDLabel.textColor = [UIColor blackColor];
            
            self.maxDistanceSetter.enabled = TRUE;
            self.maxDistanceSetter.tintColor = [UIColor lightGrayColor];
            self.maxDistance.textColor = [UIColor grayColor];
            self.maxDistanceLabel.textColor = [UIColor blackColor];
            
            self.modalityForDirectionsSetter.enabled = TRUE;
            self.modalityForDirectionsSetter.tintColor = [UIColor lightGrayColor];
            self.modalityForDirections.textColor = [UIColor grayColor];
            self.modalityForDirectionLabel.textColor = [UIColor blackColor];
            
            self.snapshotButton.enabled = TRUE;
            self.snapshotButton.titleLabel.textColor = [UIColor blackColor];
            
        }
        else{
            self.detectorIsRunning = TRUE;
            
            self.whichLensSetter.enabled = FALSE;
            self.whichLensSetter.tintColor = [UIColor clearColor];
            self.whichLens.textColor = [UIColor lightGrayColor];
            self.whichLensLabel.textColor = [UIColor lightGrayColor];
            
            self.maxFramesPerSecondSetter.enabled = FALSE;
            self.maxFramesPerSecondSetter.tintColor = [UIColor clearColor];
            self.maxFramesPerSecond.textColor = [UIColor lightGrayColor];
            self.maxFramesPerSecondLabel.textColor = [UIColor lightGrayColor];
            
            self.markerIDSetter.enabled = FALSE;
            self.markerIDSetter.tintColor = [UIColor clearColor];
            self.markerID.textColor = [UIColor lightGrayColor];
            self.markerIDLabel.textColor = [UIColor lightGrayColor];
            
            self.maxDistanceSetter.enabled = FALSE;
            self.maxDistanceSetter.tintColor = [UIColor clearColor];
            self.maxDistance.textColor = [UIColor lightGrayColor];
            self.maxDistanceLabel.textColor = [UIColor lightGrayColor];
            
            self.modalityForDirectionsSetter.enabled = FALSE;
            self.modalityForDirectionsSetter.tintColor = [UIColor clearColor];
            self.modalityForDirections.textColor = [UIColor grayColor];
            self.modalityForDirectionLabel.textColor = [UIColor lightGrayColor];
            
            self.snapshotButton.enabled = FALSE;
            self.snapshotButton.titleLabel.textColor = [UIColor lightGrayColor];
       }
    }
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
    self.rotateUp = [[CMAudio alloc] initWithName:@"rotateUp" andType:@"wav" andLooping:NO];
    self.rotateUp.theAudio.volume = 1.;
    self.rotateDown = [[CMAudio alloc] initWithName:@"rotateDown" andType:@"wav" andLooping:NO];
    self.rotateDown.theAudio.volume = 1.;
   self.rotateLeft = [[CMAudio alloc] initWithName:@"rotateLeft" andType:@"wav" andLooping:NO];
    self.rotateLeft.theAudio.volume = 1.;
    self.rotateRight = [[CMAudio alloc] initWithName:@"rotateRight" andType:@"wav" andLooping:NO];
    self.rotateRight.theAudio.volume = 1.;
    self.rotateLeftAndUp = [[CMAudio alloc] initWithName:@"rotateLeftAndUp" andType:@"wav" andLooping:NO];
    self.rotateLeftAndUp.theAudio.volume = 1.;
    self.rotateRightAndUp = [[CMAudio alloc] initWithName:@"rotateRightAndUp" andType:@"wav" andLooping:NO];
    self.rotateRightAndUp.theAudio.volume = 1.;
    self.rotateLeftAndDown = [[CMAudio alloc] initWithName:@"rotateLeftAndDown" andType:@"wav" andLooping:NO];
    self.rotateLeftAndDown.theAudio.volume = 1.;
    self.rotateRightAndDown = [[CMAudio alloc] initWithName:@"rotateRightAndDown" andType:@"wav" andLooping:NO];
    self.rotateRightAndDown.theAudio.volume = 1.;
    
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
    focalLengthInPixels[2] = 260.;
    
    ////////

    // I don't think this is necessary
//    [self.theBeep1 playIt];
//    [self.theBeep1.theAudio pause];
//    [self.theBeep2 playIt];
//    [self.theBeep2.theAudio pause];
    
    [self.motionManager startAccelerometerUpdates];
    
	/*We setup the input*/
    
    
    AVCaptureDevice     *theDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput
										  deviceInputWithDevice:theDevice
										  error:nil];
    
    
    // no white balance
//    [theDevice lockForConfiguration:(nil)];
//    theDevice.whiteBalanceMode  = AVCaptureWhiteBalanceModeLocked;
//    [theDevice unlockForConfiguration];
    
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
    
    // Set the center region
    self.centerRegionHalfSizeX = (int)(TAN_HALF_CENTER_ANGLE * focalLengthInPixels[(int)self.whichLensSetter.value]);
    self.centerRegionHalfSizeY = (int)(TAN_HALF_CENTER_ANGLE * focalLengthInPixels[(int)self.whichLensSetter.value]);

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
    
    [self setUI];
    
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
    
    
    double theMinPeriod;
    if (self.maxFramesPerSecondSetter.value == 10) // this is the max - should be set as parameter
        theMinPeriod = 0.;
    else
        theMinPeriod = (double)CLOCKS_PER_SEC / (double)self.maxFramesPerSecondSetter.value;
    
    if (clock() - self.mainStartTime > theMinPeriod)
    {
        self.mainStartTime = clock();
        
        theDetector.AccessImage((unsigned char*)base, self.width, self.height ,bytesPerRow);
        
        // RM 11/20 - ID marker from UI
//        theDetector.SetMarkerID([self.markerID.text intValue]);
        theDetector.SetMarkerID(self.markerIDSetter.value);
        if ((theDetector.FindTarget()))
        {
            
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
            
            [self setSoundOnDetection];
            
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
        
        
        
        //     NSString* fpsString = [NSString stringWithFormat:@"%i fps", self.framesPerSecond];
        //
        //     //
        //
        //
        //     char* text	= (char *)[fpsString cStringUsingEncoding:NSASCIIStringEncoding];
        //     CGContextSelectFont(context, "Arial", 25, kCGEncodingMacRoman);
        //     CGContextSetTextDrawingMode(context, kCGTextFill);
        //     CGContextSetRGBFillColor(context, 0, 0, 0, 1);
        //
        //
        //     //rotate text
        //     CGContextSetTextMatrix(context, CGAffineTransformMakeRotation( M_PI/2 ));
        //
        //     CGContextShowTextAtPoint(context,30,400, text, strlen(text));
        
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
    self.maxFramesPerSecondSetter = nil;
    self.maxFramesPerSecond = nil;
    self.markerIDSetter = nil;
    self.markerID = nil;
    
    // should also set the outlets to nil…but instead it releases in dealloc!
}

- (void)dealloc {
	[self.captureSession release];
    [self.theBeep1 release];
    [self.theBeep2 release];
    [self.rotateLeft release];
    [self.rotateRight release];
    [self.rotateUp release];
    [self.rotateDown release];
    [self.rotateLeftAndUp release];
    [self.rotateLeftAndDown release];
    [self.rotateRightAndUp release];
    [self.rotateRightAndDown release];
    
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"<NumberOfQuintuples>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"%d\n",self.nRecorded] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.outFileHandler writeData:[[NSString stringWithFormat: @"</NumberOfQuintuples>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [self.outFileHandler closeFile];
    [self.motionManager stopAccelerometerUpdates];
    [self.motionManager release];
    [self.framesPerSecond release];
    [_maxFramesPerSecondSetter release];
    [_maxFramesPerSecond release];
    [_actualFramesPerSecond release];
    [_markerIDSetter release];
    [_markerID release];
//    [_setMaxDistance release];
    [_maxDistance release];
    [_whichLensSetter release];
    [_whichLens release];
    [_modalityForDirectionsSetter release];
    [_modalityForDirections release];
    [_maxFramesPerSecond release];
    [_maxDistanceSetter release];
    [_whichLensSetter release];
    [_modalityForDirectionsSetter release];
    [_markerIDSetter release];
    [_whichLensLabel release];
    [_maxDistanceLabel release];
    [_maxFramesPerSecondLabel release];
    [_modalityForDirectionLabel release];
    [_markerIDLabel release];
    [_snapshotButton release];
    [super dealloc];
}


//- (IBAction)takeSnapshot:(id)sender {
//}
- (IBAction)takeSnapshot:(id)sender {
    
    self.shouldTakeSnapshot = YES;
    time1 = clock();
}
@end