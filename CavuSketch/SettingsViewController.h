//
//  SettingsViewController.h
//  CavuSketch
//
//  Created by Ryan Tremaine on 1/17/14.
//  Copyright (c) 2014 Cavu Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController
- (IBAction)closeSettings:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *brushControl;
@property (weak, nonatomic) IBOutlet UIImageView *brushPreview;
@property (weak, nonatomic) IBOutlet UISlider *brushValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *opacityControl;
@property (weak, nonatomic) IBOutlet UIImageView *opacityPreview;
@property (weak, nonatomic) IBOutlet UISlider *opacityValueLabel;
- (IBAction)sliderChanged:(id)sender;

@end
