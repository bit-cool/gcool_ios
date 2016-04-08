//
//  DoCoCaptureToolsView.m
//  SCRecorder
//
//  Created by Simon CORSIN on 16/02/15.
//  Copyright (c) 2015 rFlex. All rights reserved.
//

#import "DoCoCaptureToolsView.h"

#define BASE_FOCUS_TARGET_WIDTH 60
#define BASE_FOCUS_TARGET_HEIGHT 60
#define kDefaultMinZoomFactor 1
#define kDefaultMaxZoomFactor 4

@interface DoCoCaptureToolsView()
{
    CGPoint _currentFocusPoint;
    UITapGestureRecognizer *_tapToFocusGesture;
    UITapGestureRecognizer *_doubleTapToResetFocusGesture;
    UIPinchGestureRecognizer *_pinchZoomGesture;
    CGFloat _zoomAtStart;
    UIImageView *focusRectView;
}

@end

@implementation DoCoCaptureToolsView

- (id)initWithFrame:(CGRect)frame manager:(AVCamCaptureManager *)manager focusImage:(UIImage *)focusImage{
    self = [super initWithFrame:frame];
    
    if (self) {
        if (focusImage) {
            [self initFocusRectViewWithImage:focusImage];
        }
        _manager = manager;
        [self commonInit];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

-(void)initFocusRectViewWithImage:(UIImage *)image{
    focusRectView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 90, 90)];
    focusRectView.image = image;
    focusRectView.alpha = 0;
    [self addSubview:focusRectView];
}

- (void)dealloc {
    self.manager = nil;
}

- (void)commonInit {
    _minZoomFactor = kDefaultMinZoomFactor;
    _maxZoomFactor = kDefaultMaxZoomFactor;
    self.showsFocusAnimationAutomatically = YES;
    _currentFocusPoint = CGPointMake(0.5, 0.5);
    
    self.focusTargetSize = CGSizeMake(BASE_FOCUS_TARGET_WIDTH, BASE_FOCUS_TARGET_HEIGHT);
    
    _tapToFocusGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToAutoFocus:)];
    [self addGestureRecognizer:_tapToFocusGesture];
    
    _doubleTapToResetFocusGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToContinouslyAutoFocus:)];
    _doubleTapToResetFocusGesture.numberOfTapsRequired = 2;
    [_tapToFocusGesture requireGestureRecognizerToFail:_doubleTapToResetFocusGesture];
    
    [self addGestureRecognizer:_doubleTapToResetFocusGesture];
    
    _pinchZoomGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchToZoom:)];
    
    [self addGestureRecognizer:_pinchZoomGesture];
}


- (void)layoutSubviews {
    [super layoutSubviews];
}



// Auto focus at a particular point. The focus mode will change to locked once the auto focus happens.
- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer {
    if ([_manager.captureVideoInput.device isFocusPointOfInterestSupported]) {
        CGPoint tapPoint = [gestureRecognizer locationInView:self];
        [self showFocusRectAtPoint:tapPoint];
        CGPoint convertedFocusPoint = [self convertToPointOfInterestFromViewCoordinates:tapPoint];
        [_manager autoFocusAtPoint:convertedFocusPoint];
    }
}

// Change to continuous auto focus. The camera will constantly focus at the point choosen.
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer {
    if ([[[_manager captureVideoInput] device] isFocusPointOfInterestSupported])
        [_manager continuousFocusAtPoint:CGPointMake(.5f, .5f)];
    
}

- (void)pinchToZoom:(UIPinchGestureRecognizer *)gestureRecognizer {
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        _zoomAtStart = _manager.captureVideoInput.device.videoZoomFactor;
    }
    
    CGFloat newZoom = gestureRecognizer.scale * _zoomAtStart;
    
    if (newZoom > _maxZoomFactor) {
        newZoom = _maxZoomFactor;
    } else if (newZoom < _minZoomFactor) {
        newZoom = _minZoomFactor;
    }
        
    [_manager changeZoomFactor:newZoom];
}


- (BOOL)tapToFocusEnabled {
    return _tapToFocusGesture.enabled;
}

- (void)setTapToFocusEnabled:(BOOL)tapToFocusEnabled {
    _tapToFocusGesture.enabled = tapToFocusEnabled;
}

- (BOOL)doubleTapToResetFocusEnabled {
    return _doubleTapToResetFocusGesture.enabled;
}

- (void)setDoubleTapToResetFocusEnabled:(BOOL)doubleTapToResetFocusEnabled {
    _doubleTapToResetFocusGesture.enabled = doubleTapToResetFocusEnabled;
}

- (BOOL)pinchToZoomEnabled {
    return _pinchZoomGesture.enabled;
}

- (void)setPinchToZoomEnabled:(BOOL)pinchToZoomEnabled {
    _pinchZoomGesture.enabled = pinchToZoomEnabled;
}


- (void)showFocusRectAtPoint:(CGPoint)point
{
    focusRectView.alpha = 1.0f;
    focusRectView.center = point;
    focusRectView.transform = CGAffineTransformMakeScale(1.5f, 1.5f);
    [UIView animateWithDuration:0.2f animations:^{
        focusRectView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    } completion:^(BOOL finished) {
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
        animation.values = @[@0.5f, @1.0f, @0.5f, @1.0f, @0.5f, @1.0f];
        animation.duration = 0.5f;
        [focusRectView.layer addAnimation:animation forKey:@"opacity"];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3f animations:^{
                focusRectView.alpha = 0;
            }];
        });
    }];
    //    focusRectView.transform = CGAffineTransformMakeScale(1.5f, 1.5f);
    //    focusRectView.center = point;
    //    [UIView animateWithDuration:0.3f animations:^{
    //        focusRectView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    //        focusRectView.alpha = 1.0f;
    //    } completion:^(BOOL finished) {
    //        [UIView animateWithDuration:0.1f animations:^{
    //            focusRectView.alpha = 0.0f;
    //        }];
    //    }];
}


//将UI坐标转换为摄像机坐标，用于点击聚焦的坐标转换
// Convert from view coordinates to camera coordinates, where {0,0} represents the top left of the picture area, and {1,1} represents
// the bottom right in landscape mode with the home button on the right.
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates
{
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = [self  frame].size;
    
    if ([_manager.previewLayer.connection isVideoMirroringSupported]) {
        viewCoordinates.x = frameSize.width - viewCoordinates.x;
    }
    
    if ( [[_manager.previewLayer videoGravity] isEqualToString:AVLayerVideoGravityResize] ) {
        // Scale, switch x and y, and reverse x
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for (AVCaptureInputPort *port in self.manager.captureVideoInput.ports) {
            if ([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                
                if ( [[_manager.previewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspect] ) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
                        // If point is inside letterboxed area, do coordinate conversion; otherwise, don't change the default value returned (.5,.5)
                        if (point.x >= blackBar && point.x <= blackBar + x2) {
                            // Scale (accounting for the letterboxing on the left and right of the video preview), switch x and y, and reverse x
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
                        // If point is inside letterboxed area, do coordinate conversion. Otherwise, don't change the default value returned (.5,.5)
                        if (point.y >= blackBar && point.y <= blackBar + y2) {
                            // Scale (accounting for the letterboxing on the top and bottom of the video preview), switch x and y, and reverse x
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if ([[_manager.previewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
                    // Scale, switch x and y, and reverse x
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2; // Account for cropped height
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2); // Account for cropped width
                        xc = point.y / frameSize.height;
                    }
                }
                
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    
    return pointOfInterest;
}
@end
