//
//  CMAudio.m
//  MyAVController
//
//  Created by Roberto Manduchi on 10/26/12.
//
//

#import "CMAudio.h"
#import "AVFoundation/AVAudioPlayer.h"

@implementation CMAudio

- (void) playIt:(NSString*)sndTxt andType:(NSString*)sndType {
	
	NSString *path = [[NSBundle mainBundle] pathForResource:sndTxt ofType:sndType];
	
//	self.theAudio = [[AVAudioPlayer alloc] init]; // <<=== ???
	self.theAudio = [AVAudioPlayer alloc]; // <<=== ???
    
    
    
	if([self.theAudio initWithContentsOfURL:[NSURL fileURLWithPath:path] error:NULL]) {
		[self.theAudio autorelease];
	}
	else {
		[self.theAudio release];
		self.theAudio = nil;
	}
	[self.theAudio setDelegate:self];
	
    self.theAudio.numberOfLoops = (NSInteger)-1;
	[self.theAudio play];
}

- (void)dealloc {
	[self.theAudio stop];
	[self.theAudio release];
    [super dealloc];
}

@end
