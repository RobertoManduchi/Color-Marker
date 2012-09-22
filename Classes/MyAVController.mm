#import "MyAVController.h"
#import "CMDetect.hpp"


// Test 9/1
NSString * path = [[NSBundle mainBundle] pathForResource:  @"CMUserParams" ofType: @"xml"];
std::string userParsFileName = [path cStringUsingEncoding:1];

NSString * path2  = [[NSBundle mainBundle] pathForResource:  @"iPhone-9-21-12" ofType: @"xml"];
std::string classParsFileName = [path2 cStringUsingEncoding:1];

CMDetect theDetector(userParsFileName,classParsFileName);
// When am I going to destroy it ?!?!?!?
//////////


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
    
	/*We setup the input*/
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput 
										  deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] 
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
    
    
	
}


/*** RM 6/15 - test ***/
#if 1
 - (void)captureOutput:(AVCaptureOutput *)captureOutput 
 didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
 fromConnection:(AVCaptureConnection *)connection 
 { 
 float start_time = clock();
 
//     printf("captureOutput was called \n");
 
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
     
     // we should be able to allocate this buffer once and or all to save time
     uint8_t *base = (uint8_t *) malloc(bytesPerRow * height * sizeof(uint8_t));
     memcpy(base, baseAddress, bytesPerRow * height);
     CVPixelBufferUnlockBaseAddress(imageBuffer,0);
      
     //////
//     // Test 9/1
//     NSString * path = [[NSBundle mainBundle] pathForResource:  @"CMUserParams" ofType: @"xml"];
//     std::string userParsFileName = [path cStringUsingEncoding:1];
//
//     path = [[NSBundle mainBundle] pathForResource:  @"test8-30_4" ofType: @"xml"];
//     std::string classParsFileName = [path cStringUsingEncoding:1];
//
//     CMDetect theDetector(userParsFileName,classParsFileName);
     
#if 1
     theDetector.AccessImage((unsigned char*)base, width, height ,bytesPerRow);
     theDetector.FindTarget();
     
#ifdef INVERTEVERYFEWFFRAMES
     if ((nFrames++ % 10) == 0){
         nFrames = 1;
         uint8_t *tp1, *tp2;
         tp1 = base;
         for (int iy=0;iy<height; iy++,tp1 += bytesPerRow){
             tp2 = tp1;
             for (int ix=0 ;ix<bytesPerRow;ix+=4,tp2+=4){
                 *tp2 = 255 - *tp2;
                 *(tp2+1) = 255 - *(tp2+1);
                 *(tp2+2) = 255 - *(tp2+2);
             }
         }
     }
#endif
     
     ////
#else
/// RM 6/15 
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
#endif
     CVPixelBufferLockBaseAddress(imageBuffer,0);
     memcpy(baseAddress, base, bytesPerRow * height);
     free(base);
      
     /////
     
     // Create a device-dependent RGB color space
     CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
 
     // Create a bitmap graphics context with the sample buffer data
     CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, 
                                                  bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst); 
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
         
         
//         imageName = [NSString stringWithFormat:@"%d",self.indPicture++]; //%d or %i both is ok.
         imageName = [NSMutableString stringWithFormat:@"%d",self.indPicture++]; //%d or %i both is ok.
         
//         [imageName insertString:@"image" atIndex: (NSUInteger) 0];
         [imageName appendString:@".png"];
         // test RM 9/15 - save image
         NSData *pngData = UIImagePNGRepresentation(image);
         //     NSData *jpgData = UIImageJPEGRepresentation(image, 1.0);
         
         //save to the default 100Apple(Camera Roll) folder.
         
         //     [pngData writeToFile:@"/private/var/mobile/Media/DCIM/100APPLE/customImageFilename.jpg" atomically:NO];
         
         
         NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
         NSString *documentsPath = [paths objectAtIndex:0]; //Get the docs directory
//         NSString *filePath = [documentsPath stringByAppendingPathComponent:@"image.png"]; //Add the file name
         NSString *filePath = [documentsPath stringByAppendingPathComponent:imageName]; //Add the file name
         
         //     NSString *filePath = @"/private/var/mobile/Media/DCIM/100APPLE/customImageFilename.PNG";
          [pngData writeToFile:filePath atomically:YES]; //
         self.shouldTakeSnapshot = NO;
         
     }
     
     //     NSString *filePath = @"/private/var/mobile/Media/DCIM/100APPLE/IMG_0050.JPG";
//     [jpgData writeToFile:filePath atomically:NO]; //Write the file
//     [jpgData writeToFile:@"/private/var/mobile/Media/DCIM/100APPLE/IMG_0050.JPG" atomically:NO]; //Write the file
 
//     UIImageWriteToSavedPhotosAlbum(image,nil,nil,nil);
     
     // Release the Quartz image
     CGImageRelease(quartzImage);     
    
//notice we use this selector to call our setter method 'setImg' Since only the main thread can update this 

//     if ((nFrames++ % 1) == 0){
//         nFrames = 1;
         [self.imageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:YES];
//     }
     

//    float time_in_seconds = (clock() - start_time) / (double)CLOCKS_PER_SEC;
//    printf("%f time spent processing frame\n",time_in_seconds);


[pool drain];
} 

 
/**** end RM 6/15 - test ***/
#else
- (void)captureOutput:(AVCaptureOutput *)captureOutput 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
	   fromConnection:(AVCaptureConnection *)connection 
{ 
    float start_time = clock();

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
}

- (void)dealloc {
	[self.captureSession release];
    [super dealloc];
}


//- (IBAction)takeSnapshot:(id)sender {
//}
- (IBAction)takeSnapshot:(id)sender {
    
    self.shouldTakeSnapshot = YES;
    time1 = clock();
}
@end