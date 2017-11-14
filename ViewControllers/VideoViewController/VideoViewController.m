//
//  VideoViewController.m
//  CastEx
//
//  Created by Anirban on 10/15/17.
//  Copyright © 2017 Anirban Bhattacharya (Student). All rights reserved.
//

#import "VideoViewController.h"
#import "OverLayViewController.h"

@interface VideoViewController ()<H264HwEncoderImplDelegate,GCDAsyncUdpSocketDelegate>
{
    H264HwEncoderImpl *h264Encoder;
    dispatch_queue_t backgroundQueue,sendScreenFramesForUploadQueue;
    GCDAsyncUdpSocket *udpSocket;
    BOOL isBroadcasting;
    RPScreenRecorder *recorder;
    int FR;
    UIWindow *overlayWindow;
    OverLayViewController *v;
    AVPlayer *player;
    AVPlayerViewController *av;
}
@end

@implementation VideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    dispatch_queue_t queue = dispatch_queue_create("com.socketDelegate.queue", DISPATCH_QUEUE_SERIAL);
    backgroundQueue=dispatch_queue_create("com.livestream.backgroundQueue", DISPATCH_QUEUE_SERIAL);
    sendScreenFramesForUploadQueue=dispatch_queue_create("com.sendScreenFramesForUpload.Queue", DISPATCH_QUEUE_SERIAL);
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:queue];
    
    
    [self initializeEncoder];
    [self initializeScreenRecorder];
    [self loadAndStartVideo];
    [self setupOverlayWindow];
}

-(void)setupOverlayWindow
{
    v = [self.storyboard instantiateViewControllerWithIdentifier:@"OverLayViewController"];
    overlayWindow = [[UIWindow alloc] initWithFrame:self.view.bounds];
    overlayWindow.backgroundColor = [UIColor clearColor];
    overlayWindow.userInteractionEnabled = false;
    overlayWindow.rootViewController = v;
    [overlayWindow makeKeyAndVisible];
}


-(void)initializeEncoder
{
    h264Encoder = [H264HwEncoderImpl alloc];
    [h264Encoder initWithConfiguration];
    [h264Encoder initEncode:750 height:1334];
    h264Encoder.delegate = self;
}

-(void)loadAndStartVideo
{
    NSString* filePath=[[NSBundle mainBundle] pathForResource:@"trailer" ofType:@"mov"];
    
    NSURL *videoURL = [NSURL fileURLWithPath:filePath];
    player = [AVPlayer playerWithURL:videoURL];
    av = [AVPlayerViewController new];
    av.player = player;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    av.view.frame = _videoView.bounds;
    [self addChildViewController:av];
    [_videoView addSubview:av.view];
    [av didMoveToParentViewController:self];
    [player play];
}

-(void)initializeScreenRecorder
{
    FR=0;
    recorder=[RPScreenRecorder sharedRecorder];
}

-(void)formAndSendNALUnits:(NSData*)data
{
    const char startCode[] = "\x00\x00\x00\x01";
    size_t length = (sizeof startCode) - 1;
    NSMutableData *NALUnit=[NSMutableData dataWithBytes:startCode length:length];
    [NALUnit appendData:data];
    [udpSocket sendData:NALUnit toHost:@"172.20.10.2" port:1900 withTimeout:-1 tag:0];
    [udpSocket sendData:NALUnit toHost:@"172.20.10.6" port:1900 withTimeout:-1 tag:0];
}

- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps
{
    
    dispatch_async(backgroundQueue, ^{
        [self formAndSendNALUnits:sps];
        [self formAndSendNALUnits:pps];
    });
    
}
- (void)gotEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame
{
    
    dispatch_async(backgroundQueue, ^{
        [self formAndSendNALUnits:data];
    });
    
}
- (IBAction)startBroadcasting:(id)sender {
    
    
    if(isBroadcasting)
    {
        isBroadcasting = false;
        [recorder stopCaptureWithHandler:nil];
        [v startStopBroadcasting];
    }
    else
    {
        isBroadcasting = true;
        [recorder startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
            if(bufferType==1)
            {
                FR=(FR+1)%2;
                if(FR)
                    [h264Encoder encode:sampleBuffer];
            }
        } completionHandler:nil];
        [v startStopBroadcasting];
    }
}
- (IBAction)backButtonPressed:(id)sender {
    if(isBroadcasting)
    {
        isBroadcasting = false;
        [recorder stopCaptureWithHandler:nil];
        [v startStopBroadcasting];
    }
    
    [player pause];
    player = nil;
    [av removeFromParentViewController];
    [av.view removeFromSuperview];
    av = nil;
    
    [h264Encoder End];
    
    overlayWindow.hidden = true;
    overlayWindow = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
