//
//  FileViewController.h
//  CastEx
//
//  Created by Anirban on 10/15/17.
//  Copyright © 2017 Anirban Bhattacharya (Student). All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "GCDAsyncUdpSocket.h"
#import "H264HwEncoderImpl.h"
#import <ReplayKit/ReplayKit.h>
@interface FileViewController : UIViewController
@property (weak, nonatomic) IBOutlet WKWebView *webView;
@property BOOL isFile;
@end
