#import "WelcomeViewController.h"
#import "MyAVController.h"

@implementation WelcomeViewController



- (IBAction)startFlashcodeDetection {
	[self  presentViewController:[[MyAVController alloc] init] animated:YES completion: NULL];
//    - (IBAction)startFlashcodeDetection {
//        [self presentModalViewController:[[MyAVController alloc] init] animated:YES];
}

- (void)dealloc {
    [super dealloc];
}

@end
