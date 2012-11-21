//#include <opencv2/opencv.hpp>
//#include <opencv2/core/core.hpp>
#import "MyAVController.h"
#import "CMDetect.hpp"
#import "CMAudio.h"

int nRecorded = 0;
int  framesPerSecond=0,frameCount = 0;
float start_time, mainStartTime, startTimeExpLock;
int countFramesForLock = 0;

#define MIN_FRAMES_N_FOR_EXP_LOCK   2
#define SECONDS_BEFORE_EXP_UNLOCK   2.


// Test 9/1
NSString * path = [[NSBundle mainBundle] pathForResource:  @"CMUserParams" ofType: @"xml"];
std::string userParsFileName = [path cStringUsingEncoding:1];

/**** this works!!! ***/
//NSString * path2  = [[NSBundle mainBundle] pathForResource:  @"iPhone-9-21-12" ofType: @"xml"];
/*********************/

NSString * path2  = [[NSBundle mainBundle] pathForResource:  @"iPhone-11-13-12" ofType: @"xml"];
std::string classParsFileName = [path2 cStringUsingEncoding:1];

CMDetect theDetector(userParsFileName,classParsFileName);
// When am I going to destroy it ?!?!?!?
//////////

// RM 10/25
CMAudio* theBeep1 = [[CMAudio alloc] initWithName:@"beep-1" andType:@"aif"];  // when am I going to deallocate it?x
CMAudio* theBeep2 = [[CMAudio alloc] initWithName:@"beep-2" andType:@"aif"];  // when am I going to deallocate it?x



// RM 10/26
//NSString * outFilePath;

//NSFileHandle *outFileHandler;// = [NSFileHandle alloc];
NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

NSString *documentsDir = [documentPaths objectAtIndex:0];
NSString *outFilePath = [[NSString alloc] initWithFormat:@"%@",[documentsDir stringByAppendingPathComponent:@"Points.xml"]];

BOOL openedFile = [[NSFileManager defaultManager] createFileAtPath:outFilePath contents:nil attributes:nil];

NSFileHandle *outFileHandler  = [NSFileHandle fileHandleForWritingToURL:
                   [NSURL fileURLWithPath:outFilePath] error:NULL];




////
@implementation MyAVController

@synthesize captureSession = _captureSession;
@synthesize imageView = _imageView;
@synthesize customLayer = _customLayer;
@synthesize prevLayer = _prevLayer;

int nFrames;

#pragma mark -
#pragma mark Initialization
- (id)init {
	self = [super init];
	if (self) {
		/*We initialize some variables (they might be not initialized depending on what is commented or not)*/
		self.imageView = nil;
		self.prevLayer = nil;
		self.customLayer = nil;
        
        self.shouldTakeSnapshot = NO;
	}
	return self;
}

- (void)viewDidLoad {
	/*We intialize the capture*/
	[self initCapture];
}


- (void)initCapture {
    
    // RM 10/26
    // TODO: must manage errors
    [theBeep1 playIt];
    [theBeep1.theAudio pause];
    [theBeep2 playIt];
    [theBeep2.theAudio pause];

   
	/*We setup the input*/
    
    
    AVCaptureDevice     *theDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput
										  deviceInputWithDevice:theDevice
										  error:nil];

    
    // test RM 11/11
    [theDevice lockForConfiguration:(nil)];
    
//    theDevice.whiteBalanceMode  = AVCaptureWhiteBalanceModeLocked;
    
    [theDevice unlockForConfiguration];
    
    
    
    
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
        
	
}




/*** RM 6/15 - test ***/
 - (void)captureOutput:(AVCaptureOutput *)captureOutput
 didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
 fromConnection:(AVCaptureConnection *)connection 
 { 
// float start_time = clock();
 
//     printf("captureOutput was called \n");
     
//     if (maxFramesPerSecond.text == nil) {
//         NSString *myText = [[NSString alloc] initWithFormat:@"%d", (int)self.setMaxFramesPerSecond.value];
     // then we need to clear it?

//     [self.maxFramesPerSecond performSelectorOnMainThread : @ selector(setText : ) withObject:myText waitUntilDone:YES];

     if ((int)self.setMarkerID != [self.markerID.text intValue]) {
         NSString *theText;
         theText = [NSString stringWithFormat:@"%d", (int)self.setMarkerID.value];
         [self.markerID performSelectorOnMainThread : @ selector(setText : ) withObject:theText waitUntilDone:YES];
         
     }
     
      if ((int)self.setMaxFramesPerSecond.value != [self.maxFramesPerSecond.text intValue]) {
          NSString *theText;
          if (self.setMaxFramesPerSecond.value == 10) 
              theText = @"- - -";
          else
              theText = [NSString stringWithFormat:@"%d", (int)self.setMaxFramesPerSecond.value];
              
          [self.maxFramesPerSecond performSelectorOnMainThread : @ selector(setText : ) withObject:theText waitUntilDone:YES];

//          self.maxFramesPerSecond.text = [NSString stringWithFormat:@"%d", (int)self.setMaxFramesPerSecond.value];
     }
//     printf("%d\n",(int) setMaxFramesPerSecond.value);
 
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
     size_t width = CVPixelBufferGetWidth(imageBuffer); 
     size_t height = CVPixelBufferGetHeight(imageBuffer); 
 
     // RM - test
     
     // we should be able to allocate this buffer once and or all to save time (tried - didn't help)
     uint8_t *base = (uint8_t *) malloc(bytesPerRow * height * sizeof(uint8_t));
     memcpy(base, baseAddress, bytesPerRow * height);
     CVPixelBufferUnlockBaseAddress(imageBuffer,0);
     
     
#if 1
     
     double theMinPeriod;
     if (self.setMaxFramesPerSecond.value == 10) // this is the max - should be set as parameter
         theMinPeriod = 0.;
     else
         theMinPeriod = (double)CLOCKS_PER_SEC / (double)self.setMaxFramesPerSecond.value;
     
     if (clock() - mainStartTime > theMinPeriod)
     {
         mainStartTime = clock();
         
         theDetector.AccessImage((unsigned char*)base, width, height ,bytesPerRow);
     
     // RM 11/20 - ID marker from UI
         theDetector.SetMarkerID([self.markerID.text intValue]);
         
     if ((theDetector.FindTarget()))
     {
         countFramesForLock++;
         if (countFramesForLock >= MIN_FRAMES_N_FOR_EXP_LOCK) {
             // good exposure - lock it!
             AVCaptureDevice     *theDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
             [theDevice lockForConfiguration:(nil)];
             theDevice.exposureMode = AVCaptureExposureModeLocked;
             [theDevice unlockForConfiguration];
             
             startTimeExpLock = clock();
         }
         [outFileHandler writeData:[[NSString stringWithFormat: @"<Quintuple id=\"%d\">\n",++nRecorded] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"<Center>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"<X>"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"%d",theDetector.outValues.center.iX] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"</X>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"<Y>"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"%d",theDetector.outValues.center.iY] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"</Y>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"</Center>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat:          @"<Top>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"<X>"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"%d",theDetector.outValues.top.iX] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"</X>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"<Y>"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"%d",theDetector.outValues.top.iY] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"</Y>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"</Top>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat:          @"<Bottom>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"<X>"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"%d",theDetector.outValues.bottom.iX] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"</X>"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"<Y>"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"%d",theDetector.outValues.bottom.iY] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"</Y>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"</Bottom>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat:          @"<Left>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"<X>"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"%d",theDetector.outValues.left.iX] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"</X>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"<Y>"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"%d",theDetector.outValues.left.iY] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"</Y>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"</Left>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat:          @"<Right>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"<X>"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"%d",theDetector.outValues.right.iX] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"</X>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"<Y>"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"%d",theDetector.outValues.right.iY] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"</Y>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"</Right>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
         [outFileHandler writeData:[[NSString stringWithFormat: @"</Quintuple>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
         
         
         if ((theDetector.outValues.center.iX < theDetector.IMAGE_W * 3/5) &&
             (theDetector.outValues.center.iX > theDetector.IMAGE_W * 2/5)) {
             theBeep1.theAudio.volume = 1.;
             theBeep2.theAudio.volume = 1.;
         }
         else{
             theBeep1.theAudio.volume = 0.1;
             theBeep2.theAudio.volume = 0.1;
         }
         if (theDetector.rad1 < 100)
         {
             [theBeep1 playIt];
             [theBeep2 pauseIt];
         }
         else
         {
             [theBeep2 playIt];
             [theBeep1 pauseIt];
         }
     }     
     else   // not found
     {
         [theBeep1 pauseIt];
         [theBeep2 pauseIt];
         
         countFramesForLock = 0;
         
         if (((clock() - startTimeExpLock) > SECONDS_BEFORE_EXP_UNLOCK * (double)CLOCKS_PER_SEC))
             
         {
             // unlock exposure
             AVCaptureDevice     *theDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
             if (theDevice.exposureMode == AVCaptureExposureModeLocked) {             
                 [theDevice lockForConfiguration:(nil)];
                 theDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
                 [theDevice unlockForConfiguration];
             }
         }
     }
         ///// test 11/8/12 - show text
         // compute fps
         //     int  framesPerSecond = (int) (1/ ((clock() - start_time) / (double)CLOCKS_PER_SEC));
         if ((clock() - start_time) > (double)CLOCKS_PER_SEC) {
             framesPerSecond = frameCount;
             frameCount = 0;
             start_time = clock();
             [self.actualFramesPerSecond performSelectorOnMainThread : @ selector(setText : )
                   withObject:[NSString stringWithFormat:@"%d", (int)framesPerSecond]
                waitUntilDone:NO];
         }
         else
             frameCount++;
         
         
         
         //     NSString* fpsString = [NSString stringWithFormat:@"%i fps", framesPerSecond];
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
     uint8_t *tp1, *tp2;     
//     tp1 = baseAddress;
     tp1 = base;
     for (int iy=0;iy<height; iy++,tp1 += bytesPerRow){
         tp2 = tp1;
         for (int ix=0 ;ix<bytesPerRow;ix+=4,tp2+=4){
 //            *tp2 = *(tp2+2);
 //            *(tp2+2)=255;
         }
      }
     // RM - test
     CVPixelBufferLockBaseAddress(imageBuffer,0);
     memcpy(baseAddress, base, bytesPerRow * height);
     free(base);
      
     /////
     
     // Create a device-dependent RGB color space
     CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
 
     // Create a bitmap graphics context with the sample buffer data
     CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, 
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
         if (theDevice.exposureMode == AVCaptureExposureModeLocked) {
             theDevice.exposureMode  = AVCaptureExposureModeContinuousAutoExposure;
         }
         else
             theDevice.exposureMode = AVCaptureExposureModeLocked;
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

 
/**** end RM 6/15 - test ***/
#else
- (void)captureOutput:(AVCaptureOutput *)captureOutput 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
	   fromConnection:(AVCaptureConnection *)connection 
{ 
//    float start_time = clock();

    printf("captureOutput was called \n");
    
	/*We create an autorelease pool because as we are not in the main_queue our code is
	 not executed in the main thread. So we have to create an autorelease pool for the thread we are in*/
	// Get CVImage from sample buffer
    //CVImageBufferRef cvImage = CMSampleBufferGetImageBuffer(sampleBuffer);
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
    /*Lock the image buffer*/
    CVPixelBufferLockBaseAddress(imageBuffer,0); 
    //for 420f and 420v then this points to CVPlanarPixelBufferInfo_YCbCrBiPlanar
    /*Get information about the image*/
    uint8_t *baseAddress = (uint8_t *) CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    //size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
    size_t width = CVPixelBufferGetWidth(imageBuffer); 
    size_t height = CVPixelBufferGetHeight(imageBuffer);  
    
    // test RM 6/15
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
    
    //This function Michael wrote to quickly extract UIimag
//    UIImage *uiImg = [self UIImageFromBits: baseAddress height:height width:width];
//
    UIImage *uiImg = [self UIImageFromBits: baseAddress height:height width:width bytesPerRow:bytesPerRow];

    
    //This function Michael wrote to quickly get IPlImage
    //IplImage *img = [self CreateGrayIplImageFromPlanar: baseAddress height:height width:width];
    
    //notice we use this selector to call our setter method 'setImg' Since only the main thread can update this 
    
	[self.imageView performSelectorOnMainThread:@selector(setImage:) withObject:uiImg waitUntilDone:YES];    

    
    float time_in_seconds = (clock() - start_time) / (double)CLOCKS_PER_SEC;
    printf("%f time spent processing frame\n",time_in_seconds);
    
    /*We unlock the  image buffer*/
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
	
    [pool drain];
} 
#endif


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
    self.setMaxFramesPerSecond = nil;
    self.maxFramesPerSecond = nil;
    self.setMarkerID = nil;
    self.markerID = nil;
    
    // should also set the outlets to nil…but instead it releases in dealloc!
}

- (void)dealloc {
	[self.captureSession release];
    [theBeep1 release];
    [theBeep2 release];
    [outFileHandler writeData:[[NSString stringWithFormat: @"<NumberOfQuintuples>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [outFileHandler writeData:[[NSString stringWithFormat: @"%d\n",nRecorded] dataUsingEncoding:NSUTF8StringEncoding]];
    [outFileHandler writeData:[[NSString stringWithFormat: @"</NumberOfQuintuples>\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [outFileHandler closeFile];
    [framesPerSecond release];
    [_maxFramesPerSecond release];
    [_setMaxFramesPerSecond release];
    [_maxFramesPerSecond release];
    [_maxFramesPerSecond release];
    [_actualFramesPerSecond release];
    [_setMarkerID release];
    [_markerID release];
    [super dealloc];
}


//- (IBAction)takeSnapshot:(id)sender {
//}
- (IBAction)takeSnapshot:(id)sender {
    
    self.shouldTakeSnapshot = YES;
    time1 = clock();
}
@end