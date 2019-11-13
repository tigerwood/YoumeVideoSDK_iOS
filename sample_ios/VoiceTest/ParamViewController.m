//
//  SecondViewController.m
//  UITest2Bar
//
//  Created by pinky on 2017/9/28.
//  Copyright © 2017年 youme. All rights reserved.
//

#import "ParamViewController.h"
#import "YMVoiceService.h"
#import "ViewController.h"

@interface ParamViewController ()

@end

@implementation ParamViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
//    @property (retain, nonatomic) IBOutlet UITextField *tf_width;
//    @property (retain, nonatomic) IBOutlet UITextField *tf_height;
//    @property (retain, nonatomic) IBOutlet UITextField *tf_interval;
//    @property (retain, nonatomic) IBOutlet UITextField *tf_bitrate;
//    
//    @property (retain, nonatomic) IBOutlet UISwitch *tf_open_hw;
//    @property (retain, nonatomic) IBOutlet UISwitch *tf_high_audio;
    
    _tf_width.text = [NSString stringWithFormat:@"%d", params->videoWidth];
    _tf_height.text = [NSString stringWithFormat:@"%d", params->videoHeight];

    _tf_interval.text = [NSString stringWithFormat:@"%d", params->reportInterval];
    _tf_maxBitrate.text = [NSString stringWithFormat:@"%d", params->maxBitrate];
    _tf_minBitrate.text = [NSString stringWithFormat:@"%d", params->minBitrate];
    _tf_farendLevel.text = [NSString stringWithFormat:@"%d", params->farendLevel];
    _tf_video_fps.text = [NSString stringWithFormat:@"%d", params->fps];
    
    _tf_open_hw.on = params->bHWEnable;
    _tf_high_audio.on = params->bHighAudio;
    _push_stream.on = params->push;
    _fix_quality.on = params->fixQuality;
    
//    if( bInited )
//    {
//        _tf_width.enabled = false ;
//        _tf_height.enabled = false ;
//
//        _tf_open_hw.enabled = false ;
//        _tf_high_audio.enabled = false ;
//    }
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleClickTap:)]];
    
}

-(void)handleClickTap:(UITapGestureRecognizer*)gest {
    [self.view endEditing:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onClickFinish:(id)sender
{
    //if( !bInited )
    {
        params->videoWidth = _tf_width.text.intValue;
        params->videoHeight = _tf_height.text.intValue;
        params->reportInterval = _tf_interval.text.intValue;
        params->maxBitrate = _tf_maxBitrate.text.intValue;
        params->minBitrate = _tf_minBitrate.text.intValue;
        params->farendLevel = _tf_farendLevel.text.intValue;
        params->fps = _tf_video_fps.text.intValue;
        
        params->bHWEnable = _tf_open_hw.on;
        params->bHighAudio = _tf_high_audio.on;
        params->push = _push_stream.on;
        params->fixQuality = _fix_quality.on;
    }
    
    [self dismissViewControllerAnimated: TRUE completion:nil];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}

@end
