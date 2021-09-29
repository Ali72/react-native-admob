#if __has_include(<React/RCTView.h>)
#import <React/RCTView.h>
#else
#import "RCTView.h"
#endif

@import GoogleMobileAds;

@class RCTEventDispatcher;

@interface RNDFPBannerView : RCTView <GADBannerViewDelegate, GADAdSizeDelegate, GADAppEventDelegate>

@property (nonatomic, copy) NSArray *validAdSizes;
@property (nonatomic, copy) NSArray *testDevices;

@property (nonatomic, copy) RCTDirectEventBlock onSizeChange;
@property (nonatomic, copy) RCTDirectEventBlock onAppEvent;
@property (nonatomic, copy) RCTDirectEventBlock onAdLoaded;
@property (nonatomic, copy) RCTDirectEventBlock onAdFailedToLoad;
@property (nonatomic, copy) RCTDirectEventBlock onAdOpened;
@property (nonatomic, copy) RCTDirectEventBlock onAdClosed;
@property (nonatomic, copy) RCTDirectEventBlock onAdLeftApplication;

- (void)loadBanner;

@end
