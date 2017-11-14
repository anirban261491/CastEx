//
//  CameraViewController.m
//  CastEx
//
//  Created by Anirban on 10/15/17.
//  Copyright © 2017 Anirban Bhattacharya (Student). All rights reserved.
//

#import "CameraViewController.h"

@interface CameraViewController ()<H264HwEncoderImplDelegate,GCDAsyncUdpSocketDelegate>
{
    AVCaptureDeviceInput *cameraDeviceInput;
    AVCaptureSession* captureSession;
    H264HwEncoderImpl *h264Encoder;
    dispatch_queue_t backgroundQueue,sendScreenFramesForUploadQueue;
    GCDAsyncUdpSocket *udpSocket;
    GCDAsyncSocket *tcpSocket;
    AVSampleBufferDisplayLayer *displayLayer;
    BOOL isBroadcasting;
    int packetNumber;
}
@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    packetNumber = 0;
    dispatch_queue_t queue = dispatch_queue_create("com.socketDelegate.queue", DISPATCH_QUEUE_SERIAL);
    backgroundQueue=dispatch_queue_create("com.livestream.backgroundQueue", DISPATCH_QUEUE_SERIAL);
    sendScreenFramesForUploadQueue=dispatch_queue_create("com.sendScreenFramesForUpload.Queue", DISPATCH_QUEUE_SERIAL);
    //udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:queue];
    tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:queue];
    
    NSError *err = nil;
    if (![tcpSocket acceptOnPort:1900 error:&err]){
        
        NSLog(@"Error in acceptOnPort:error: -> %@", err);
        
    }
    
    [self initializeEncoder];
    [self setupCamera];
    
    [self.view bringSubviewToFront:_recordStartStopButtonImageView];
    [self.view bringSubviewToFront:_recordStartStopButton];
    [self.view bringSubviewToFront:_backButtonImageView];
    [self.view bringSubviewToFront:_backButton];
}


- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    NSLog(@"Accepted new socket from %@:%hu", [newSocket connectedHost], [newSocket connectedPort]);
    
    tcpSocket = newSocket;
    //NSString *welcomMessage = @"Hello from the server\r\n";
    //[self.asyncSocket writeData:[welcomMessage dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:1];
    
    //[self.asyncSocket readDataWithTimeout:-1 tag:0];
    
}


-(void)setupCamera
{
    [self initializeDisplayLayer];
    [self initializeVideoCaptureSession];
    [captureSession startRunning];
    
   
    if(displayLayer)
    {
        [displayLayer flushAndRemoveImage];
    }
}

-(void)initializeEncoder
{
    h264Encoder = [H264HwEncoderImpl alloc];
    [h264Encoder initWithConfiguration];
    [h264Encoder initEncode:750 height:1334];
    h264Encoder.delegate = self;
}

-(void) initializeDisplayLayer
{
    //Initialize display layer
    displayLayer = [[AVSampleBufferDisplayLayer alloc] init];
    //Add the layer to the VideoView
    displayLayer.bounds = self.view.bounds;
    displayLayer.frame = self.view.frame;
    displayLayer.backgroundColor = [UIColor blackColor].CGColor;
    displayLayer.position = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    displayLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    // Remove from previous view if exists
    [displayLayer removeFromSuperlayer];
    
    [self.view.layer addSublayer:displayLayer];
}

-(void) initializeVideoCaptureSession
{
    // Create our capture session...
    captureSession = [AVCaptureSession new];
    
    // Get our camera device...
    //AVCaptureDevice *cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *cameraDevice = [self frontFacingCameraIfAvailable];
    
    NSError *error;
    
    // Initialize our camera device input...
    cameraDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:cameraDevice error:&error];
    
    // Finally, add our camera device input to our capture session.
    if ([captureSession canAddInput:cameraDeviceInput])
    {
        [captureSession addInput:cameraDeviceInput];
    }
    
    // Initialize image output
    AVCaptureVideoDataOutput *output = [AVCaptureVideoDataOutput new];
    
    [output setAlwaysDiscardsLateVideoFrames:YES];
    
    dispatch_queue_t videoDataOutputQueue = dispatch_queue_create("video_data_output_queue", DISPATCH_QUEUE_SERIAL);
    
    [output setSampleBufferDelegate:self queue:videoDataOutputQueue];
    [output setVideoSettings:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA],(id)kCVPixelBufferPixelFormatTypeKey,nil]];
    
    
    if( [captureSession canAddOutput:output])
    {
        [captureSession addOutput:output];
    }
    
    [[output connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
}


-(AVCaptureDevice *)frontFacingCameraIfAvailable
{
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices)
    {
        if (device.position == AVCaptureDevicePositionFront)
        {
            captureDevice = device;
            break;
        }
    }
    
    //  couldn't find one on the front, so just get the default video device.
    if (!captureDevice)
    {
        captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    return captureDevice;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if ([connection isVideoOrientationSupported]) {
        [connection setVideoOrientation:[UIDevice currentDevice].orientation];
    }
    [displayLayer enqueueSampleBuffer:sampleBuffer];
    
    if(isBroadcasting)
        [h264Encoder encode:sampleBuffer];
}

-(void)formAndSendNALUnits:(NSData*)data
{
    const char startCode[] = "\x00\x00\x00\x01";
    size_t length = (sizeof startCode) - 1;
    //NSMutableData *NALUnit = [NSMutableData dataWithBytes:&packetNumber length:sizeof(int)];
    NSMutableData *NALUnit=[NSMutableData dataWithBytes:startCode length:length];
    //[NALUnit appendBytes:startCode length:length];
    [NALUnit appendData:data];
    
    [tcpSocket writeData:NALUnit withTimeout:-1 tag:0];
    //[udpSocket sendData:NALUnit toHost:@"172.20.10.4" port:1900 withTimeout:-1 tag:0];
    //packetNumber++;
   // [udpSocket sendData:NALUnit toHost:@"172.20.10.5" port:1900 withTimeout:-1 tag:0];
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
        [_recordStartStopButtonImageView setImage:[UIImage imageNamed:@"recordButton.png"]];
    }
    else
    {
        isBroadcasting = true;
        [_recordStartStopButtonImageView setImage:[UIImage imageNamed:@"stopButton.png"]];
    }
}

- (IBAction)backButtonPressed:(id)sender {
    if([captureSession isRunning])
    {
        [self stopCaputureSession];
    }
    [h264Encoder End];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void) stopCaputureSession
{
    [captureSession stopRunning];
    [displayLayer flushAndRemoveImage];
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
