//
//  NOMTSwitchButtonCell.m
//  NOMenuTimer
//
//  Created by Yuriy Panfyorov on 25/03/14.
//  Copyright (c) 2014 Yuriy Panfyorov. All rights reserved.
//

#import "NOSwitchButtonCell.h"

#import "NOSwitchButton.h"

// used to make space for the nice shadow (height only)
#define SHADOW_INSET 4.
// used to make space for the nice stroke (width only)
#define STROKE_INSET 2.
// used to make the thumb smaller than the outer line
#define THUMB_INSET 1.

#define THUMB_SHADOW_WHITE 0.
#define THUMB_SHADOW_ALPHA .25
#define THUMB_SHADOW_BLUR 3.

// used to find out if mouse has been moved far enough to consider it dragging
#define DRAGGING_DISTANCE_THRESHOLD 4.
#define CLICK_TIME_DELAY_THRESHOLD .5

#define BACKGROUND_TRANSITION_VELOCITY .05
#define THUMB_ANIMATION_VELOCITY .05

NS_ENUM(NSInteger, NOMTSwitchBackgroundState) {
    NOMTSwitchBackgroundStateNone = -1,
    NOMTSwitchBackgroundStateOff = 0,
    NOMTSwitchBackgroundStateOffPressed = 1,
    NOMTSwitchBackgroundStateOn
};

static NSImage *image;

static inline CGFloat easingFunctionIn(CGFloat t) {
    CGFloat overshoot = 1.70158;
	t = t - 1;
	return t * t * ((overshoot + 1) * t + overshoot) + 1;
}

static inline CGFloat easingFunctionOut(CGFloat t) {
    CGFloat overshoot = 1.70158;
	return t * t * ((overshoot + 1) * t - overshoot);
}

float clampf(float value, float min_inclusive, float max_inclusive)
{
	if (min_inclusive > max_inclusive) {
        float temp = min_inclusive;
        min_inclusive = max_inclusive;
        max_inclusive = temp;
	}
	return value < min_inclusive ? min_inclusive : value < max_inclusive? value : max_inclusive;
}

//
// when pressed on the left
// always shrink white background, display gray, expand thumb
//
// when pressed on the right
// expand thumb
//
// when released immediately
// move thumb, change background color to green or gray
// if new state is off, expand white background
//
// while moving
// set background color to blended color of green and gray
//


@interface NOSwitchButtonCell () {
    BOOL _isTracking;
    BOOL _hasMovedEnough;

    NSDate *_initialTrackingTime;
    NSPoint _initialTrackingPoint;
    
    NSPoint _trackingPoint;
    CGFloat _trackingThumbCenterX;
    CGFloat _currentThumbOriginXRatio;
    NSRect _trackingCellFrame;
    NSCellStateValue _trackingState;
    
    CGFloat _trackingRatio;
    
    NSInteger _backgroundState;
    BOOL _isBackgroundInTransition;
    NSTimer *_backgroundTransitionTimer;
    CGFloat _backgroundCurrentState;
    CGFloat _backgroundTargetState;
    
    BOOL _isThumbAnimating;
    NSTimer *_thumbAnimationTimer;
    CGFloat _thumbAnimationInitialOriginX;
    CGFloat _thumbAnimationCurrentState;
    CGFloat _thumbAnimationTargetState;
}

@end

@implementation NOSwitchButtonCell

+ (void)initialize {
    image = [NSImage imageNamed:@"Switch"];
}

+ (BOOL)prefersTrackingUntilMouseUp
{
	return YES;
}

+ (NSFocusRingType)defaultFocusRingType
{
	return NSFocusRingTypeNone;
}

#pragma mark - initializers

- (id)init {
    self = [super init];
    if (self) {
        [self initializeIvars];
    }
    return self;
}

- (id)initImageCell:(NSImage *)image {
    self = [super initImageCell:image];
    if (self) {
        [self initializeIvars];
    }
    return self;
}

- (id)initTextCell:(NSString *)aString {
    self = [super initTextCell:aString];
    if (self) {
        [self initializeIvars];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initializeIvars];
    }
    return self;
}

- (BOOL)allowsMixedState {
    return NO;
}

- (void)setAllowsMixedState:(BOOL)flag {
    if (flag) {
        NSLog(@"NOMTSwitchButtonCell does not support mixed state.");
    }
    [super setAllowsMixedState:NO];
}

- (void)initializeIvars {
    _isBackgroundInTransition = NO;
    _backgroundState = NOMTSwitchBackgroundStateNone;
    _isThumbAnimating = NO;
}

- (void)awakeFromNib {
    if (self.controlView && [self.controlView isKindOfClass:[NOSwitchButton class]]) {
        self.tintColor = [(NOSwitchButton *)self.controlView tintColor];
    } else {
        self.tintColor = [NSColor colorWithCalibratedRed:76./255. green:217./255. blue:100./255. alpha:1.];
    }
    
    [self setBackgroundStateForCellState:self.state];
}

- (void)setBackgroundStateForCellState:(NSCellStateValue)cellState {
    switch (cellState) {
        case NSOnState:
            _backgroundState = NOMTSwitchBackgroundStateOn;
            break;
            
        default:
            _backgroundState = NOMTSwitchBackgroundStateOff;
            break;
    }
}

#pragma mark - Drawing

- (NSRect)thumbRectInCellFrame:(NSRect)cellFrame {
    CGFloat height = cellFrame.size.height;
    
    CGFloat radius = height * .5 - SHADOW_INSET;
    
    CGFloat thumbRadius = radius - THUMB_INSET;
    
    NSRect thumbRect = NSMakeRect(STROKE_INSET + THUMB_INSET, SHADOW_INSET + THUMB_INSET, thumbRadius * 2 + (_isTracking ? 4 : 0), thumbRadius * 2);
    
    NSCellStateValue state = [self state];
	switch (state) {
		case NSOnState:
            thumbRect.origin.x = cellFrame.origin.x + cellFrame.size.width - thumbRect.size.width - STROKE_INSET - THUMB_INSET;
            break;
        case NSOffState:
            break;
    }
    
    return thumbRect;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    
    [self drawInteriorWithFrame:cellFrame inView:controlView];
    
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    // because calculations are intertwined all the drawing happens in drawWithFrame:inView:
    
    if (_isTracking) {
        _trackingCellFrame = cellFrame;
    }
    
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
	[context saveGraphicsState];
    
    CGFloat height = cellFrame.size.height;
    CGFloat width = cellFrame.size.width;
    
    CGFloat radius = height * .5 - SHADOW_INSET;
    
    NSRect thumbRect = [self thumbRectInCellFrame:cellFrame];
    
    CGFloat thumbMinOriginX = cellFrame.origin.x + STROKE_INSET + THUMB_INSET;
    CGFloat thumbMaxOriginX = cellFrame.origin.x + (cellFrame.size.width - thumbRect.size.width - STROKE_INSET - THUMB_INSET);
    
    CGFloat thumbRadius = cellFrame.size.height * .5 - SHADOW_INSET - THUMB_INSET;
    CGFloat thumbOriginX = 0.;
    
    // background drawing
    
    NSBezierPath *background = [NSBezierPath bezierPath];
    [background moveToPoint:NSMakePoint(radius + STROKE_INSET, SHADOW_INSET)];
    [background appendBezierPathWithArcWithCenter:NSMakePoint(radius + STROKE_INSET,
                                                              radius + SHADOW_INSET)
                                           radius:radius
                                       startAngle:270
                                         endAngle:90
                                        clockwise:YES];
    [background lineToPoint:NSMakePoint(width - radius - STROKE_INSET, height - SHADOW_INSET)];
    [background appendBezierPathWithArcWithCenter:NSMakePoint(width - radius - STROKE_INSET,
                                                              radius + SHADOW_INSET)
                                           radius:radius
                                       startAngle:90
                                         endAngle:-90
                                        clockwise:YES];
    [background lineToPoint:NSMakePoint(radius + STROKE_INSET, SHADOW_INSET)];
    
    NSBezierPath *strokePath = [NSBezierPath bezierPath];
    [strokePath appendBezierPath:background];
    
    NSColor *fillColor;
    NSColor *strokeColor;
    
    if (_isTracking || _isBackgroundInTransition) {
        // need to blend background from grey to green
        // so we have to calculate the current thumb position and its ratio
        
        if (_isTracking) {
            thumbRect.origin.x += _trackingPoint.x - _initialTrackingPoint.x;
        }
        
        if (_isThumbAnimating) {
            CGFloat easedAnimationState = (_thumbAnimationTargetState == 0 ? easingFunctionOut(_thumbAnimationCurrentState) : easingFunctionIn(_thumbAnimationCurrentState));
            thumbRect.origin.x = thumbMinOriginX + easedAnimationState * (thumbMaxOriginX - thumbMinOriginX);
        } else {
            thumbRect.origin.x = clampf(thumbRect.origin.x, thumbMinOriginX, thumbMaxOriginX);
        }
        
        _trackingThumbCenterX = NSMidX(thumbRect);
        
        CGFloat thumbRatio = (thumbRect.origin.x - thumbMinOriginX) / (thumbMaxOriginX - thumbMinOriginX);
        
        // blend based on the current thumb position within bounds
        fillColor = [self backgroundColorForRatio: thumbRatio];
        strokeColor = [self strokeColorForRatio: thumbRatio];
        
        // pass this value further down the road
        thumbOriginX = thumbRect.origin.x;
    } else {
        if (self.isEnabled) {
            switch ([self state]) {
                case NSOnState:
                    fillColor = self.tintColor;
                    strokeColor = self.tintColor;
                    break;
                case NSOffState:
                    fillColor = [NSColor colorWithCalibratedRed:1. green:1. blue:1. alpha:0.];
                    strokeColor = [NSColor colorWithCalibratedRed:0.8 green:0.8 blue:0.8 alpha:1];
                    break;
            }
        } else {
            fillColor = [self disabledBackgroundColorForState:self.state];
            strokeColor = [self disabledStrokeColorForState:self.state];
        }
    }
    
    if (_isBackgroundInTransition) {
        [context saveGraphicsState];
        
        CGFloat extraInset = radius * _backgroundCurrentState;
        radius -= extraInset;
        
        [background setWindingRule:NSEvenOddWindingRule];
        
        NSBezierPath *holePath = [NSBezierPath bezierPath];
        
        [holePath moveToPoint:NSMakePoint(thumbOriginX + radius, SHADOW_INSET + extraInset)];
        [holePath lineToPoint:NSMakePoint(thumbOriginX + radius, height - SHADOW_INSET - extraInset)];
        [holePath lineToPoint:NSMakePoint(width - radius - STROKE_INSET - extraInset, height - SHADOW_INSET - extraInset)];
        [holePath appendBezierPathWithArcWithCenter:NSMakePoint(width - radius - STROKE_INSET - extraInset,
                                                                radius + SHADOW_INSET + extraInset)
                                             radius:radius
                                         startAngle:90
                                           endAngle:-90
                                          clockwise:YES];
        [holePath lineToPoint:NSMakePoint(thumbOriginX + radius, SHADOW_INSET + extraInset)];
        
        [background appendBezierPath:holePath];
        
    }
    
    [fillColor setFill];
    [background fill];
    
    if (_isBackgroundInTransition) {
        [context restoreGraphicsState];
    }
    
    [strokeColor setStroke];
    [strokePath setLineWidth:2.];
    [strokePath stroke];
    
    //
    // thumb drawing
    //
    
    if (_isThumbAnimating) {
        CGFloat easedAnimationState = (_thumbAnimationTargetState == 0 ? easingFunctionOut(_thumbAnimationCurrentState) : easingFunctionIn(_thumbAnimationCurrentState));
        thumbRect.origin.x = thumbMinOriginX + easedAnimationState * (thumbMaxOriginX - thumbMinOriginX);
    }
    
    _currentThumbOriginXRatio = (thumbRect.origin.x - thumbMinOriginX) / (thumbMaxOriginX - thumbMinOriginX);
    
    NSBezierPath *thumb = [NSBezierPath bezierPathWithRoundedRect:thumbRect xRadius:thumbRadius yRadius:thumbRadius];
    
    CGContextRef cgContext = [context graphicsPort];
    CGSize shadowSize = {0., -2.};
    NSColor *shadowColor = self.isEnabled ? [NSColor colorWithWhite:0 alpha:1./3.] : [NSColor colorWithWhite:0. alpha:1./6.];
    CGContextSetShadowWithColor(cgContext, shadowSize, THUMB_SHADOW_BLUR, shadowColor.CGColor);
    CGContextBeginTransparencyLayer(cgContext, NULL);
    
    [[NSColor whiteColor] setFill];
    [thumb fill];
    
    [[NSColor colorWithCalibratedRed:0.8 green:0.8 blue:0.8 alpha:.5] setStroke];;
    [thumb setLineWidth:.5];
    [thumb stroke];
    
    CGContextEndTransparencyLayer(cgContext);
    
    [context restoreGraphicsState];
    
}

- (NSColor *)disabledBackgroundColorForState:(NSCellStateValue)state {
    switch (state) {
        case NSOnState:
            return [self.tintColor highlightWithLevel:.5];
        case NSOffState:
            return [NSColor colorWithCalibratedWhite:1. alpha:1];
        default:
            break;
    }
    return self.tintColor;
}

- (NSColor *)disabledStrokeColorForState:(NSCellStateValue)state {
    switch (state) {
        case NSOnState:
            return [self disabledBackgroundColorForState:state];
        case NSOffState:
            return [[NSColor colorWithCalibratedWhite:.8 alpha:1] highlightWithLevel:.5];
        default:
            break;
    }
    return self.tintColor;
}

- (NSColor *)backgroundColorForRatio:(CGFloat)ratio {
    return [[NSColor colorWithCalibratedRed:0.8 green:0.8 blue:0.8 alpha:1] blendedColorWithFraction:ratio ofColor:self.tintColor];
}

- (NSColor *)strokeColorForRatio:(CGFloat)ratio {
    return [[NSColor colorWithCalibratedRed:0.8 green:0.8 blue:0.8 alpha:1] blendedColorWithFraction:ratio ofColor:self.tintColor];
}

#pragma mark - Tracking

- (NSUInteger)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView
{
	NSPoint mouseLocation = [controlView convertPoint:[event locationInWindow] fromView:nil];
	return NSPointInRect(mouseLocation, cellFrame) ? (NSCellHitContentArea | NSCellHitTrackableArea) : NSCellHitNone;
}

- (BOOL) startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView
{
    if (_isThumbAnimating)
        return NO;
    
	_isTracking = YES;
    _hasMovedEnough = NO;
    _trackingState = self.state;
	_trackingPoint = _initialTrackingPoint = startPoint;
    
    _initialTrackingTime = [NSDate date];
    
    // check if
    if (_backgroundState == NOMTSwitchBackgroundStateOff) {
        // begin transition
       [self beginBackgroundTransitionTo:NOMTSwitchBackgroundStateOffPressed];
    }
    
    [[self controlView] setNeedsDisplay:YES];
    
	return [controlView isKindOfClass:[NSControl class]];
}

- (BOOL) continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView
{
	NSControl *control = [controlView isKindOfClass:[NSControl class]] ? (NSControl *)controlView : nil;
	if (control) {
		_trackingPoint = currentPoint;
		[control drawCell:self];
        
        CGFloat distance = (_trackingPoint.x - _initialTrackingPoint.x) * (_trackingPoint.x - _initialTrackingPoint.x) + (_trackingPoint.y - _initialTrackingPoint.y) * (_trackingPoint.y - _initialTrackingPoint.y);
        if (distance > DRAGGING_DISTANCE_THRESHOLD)
            _hasMovedEnough = YES;

        CGFloat xRatio = _trackingThumbCenterX / _trackingCellFrame.size.width;
            
        NSCellStateValue desiredState;
        
        if (xRatio < .5)
            desiredState = NSOffState;
        else
            desiredState = NSOnState;
        
        if (desiredState != _trackingState) {
            
            _trackingState = desiredState;
        }

		return YES;
	}
	_isTracking = NO;
	return NO;
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag
{
	_isTracking = NO;
    
	NSControl *control = [controlView isKindOfClass:[NSControl class]] ? (NSControl *)controlView : nil;
	if (control) {
        
        NSCellStateValue desiredState;
        
        // has to set the state to the previous to the expected state
        // because it loops internally afterwards
        if (_hasMovedEnough || [[NSDate date] timeIntervalSinceDate:_initialTrackingTime] > CLICK_TIME_DELAY_THRESHOLD) {
            // probably the thumb has been dragged so calculate the desired position
            CGFloat xRatio = _trackingThumbCenterX / _trackingCellFrame.size.width;
            
            if (xRatio < .5)
                desiredState = NSOffState;
            else
                desiredState = NSOnState;
            
        } else {
            // if clicked in place, just toggle state
            desiredState = 1 - self.state;
        }

        if (desiredState == NSOffState) {
            _backgroundState = NOMTSwitchBackgroundStateOffPressed;
            [self beginBackgroundTransitionTo:NOMTSwitchBackgroundStateOff];
        }

        [self setState:1 - desiredState];
        [self setBackgroundStateForCellState:desiredState];
        
        // animate thumb
        [self beginThumbTransitionTo:desiredState];
	}
}

#pragma mark - Background transitions

- (void)beginBackgroundTransitionTo:(NSInteger)backgroundState {
    
    if (_isBackgroundInTransition)
        return;
    
    // check
    if(_backgroundTransitionTimer) {
        [_backgroundTransitionTimer invalidate];
        _backgroundTransitionTimer = nil;
    }
    
    _backgroundTransitionTimer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(updateBackgroundTransition:) userInfo:nil repeats:YES];
    _backgroundTransitionTimer.tolerance = .01;
    [[NSRunLoop currentRunLoop] addTimer:_backgroundTransitionTimer forMode:NSRunLoopCommonModes];
    
    _isBackgroundInTransition = YES;
    _backgroundCurrentState = _backgroundState;
    _backgroundTargetState = backgroundState;
}

- (void)completeBackgroundTransition {
    // check
    if(_backgroundTransitionTimer) {
        // cancel and revert
        [_backgroundTransitionTimer invalidate];
        _backgroundTransitionTimer = nil;
    }
    
    _isBackgroundInTransition = NO;
}

- (void)updateBackgroundTransition:(NSTimer*)timer {
    CGFloat dt = BACKGROUND_TRANSITION_VELOCITY;
    if (_backgroundTargetState - _backgroundCurrentState < 0) {
        dt = - BACKGROUND_TRANSITION_VELOCITY;
    }
    _backgroundCurrentState += dt;
    
    BOOL shouldCompleteBackgroundTransition = NO;
    if (dt > 0.) {
        if (_backgroundCurrentState >= _backgroundTargetState) {
            shouldCompleteBackgroundTransition = YES;
        }
    } else if (dt < 0.) {
        if (_backgroundCurrentState <= _backgroundTargetState) {
            shouldCompleteBackgroundTransition = YES;
        }
    }
    
    if (shouldCompleteBackgroundTransition) {
        _backgroundCurrentState = _backgroundTargetState;
        
        _backgroundState = _backgroundTargetState;
        
        [self completeBackgroundTransition];
    }

    // not very nice but whatchagonnado
    [self.controlView setNeedsDisplay:YES];
}

#pragma mark - Thumb animation

- (void)beginThumbTransitionTo:(NSInteger)thumbState {
    if (_isThumbAnimating)
        return;
    
    if (_thumbAnimationTimer) {
        [_backgroundTransitionTimer invalidate];
        _backgroundTransitionTimer = nil;
    }
    
    _thumbAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(updateThumbTransition:) userInfo:nil repeats:YES];
    _thumbAnimationTimer.tolerance = .01;
    [[NSRunLoop currentRunLoop] addTimer:_thumbAnimationTimer forMode:NSRunLoopCommonModes];
    
    _isThumbAnimating = YES;
    
    _thumbAnimationCurrentState = _currentThumbOriginXRatio;
    _thumbAnimationTargetState = thumbState;
}

- (void)completeThumbTransition {
    // check
    if(_thumbAnimationTimer) {
        // cancel and revert
        [_thumbAnimationTimer invalidate];
        _thumbAnimationTimer = nil;
    }
    
    _isThumbAnimating = NO;
}

- (void)updateThumbTransition:(NSTimer *)timer {
    CGFloat dt = THUMB_ANIMATION_VELOCITY;
    if (_thumbAnimationTargetState - _thumbAnimationCurrentState < 0) {
        dt = - THUMB_ANIMATION_VELOCITY;
    }
    _thumbAnimationCurrentState += dt;
    
    BOOL shouldCompleteBackgroundTransition = NO;
    if (dt > 0.) {
        if (_thumbAnimationCurrentState >= _thumbAnimationTargetState) {
            shouldCompleteBackgroundTransition = YES;
        }
    } else if (dt < 0.) {
        if (_thumbAnimationCurrentState <= _thumbAnimationTargetState) {
            shouldCompleteBackgroundTransition = YES;
        }
    }
    
    if (shouldCompleteBackgroundTransition) {
        _thumbAnimationCurrentState = _thumbAnimationTargetState;
        
        [self completeThumbTransition];
    }
    
    // not very nice but whatchagonnado
    [self.controlView setNeedsDisplay:YES];
}

@end
