//==============================================================================
//
//  InfColorPickerController.m
//  InfColorPicker
//
//  Created by Troy Gaul on 7 Aug 2010.
//
//  Copyright (c) 2011-2013 InfinitApps LLC: http://infinitapps.com
//	Some rights reserved: http://opensource.org/licenses/MIT
//
//==============================================================================

#import "InfColorPickerController.h"

#import "InfColorBarPicker.h"
#import "InfColorSquarePicker.h"
#import "InfColorPickerNavigationController.h"
#import "InfHSBSupport.h"

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC enabled (-fobjc-arc).
#endif

static void HSVFromUIColor(UIColor* color, float* h, float* s, float* v)
{
	CGColorRef colorRef = [color CGColor];
	
	const CGFloat* components = CGColorGetComponents(colorRef);
	size_t numComponents = CGColorGetNumberOfComponents(colorRef);
	
	CGFloat r, g, b;
	
	if (numComponents < 3) {
		r = g = b = components[0];
	}
	else {
		r = components[0];
		g = components[1];
		b = components[2];
	}
	
	RGBToHSV(r, g, b, h, s, v, YES);
}

@interface InfColorPickerController ()

@property (nonatomic) IBOutlet InfColorBarView* barView;
@property (nonatomic) IBOutlet InfColorSquareView* squareView;
@property (nonatomic) IBOutlet InfColorBarPicker* barPicker;
@property (nonatomic) IBOutlet InfColorSquarePicker* squarePicker;
@property (nonatomic) IBOutlet UINavigationController* navController;

@end

@implementation InfColorPickerController {
    
	float _hue;
	float _saturation;
	float _brightness;
    float _red;
    float _green;
    float _blue;
}

@synthesize brush;
@synthesize brushControl;

+ (InfColorPickerController*) colorPickerViewController
{
	return [[self alloc] initWithNibName: @"InfColorPickerView" bundle: nil];
}

+ (CGSize) idealSizeForViewInPopover
{
	return CGSizeMake(256 + (1 + 20) * 2, 420);
}

- (id) initWithNibName: (NSString*) nibNameOrNil bundle: (NSBundle*) nibBundleOrNil
{
	self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];
	
	if (self) {
		self.navigationItem.title = NSLocalizedString(@"Set Color",
		                                              @"InfColorPicker default nav item title");
	}
	
	return self;
}

- (void) presentModallyOverViewController: (UIViewController*) controller
{
	UINavigationController* nav = [[InfColorPickerNavigationController alloc] initWithRootViewController: self];
	
	nav.navigationBar.barStyle = UIBarStyleDefault;// UIBarStyleBlackOpaque;
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
																						   target: self
																						   action: @selector(done:)];
	
	[controller presentViewController: nav animated: YES completion: nil];
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	
	_barPicker.value = _hue;
	_squareView.hue = _hue;
	_squarePicker.hue = _hue;
	_squarePicker.value = CGPointMake(_saturation, _brightness);
	

    brushControl.value = brush;
    
    [self sliderChanged:brushControl];
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
	return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (NSUInteger) supportedInterfaceOrientations
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationMaskAll;
	else
		return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIRectEdge) edgesForExtendedLayout
{
	return UIRectEdgeNone;
}

- (IBAction) takeBarValue: (InfColorBarPicker*) sender
{
	_hue = sender.value;
	
	_squareView.hue = _hue;
	_squarePicker.hue = _hue;
	
	[self updateResultColor];
}

- (IBAction) takeSquareValue: (InfColorSquarePicker*) sender
{
	_saturation = sender.value.x;
	_brightness = sender.value.y;
	
	[self updateResultColor];
}

- (IBAction) done: (id) sender
{
	[self.delegate colorPickerControllerDidFinish: self];
}

- (void) informDelegateDidChangeColor
{
	if (self.delegate && [(id) self.delegate respondsToSelector: @selector(colorPickerControllerDidChangeColor:)])
		[self.delegate colorPickerControllerDidChangeColor: self];
}

- (void) updateResultColor
{
	// This is used when code internally causes the update.  We do this so that
	// we don't cause push-back on the HSV values in case there are rounding
	// differences or anything.
	
	[self willChangeValueForKey: @"resultColor"];
	
	_resultColor = [UIColor colorWithHue: _hue
							  saturation: _saturation
							  brightness: _brightness
								   alpha: 1.0f];
    
    [self setRGB];
	
	[self didChangeValueForKey: @"resultColor"];
    
    [self updateBrushPreview];
	
	[self informDelegateDidChangeColor];
}

- (void) setResultColor: (UIColor*) newValue
{
	if (![_resultColor isEqual: newValue]) {
		_resultColor = newValue;
        
        [self setRGB];
		
		float h = _hue;
		HSVFromUIColor(newValue, &h, &_saturation, &_brightness);
		
		if ((h == 0.0 && _hue == 1.0) || (h == 1.0 && _hue == 0.0)) {
			// these are equivalent, so do nothing
		}
		else if (h != _hue) {
			_hue = h;
			
			_barPicker.value = _hue;
			_squareView.hue = _hue;
			_squarePicker.hue = _hue;
		}
		
		_squarePicker.value = CGPointMake(_saturation, _brightness);
		
		[self informDelegateDidChangeColor];
	}
}

- (void) setRGB {
    CGColorRef colorRef = [_resultColor CGColor];
    const CGFloat *_components = CGColorGetComponents(colorRef);
    _red     = _components[0];
    _green = _components[1];
    _blue   = _components[2];
}

- (void) setSourceColor: (UIColor*) newValue
{
	if (![_sourceColor isEqual: newValue]) {
		_sourceColor = newValue;
		
		self.resultColor = newValue;
	}
}

- (CGSize) contentSizeForViewInPopover
{
	return [[self class] idealSizeForViewInPopover];
}

- (IBAction)sliderChanged:(id)sender {
    UISlider * changedSlider = (UISlider*)sender;
    
    if(changedSlider == self.brushControl) {
        
        brush = brushControl.value;
        
        [self updateBrushPreview];
    }
}

- (void)updateBrushPreview {
    UIGraphicsBeginImageContext(self.brushPreview.frame.size);
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), self.brush);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.0, 0.0, 0.0, 1.0);
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(),45, 45);
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(),45, 45);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), _red, _green, _blue, 1.0);
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    self.brushPreview.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}
@end