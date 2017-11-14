//
//  IntroViewController.m
//  CastEx
//
//  Created by Anirban Bhattacharya (Student) on 10/12/17.
//  Copyright © 2017 Anirban Bhattacharya (Student). All rights reserved.
//

#import "IntroViewController.h"
#import "StreamViewController.h"
#import "ContentTypeViewController.h"
@interface IntroViewController ()

@end

@implementation IntroViewController

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


- (IBAction)watchButtonPressed:(id)sender {
    StreamViewController *v = [self.storyboard instantiateViewControllerWithIdentifier:@"StreamViewController"];
    [self.navigationController pushViewController:v animated:YES];
}
- (IBAction)streamContentButtonPressed:(id)sender {
    ContentTypeViewController *v = [self.storyboard instantiateViewControllerWithIdentifier:@"ContentTypeViewController"];
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
