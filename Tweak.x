#import <UIKit/UIKit.h>

@interface BrowserViewController : UIViewController
- (void)handleiPhoneSwipe:(id)swipe;
- (void)handleiPadSwipe:(id)swipe;
- (NSSet *)swipeRecognizers;
@property(retain, nonatomic) UIView *contentArea; 
- (void)toggleFullScreenMode:(BOOL)animated;
@end

@interface MainController : NSObject
- (id)activeTabModel;
@end

@interface Tab : NSObject
- (void)reload;
- (UIView *)view;
@property(readonly, nonatomic) BOOL canGoForward;
@property(readonly, nonatomic) BOOL canGoBack;
- (void)goForward;
- (void)goBack;
@end


@interface TabModel : NSObject
@property(assign, nonatomic) Tab *currentTab;
@end

/* This hack obviously supports only one argument */
#define CZSafeMethodCall(obj, selector, ...) ([obj respondsToSelector:NSSelectorFromString(@#selector)] ? [obj selector __VA_ARGS__] : 0)


%hook BrowserViewController
static BOOL isInFullScreen = NO;

- (void)handleiPadSwipe:(id)swipe
{
    CZSafeMethodCall(self, handleiPhoneSwipe:, swipe);
}

- (void)addHorizontalGestures
{
	%orig();
    NSSet *swipeSet = CZSafeMethodCall(self, swipeRecognizers);
	NSArray *swipeArray = [swipeSet allObjects];
    UIPanGestureRecognizer *sGesture = [swipeArray count] >= 1 ? [swipeArray objectAtIndex:0] : nil;
	UIView *gestView = sGesture.view;
	
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fingerTapped:)];
	tapRecognizer.numberOfTouchesRequired = 3;
    [gestView addGestureRecognizer:tapRecognizer];
    [tapRecognizer release];
	
    UISwipeGestureRecognizer *swipeRecognizerLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingerSwiped:)];
    swipeRecognizerLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [gestView addGestureRecognizer:swipeRecognizerLeft];
	swipeRecognizerLeft.numberOfTouchesRequired = 2;
    [swipeRecognizerLeft release];
	
    UISwipeGestureRecognizer *swipeRecognizerRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingerSwiped:)];
    swipeRecognizerRight.direction = UISwipeGestureRecognizerDirectionRight;
    [gestView addGestureRecognizer:swipeRecognizerRight];
	swipeRecognizerRight.numberOfTouchesRequired = 2;
    [swipeRecognizerRight release];
	
}

%new
- (void)twoFingerSwiped:(UISwipeGestureRecognizer *)sender
{
	if (sender.state == UIGestureRecognizerStateEnded)
	{
		MainController *smInstance = (MainController *)[UIApplication sharedApplication].delegate;
		TabModel *aTabModel = CZSafeMethodCall(smInstance, activeTabModel);
		Tab *cTab = (Tab *)CZSafeMethodCall(aTabModel, currentTab);
		if (sender.direction == UISwipeGestureRecognizerDirectionRight && CZSafeMethodCall(cTab, canGoBack))
			CZSafeMethodCall(cTab, goBack);
		else if (sender.direction == UISwipeGestureRecognizerDirectionLeft && CZSafeMethodCall(cTab, canGoForward))
			CZSafeMethodCall(cTab, goForward);
	}
}

%new
- (void)toggleFullScreenMode:(BOOL)animated
{
	CGRect browserFrame = self.view.frame;
	CGRect contentFrame = CZSafeMethodCall(self, contentArea).frame;
	UIApplication *sharedApp = [UIApplication sharedApplication];
	contentFrame.origin.y = contentFrame.origin.y + 20 + (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 0 : 1);
	UIInterfaceOrientation sOrientation = [sharedApp statusBarOrientation];
	if (sOrientation == UIInterfaceOrientationPortrait || sOrientation == UIInterfaceOrientationPortraitUpsideDown)
	{
		browserFrame.size.height = isInFullScreen ? browserFrame.size.height - contentFrame.origin.y : browserFrame.size.height + contentFrame.origin.y;
		if (sOrientation == UIInterfaceOrientationPortrait)
			browserFrame.origin.y = isInFullScreen ? browserFrame.origin.y + contentFrame.origin.y : browserFrame.origin.y - contentFrame.origin.y;
	}
	else if (sOrientation == UIInterfaceOrientationLandscapeLeft || sOrientation == UIInterfaceOrientationLandscapeRight)
	{
		browserFrame.size.width = isInFullScreen ? browserFrame.size.width - contentFrame.origin.y : browserFrame.size.width + contentFrame.origin.y;
		if (sOrientation == UIInterfaceOrientationLandscapeLeft)
			browserFrame.origin.x = isInFullScreen ? browserFrame.origin.x + contentFrame.origin.y : browserFrame.origin.x - contentFrame.origin.y;
	}
	if (animated)
	{
		[UIView animateWithDuration:0.6
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseInOut
						 animations:^{
							 self.view.frame = browserFrame;
						 }
						 completion:nil
		 ];
	}
	else
		self.view.frame = browserFrame;
	isInFullScreen = !isInFullScreen;
	if (animated)
		[sharedApp setStatusBarHidden:isInFullScreen withAnimation:UIStatusBarAnimationSlide];
	else
		[sharedApp setStatusBarHidden:isInFullScreen withAnimation:UIStatusBarAnimationNone];
}

%new
- (void)fingerTapped:(UITapGestureRecognizer *)sender
{
	if (sender.state == UIGestureRecognizerStateEnded)
	{
		[self toggleFullScreenMode:YES];
	}
}
- (void)willRotateToInterfaceOrientation:(int)arg1 duration:(double)arg2
{
	UIApplication *sharedApp = [UIApplication sharedApplication];
	[sharedApp setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
	%orig();
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	%orig();
	BOOL wasInFullScreen = isInFullScreen;
	isInFullScreen = NO;
	if (wasInFullScreen)
		[self toggleFullScreenMode:NO];
}
%end
