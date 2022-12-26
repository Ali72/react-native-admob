#import "RNAdMobRewarded.h"
#import "RNAdMobUtils.h"

#if __has_include(<React/RCTUtils.h>)
#import <React/RCTUtils.h>
#else
#import "RCTUtils.h"
#endif

static NSString *const kEventAdLoaded = @"rewardedVideoAdLoaded";
static NSString *const kEventAdFailedToLoad = @"rewardedVideoAdFailedToLoad";
static NSString *const kEventAdOpened = @"rewardedVideoAdOpened";
static NSString *const kEventAdClosed = @"rewardedVideoAdClosed";
static NSString *const kEventAdFailedToOpen = @"interstitialAdFailedToOpen";
static NSString *const kEventAdLeftApplication = @"rewardedVideoAdLeftApplication";
static NSString *const kEventRewarded = @"rewardedVideoAdRewarded";
static NSString *const kEventVideoStarted = @"rewardedVideoAdVideoStarted";
static NSString *const kEventVideoCompleted = @"rewardedVideoAdVideoCompleted";

@implementation RNAdMobRewarded
{
    NSString *_adUnitID;
    NSArray *_testDevices;
    RCTPromiseResolveBlock _requestAdResolve;
    RCTPromiseRejectBlock _requestAdReject;
    BOOL hasListeners;
    BOOL statusBarHidden;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

+ (BOOL)requiresMainQueueSetup
{
    return NO;
}

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents
{
    return @[
        kEventRewarded,
        kEventAdLoaded,
        kEventAdFailedToLoad,
        kEventAdOpened,
        kEventVideoStarted,
        kEventAdClosed,
        kEventAdLeftApplication,
        kEventVideoCompleted ];
}

- (instancetype)init{
    if ((self = [super init])) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self->statusBarHidden = [UIApplication sharedApplication].statusBarHidden;
        });
    }
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(willBackgroundApplication:)
     name:UIApplicationWillResignActiveNotification
     object:nil];
    return self;
}

- (void)dealloc {
    NSLog(@"RNAdMobRewarded Object deallocated");
    _rewardedAd = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark exported methods

RCT_EXPORT_METHOD(setAdUnitID:(NSString *)adUnitID)
{
    _adUnitID = adUnitID;
}

RCT_EXPORT_METHOD(setTestDevices:(NSArray *)testDevices)
{
    _testDevices = RNAdMobProcessTestDevices(testDevices, GADSimulatorID);
     GADMobileAds.sharedInstance.requestConfiguration.testDeviceIdentifiers = _testDevices;
}

RCT_EXPORT_METHOD(requestAd:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    _requestAdResolve = resolve;
    _requestAdReject = reject;

    GADMobileAds.sharedInstance.requestConfiguration.testDeviceIdentifiers = _testDevices;

    GADRequest *request = [GADRequest request];
    [GADRewardedAd
     loadWithAdUnitID:_adUnitID
     request:request
     completionHandler:^(GADRewardedAd *ad, NSError *error) {
        if (error) {
            NSLog(@"Rewarded ad failed to load with error: %@", [error localizedDescription]);
            if (self->hasListeners) {
                NSDictionary *jsError = RCTJSErrorFromCodeMessageAndNSError(@"E_AD_FAILED_TO_LOAD", error.localizedDescription, error);
                    [self sendEventWithName:kEventAdFailedToLoad body:jsError];
                }
            self->_requestAdReject(@"E_AD_FAILED_TO_LOAD", error.localizedDescription, error);
            return;
        }
        self.rewardedAd = ad;
        self.rewardedAd.fullScreenContentDelegate = self;
        if (self->hasListeners) {
            [self sendEventWithName:kEventAdLoaded body:nil];
        }
        self->_requestAdResolve(nil);
        NSLog(@"Rewarded ad loaded.");
    }];
}

RCT_EXPORT_METHOD(showAd:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    if ([self isReady]) {
        [self.rewardedAd presentFromRootViewController:[UIApplication sharedApplication].delegate.window.rootViewController
                              userDidEarnRewardHandler:^{
            GADAdReward *reward = self.rewardedAd.adReward;
            // MARK: Reward the user!
            if (self->hasListeners) {
                [self sendEventWithName:kEventRewarded body:@{@"type": reward.type, @"amount": reward.amount}];
            }
        }];

        resolve(nil);
    }
    else {
        reject(@"E_AD_NOT_READY", @"Ad is not ready.", nil);
    }
}

RCT_EXPORT_METHOD(isReady:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNumber numberWithBool:[self isReady]]]);
}

- (void)startObserving
{
    hasListeners = YES;
}

- (void)stopObserving
{
    hasListeners = NO;
}

#pragma mark GADRewardBasedVideoAdDelegate

- (void)adWillPresentFullScreenContent:(id)ad {
    NSLog(@"Ad will present full screen content.");
    //Hide the status bar when full-screen ads shown (fix bug for iphone14)
    if (statusBarHidden == NO){
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
    if (hasListeners){
        [self sendEventWithName:kEventAdOpened body:nil];
    }

}
- (void)adDidDismissFullScreenContent:(id)ad {
    NSLog(@"Ad did dismiss full screen content.");
    if (statusBarHidden == NO){
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }
    if (hasListeners) {
        [self sendEventWithName:kEventAdClosed body:nil];
    }
}

- (void)ad:(id)ad didFailToPresentFullScreenContentWithError:(NSError *)error {
    NSLog(@"Ad failed to present full screen content with error %@.", [error localizedDescription]);
    if (hasListeners){
        [self sendEventWithName:kEventAdFailedToOpen body:nil];
    }
}

- (void)willBackgroundApplication:(id) sender
{
    if (hasListeners) {
        [self sendEventWithName:kEventAdLeftApplication body:nil];
    }
    NSLog(@"applicationDidEnterBackground");
}



-(BOOL)isReady{
    return  [_rewardedAd canPresentFromRootViewController:[UIApplication sharedApplication].delegate.window.rootViewController error:NULL];
}
@end
