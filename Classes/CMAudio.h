//
//  CMAudio.h
//  MyAVController
//
//  Created by Roberto Manduchi on 10/26/12.
//
//

#import <Foundation/Foundation.h>
#import "AVFoundation/AVAudioPlayer.h"

@interface CMAudio : NSObject

@property (nonatomic,retain) AVAudioPlayer* theAudio;
-(void) playIt:(NSString*)sndTxt andType:(NSString*)sndType;
@end
