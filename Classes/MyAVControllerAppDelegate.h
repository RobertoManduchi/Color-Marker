#import <UIKit/UIKit.h>

//@class WelcomeViewController;

/* test RM
@class MyAVController;

@interface MyAVControllerAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
//    WelcomeViewController *viewController;
    MyAVController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
//@property (nonatomic, retain) IBOutlet WelcomeViewController *viewController;

@property (nonatomic, retain) IBOutlet
    MyAVController  *viewController;

@end

*/

@interface MyAVControllerAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
