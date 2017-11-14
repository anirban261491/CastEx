//
//  OverLayViewController.m
//  CastEx
//
//  Created by Anirban on 10/15/17.
//  Copyright © 2017 Anirban Bhattacharya (Student). All rights reserved.
//

#import "OverLayViewController.h"

@interface OverLayViewController ()
{
    BOOL isBroadcasting;
}
@end

@implementation OverLayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)startStopBroadcasting {
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
