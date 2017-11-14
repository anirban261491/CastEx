//
//  CameraViewController.h
//  CastEx
//
//  Created by Anirban on 10/15/17.
//  Copyright © 2017 Anirban Bhattacharya (Student). All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "GCDAsyncUdpSocket.h"
#import "GCDAsyncSocket.h"
#import "H264HwEncoderImpl.h"
@interface CameraViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *recordStartStopButtonImageView;
@property (weak, nonatomic) IBOutlet UIButton *recordStartStopButton;
@property (weak, nonatomic) IBOutlet UIImageView *backButtonImageView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@end
