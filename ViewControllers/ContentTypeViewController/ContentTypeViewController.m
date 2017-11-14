//
//  ContentTypeViewController.m
//  CastEx
//
//  Created by Anirban on 10/15/17.
//  Copyright © 2017 Anirban Bhattacharya (Student). All rights reserved.
//

#import "ContentTypeViewController.h"
#import "CameraViewController.h"
#import "VideoViewController.h"
#import "FileViewController.h"
@interface ContentTypeViewController ()

@end

@implementation ContentTypeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSURL *videoURL = [[NSBundle mainBundle]URLForResource:@"waves" withExtension:@"mp4"];
    
    // create an AVPlayer
    AVPlayer *player = [AVPlayer playerWithURL:videoURL];
    player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[player currentItem]];
    AVPlayerLayer *videoLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    videoLayer.frame = self.view.bounds;
    videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:videoLayer];
    _overlayView.frame = self.view.bounds;
    [self.view addSubview:_overlayView];
    [player play];
}

-(void)playerItemDidReachEnd:(NSNotification *)notification
{
    AVPlayerItem *playerItem = [notification object];
    [playerItem seekToTime:kCMTimeZero completionHandler:nil];
}
- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)cameraButtonPressed:(id)sender {
    CameraViewController *v = [self.storyboard instantiateViewControllerWithIdentifier:@"CameraViewController"];
    [self.navigationController pushViewController:v animated:YES];
}
- (IBAction)fileButtonPressed:(id)sender {
    FileViewController *v = [self.storyboard instantiateViewControllerWithIdentifier:@"FileViewController"];
    v.isFile = true;
    [self.navigationController pushViewController:v animated:YES];
}
- (IBAction)videoButtonPressed:(id)sender {
    VideoViewController *v = [self.storyboard instantiateViewControllerWithIdentifier:@"VideoViewController"];
    [self.navigationController pushViewController:v animated:YES];
}

- (IBAction)websiteButtonPressed:(id)sender {
    FileViewController *v = [self.storyboard instantiateViewControllerWithIdentifier:@"FileViewController"];
    v.isFile = false;
    [self.navigationController pushViewController:v animated:YES];
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
