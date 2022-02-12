#import "RCTConvert+GADAdSize.h"

@implementation RCTConvert (GADAdSize)

+ (GADAdSize)GADAdSize:(id)json
{
    NSString *adSize = [self NSString:json];
    if ([adSize isEqualToString:@"banner"]) {
        return GADAdSizeBanner;
    } else if ([adSize isEqualToString:@"fullBanner"]) {
        return GADAdSizeFullBanner;
    } else if ([adSize isEqualToString:@"largeBanner"]) {
        return GADAdSizeLargeBanner;
    } else if ([adSize isEqualToString:@"fluid"]) {
        return GADAdSizeFluid;
    } else if ([adSize isEqualToString:@"skyscraper"]) {
        return GADAdSizeSkyscraper;
    } else if ([adSize isEqualToString:@"leaderboard"]) {
        return GADAdSizeLeaderboard;
    } else if ([adSize isEqualToString:@"mediumRectangle"]) {
        return GADAdSizeMediumRectangle;
    } else if ([adSize isEqualToString:@"smartBannerPortrait"]) {
        return kGADAdSizeSmartBannerPortrait;
    } else if ([adSize isEqualToString:@"smartBannerLandscape"]) {
        return kGADAdSizeSmartBannerLandscape;
    }
    else {
        return GADAdSizeInvalid;
    }
}

@end
