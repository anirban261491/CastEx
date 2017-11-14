//
//  VideoViewController.h
//  CastEx
//
//  Created by Anirban on 10/15/17.
//  Copyright © 2017 Anirban Bhattacharya (Student). All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "GCDAsyncUdpSocket.h"
#import "H264HwEncoderImpl.h"
#import <ReplayKit/ReplayKit.h>
@interface VideoViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *videoView;

@end
