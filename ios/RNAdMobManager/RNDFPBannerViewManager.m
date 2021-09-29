#import "RNDFPBannerViewManager.h"
#import "RNDFPBannerView.h"

#if __has_include(<React/RCTBridge.h>)
#import <React/RCTBridge.h>
#import <React/RCTUIManager.h>
#import <React/RCTEventDispatcher.h>
#else
#import "RCTBridge.h"
#import "RCTUIManager.h"
#import "RCTEventDispatcher.h"
#endif

@implementation RNDFPBannerViewManager

RCT_EXPORT_MODULE();

- (UIView *)view
{
  return [RNDFPBannerView new];
}

RCT_EXPORT_METHOD(loadBanner:(nonnull NSNumber *)reactTag)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, RNDFPBannerView *> *viewRegistry) {
        RNDFPBannerView *view = viewRegistry[reactTag];
        if (![view isKindOfClass:[RNDFPBannerView class]]) {
            RCTLogError(@"Invalid view returned from registry, expecting RNDFPBannerView, got: %@", view);
        } else {
            [view loadBanner];
        }
    }];
}

RCT_REMAP_VIEW_PROPERTY(adSize, _bannerView.adSize, GADAdSize)
RCT_REMAP_VIEW_PROPERTY(adUnitID, _bannerView.adUnitID, NSString)
RCT_EXPORT_VIEW_PROPERTY(validAdSizes, NSArray)
RCT_EXPORT_VIEW_PROPERTY(testDevices, NSArray)

RCT_EXPORT_VIEW_PROPERTY(onSizeChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onAppEvent, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onAdLoaded, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onAdFailedToLoad, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onAdOpened, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onAdClosed, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onAdLeftApplication, RCTDirectEventBlock)

@end
