


#import "AVCamCaptureManager.h"

@interface DoCoCaptureToolsView : UIView

/**
 The instance of the SCRecorder to use.
 */
@property (strong, nonatomic) AVCamCaptureManager *manager;


/**
 The size of the focus target.
 */
@property (assign, nonatomic) CGSize focusTargetSize;

/**
 The minimum zoom allowed for the pinch to zoom.
 Default is 1
 */
@property (assign, nonatomic) CGFloat minZoomFactor;

/**
 The maximum zoom allowed for the pinch to zoom.
 Default is 4
 */
@property (assign, nonatomic) CGFloat maxZoomFactor;


/**
 Whether the tap to focus should be enabled.
 */
@property (assign, nonatomic) BOOL tapToFocusEnabled;

/**
 Whether the double tap to reset the focus should be enabled.
 */
@property (assign, nonatomic) BOOL doubleTapToResetFocusEnabled;

/**
 Whether the pinch to zoom should be enabled.
 */
@property (assign, nonatomic) BOOL pinchToZoomEnabled;

/**
 Whether the DoCoCaptureToolsView should show the focus animation automatically
 when the focusing state changes. If set to NO, you will have to call
 "showFocusAnimation" and "hideFocusAnimation" yourself.
 */
@property (assign, nonatomic) BOOL showsFocusAnimationAutomatically;


- (id)initWithFrame:(CGRect)frame manager:(AVCamCaptureManager *)manager focusImage:(UIImage *)focusImage;

@end
