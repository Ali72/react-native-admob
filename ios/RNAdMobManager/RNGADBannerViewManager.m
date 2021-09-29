#import "RNGADBannerViewManager.h"
#import "RNGADBannerView.h"
#import "RCTConvert+GADAdSize.h"

#if __has_include(<React/RCTBridge.h>)
#import <React/RCTBridge.h>
#import <React/RCTUIManager.h>
#import <React/RCTEventDispatcher.h>
#else
#import "RCTBridge.h"
#import "RCTUIManager.h"
#import "RCTEventDispatcher.h"
#endif

@implementation RNGADBannerViewManager

RCT_EXPORT_MODULE();

- (UIView *)view
{
    return [RNGADBannerView new];
}

RCT_EXPORT_METHOD(loadBanner:(nonnull NSNumber *)reactTag)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, RNGADBannerView *> *viewRegistry) {
        RNGADBannerView *view = viewRegistry[reactTag];
        if (![view isKindOfClass:[RNGADBannerView class]]) {
            RCTLogError(@"Invalid view returned from registry, expecting RNGADBannerView, got: %@", view);
        } else {
            [view loadBanner];
        }
    }];
}

RCT_REMAP_VIEW_PROPERTY(adSize, _bannerView.adSize, GADAdSize)
RCT_REMAP_VIEW_PROPERTY(adUnitID, _bannerView.adUnitID, NSString)

RCT_EXPORT_VIEW_PROPERTY(testDevices, NSArray)

RCT_EXPORT_VIEW_PROPERTY(onSizeChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onAdLoaded, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onAdFailedToLoad, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onAdOpened, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onAdClosed, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onAdLeftApplication, RCTDirectEventBlock)

@end
