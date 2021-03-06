//
//  ViewController.m
//  H264DecodeDemo
//
//  Created by Yao Dong on 15/8/6.
//  Copyright (c) 2015年 duowan. All rights reserved.
//

#import "StreamViewController.h"
#import "AAPLEAGLLayer.h"
#import <VideoToolbox/VideoToolbox.h>


@interface StreamViewController ()
{
    uint8_t *_sps;
    NSInteger _spsSize;
    uint8_t *_pps;
    NSInteger _ppsSize;
    VTDecompressionSessionRef _deocderSession;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
    NSMutableArray * NALBuffer;
    AAPLEAGLLayer *_glLayer;
}
@end

static void didDecompress( void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
    
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}

@implementation StreamViewController
GCDAsyncUdpSocket *udpSocket;
GCDAsyncSocket *tcpSocket;
dispatch_queue_t receiveDataQueue;
dispatch_queue_t writeToFileQueue;
dispatch_queue_t sendToDecodeQueue;

-(BOOL)initH264Decoder {
    if(_deocderSession) {
        return YES;
    }
    
    const uint8_t* const parameterSetPointers[2] = { _sps, _pps };
    const size_t parameterSetSizes[2] = { _spsSize, _ppsSize };
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2, //param count
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4, //nal start code size
                                                                          &_decoderFormatDescription);
    
    if(status == noErr) {
        CFDictionaryRef attrs = NULL;
        const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
        //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
        //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
        uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
        attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
        
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputCallback = didDecompress;
        callBackRecord.decompressionOutputRefCon = NULL;
        
        status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                              _decoderFormatDescription,
                                              NULL, attrs,
                                              &callBackRecord,
                                              &_deocderSession);
        CFRelease(attrs);
    } else {
        NSLog(@"IOS8VT: reset decoder session failed status=%d", status);
    }

    return YES;
}

-(void)clearH264Deocder {
    if(_deocderSession) {
        VTDecompressionSessionInvalidate(_deocderSession);
        CFRelease(_deocderSession);
        _deocderSession = NULL;
    }
    
    if(_decoderFormatDescription) {
        CFRelease(_decoderFormatDescription);
        _decoderFormatDescription = NULL;
    }
    
    free(_sps);
    free(_pps);
    _spsSize = _ppsSize = 0;
}

-(CVPixelBufferRef)decode:(uint8_t*)buffer Size:(NSInteger)size{
    CVPixelBufferRef outputPixelBuffer = NULL;
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                          (void*)buffer, size,
                                                          kCFAllocatorNull,
                                                          NULL, 0, size,
                                                          0, &blockBuffer);
    if(status == kCMBlockBufferNoErr) {
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = {size};
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           _decoderFormatDescription ,
                                           1, 0, NULL, 1, sampleSizeArray,
                                           &sampleBuffer);
        if (status == kCMBlockBufferNoErr && sampleBuffer) {
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagOut = 0;
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_deocderSession,
                                                                      sampleBuffer,
                                                                      flags,
                                                                      &outputPixelBuffer,
                                                                      &flagOut);
            
            if(decodeStatus == kVTInvalidSessionErr) {
                NSLog(@"IOS8VT: Invalid session, reset decoder session");
            } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                NSLog(@"IOS8VT: decode failed status=%d(Bad data)", decodeStatus);
            } else if(decodeStatus != noErr) {
                NSLog(@"IOS8VT: decode failed status=%d", decodeStatus);
            }
            
            CFRelease(sampleBuffer);
        }
        CFRelease(blockBuffer);
    }
    
    return outputPixelBuffer;
}

-(void)parseNALU:(NSData*)data {
    
    
        uint8_t *buffer=(uint8_t*)data.bytes;
        NSInteger size=[data length];
    
    
        uint32_t nalSize = (uint32_t)(size - 4);
        uint8_t *pNalSize = (uint8_t*)(&nalSize);
        buffer[0] = *(pNalSize + 3);
        buffer[1] = *(pNalSize + 2);
        buffer[2] = *(pNalSize + 1);
        buffer[3] = *(pNalSize);
    
        CVPixelBufferRef pixelBuffer = NULL;
        int nalType = buffer[4] & 0x1F;
    
        switch (nalType) {
            case 0x05:
                NSLog(@"Nal type is IDR frame");
                if([self initH264Decoder]) {
                    pixelBuffer = [self decode:buffer Size:size];
                }
                break;
            case 0x07:
                NSLog(@"Nal type is SPS");
                _spsSize = size - 4;
                _sps = malloc(_spsSize);
                memcpy(_sps, buffer + 4, _spsSize);
                break;
            case 0x08:
                NSLog(@"Nal type is PPS");
                _ppsSize = size - 4;
                _pps = malloc(_ppsSize);
                memcpy(_pps, buffer + 4, _ppsSize);
                break;
                
            default:
                NSLog(@"Nal type is B/P frame");
                pixelBuffer = [self decode:buffer Size:size];
                break;
        }
        
        if(pixelBuffer) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                _glLayer.pixelBuffer = pixelBuffer;
            });
            
            CVPixelBufferRelease(pixelBuffer);
        }
        
        NSLog(@"Read Nalu size %ld", size);
    

}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _glLayer = [[AAPLEAGLLayer alloc] initWithFrame:self.view.bounds];
    [self.view.layer addSublayer:_glLayer];
    
    [self.view bringSubviewToFront:_backButtonImageView];
    [self.view bringSubviewToFront:_backButton];
    
    NALBuffer=[NSMutableArray new];
    receiveDataQueue = dispatch_queue_create("com.receiveDataQueue.queue", DISPATCH_QUEUE_SERIAL);
    writeToFileQueue = dispatch_queue_create("com.writeToFile.queue", DISPATCH_QUEUE_SERIAL);
    sendToDecodeQueue = dispatch_queue_create("com.sendToDecode.queue", DISPATCH_QUEUE_SERIAL);
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:receiveDataQueue];
    
    //tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:receiveDataQueue];
    
    //[self connectToServer];
     [self openSocket];
}

-(void)connectToServer {
    NSError *err = nil;
    if (![tcpSocket connectToHost:@"172.20.10.2" onPort:1900 error:&err]) // Asynchronous!
    {
        // If there was an error, it's likely something like "already connected" or "no delegate set"
        NSLog(@"I goofed: %@", err);
        return;
    }
}

- (void)socket:(GCDAsyncSocket *)sender didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"Cool, I'm connected! That was easy.");
    
    [tcpSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sender didReadData:(NSData *)data withTag:(long)tag
{
    //NSLog(@"Received Data: %@",data);
    dispatch_async(writeToFileQueue, ^{
        [self addToBuffer:data];
    });
    dispatch_async(writeToFileQueue, ^{
        [self readFromBufferAndSend];
    });
    [tcpSocket readDataWithTimeout:-1 tag:0];
}

-(void)openSocket
{
    NSError *error;
    
    if (![udpSocket bindToPort:1900 error:&error])
    {
        NSLog(@"Bind error");
    }
//    if (![udpSocket joinMulticastGroup:@"224.0.113.0" error:&error])
//    {
//        NSLog(@"Group joining error");
//    }
    if (![udpSocket beginReceiving:&error])
    {
        [udpSocket close];
        
        NSLog(@"Receiving error");
        return;
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    dispatch_async(writeToFileQueue, ^{
        [self addToBuffer:data];
    });
    dispatch_async(writeToFileQueue, ^{
        [self readFromBufferAndSend];
    });
}

-(void)addToBuffer:(NSData*)NALUnit
{
    [NALBuffer addObject:NALUnit];
}


-(void)readFromBufferAndSend
{
    NSData *NALUnit = [NALBuffer objectAtIndex:0];
    [NALBuffer removeObjectAtIndex:0];
    dispatch_async(sendToDecodeQueue, ^{
        [self parseNALU:NALUnit];
    });
}
- (IBAction)backButtonPressed:(id)sender {
    [self clearH264Deocder];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
