#import <UIKit/UIKit.h>

#import "MyAVControllerAppDelegate.h"

int main(int argc, char *argv[]) {

/* RM
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, nil);
    [pool release];
    return retVal;
 */
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([MyAVControllerAppDelegate class]));
    }

}
