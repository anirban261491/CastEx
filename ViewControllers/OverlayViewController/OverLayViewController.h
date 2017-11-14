//
//  OverLayViewController.h
//  CastEx
//
//  Created by Anirban on 10/15/17.
//  Copyright © 2017 Anirban Bhattacharya (Student). All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OverLayViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *recordStartStopButtonImageView;
- (void)startStopBroadcasting;
@end
