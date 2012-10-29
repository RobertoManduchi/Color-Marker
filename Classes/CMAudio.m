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

- (id) initWithName:(NSString*)sndTxt andType:(NSString*)sndType
{
	NSString *path = [[NSBundle mainBundle] pathForResource:sndTxt ofType:sndType];

	self.theAudio = [AVAudioPlayer alloc]; 

	if([self.theAudio initWithContentsOfURL:[NSURL fileURLWithPath:path] error:NULL]) {
		[self.theAudio autorelease];
  	}
	else {
		[self.theAudio release];
		self.theAudio = nil;
        return nil;
	}
	[self.theAudio setDelegate:self];
    self.theAudio.numberOfLoops = (NSInteger)-1;
    
    return self;
}

- (void) playIt {
    
    if (!self.theAudio.isPlaying) {
        [self.theAudio play];
    }
    
}
- (void) pauseIt {
    
    if (self.theAudio.isPlaying) {
        [self.theAudio pause];
    }
    
}

- (void)dealloc {
	[self.theAudio stop];
	[self.theAudio release];
    [super dealloc];
}

@end
