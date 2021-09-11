#import "RNAdMobInterstitial.h"
#import "InterstitialAdRequest.h"
#import "RNAdMobUtils.h"
#import "InterstitialAdPromise.h"

#if __has_include(<React/RCTUtils.h>)
#import <React/RCTUtils.h>
#else
#import "RCTUtils.h"
#endif

static NSString *const kEventAdLoaded = @"interstitialAdLoaded";
static NSString *const kEventAdFailedToLoad = @"interstitialAdFailedToLoad";
static NSString *const kEventAdOpened = @"interstitialAdOpened";
static NSString *const kEventAdFailedToOpen = @"interstitialAdFailedToOpen";
static NSString *const kEventAdClosed = @"interstitialAdClosed";
static NSString *const kEventAdLeftApplication = @"interstitialAdLeftApplication";


@implementation RNAdMobInterstitial
{
    NSArray *_testDevices;
    NSMutableDictionary *interstitialAds;
    NSMutableDictionary *interstitialAdLoadRequests;
    NSMutableDictionary *requestAdPromises;
    BOOL hasListeners;
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
        kEventAdLoaded,
        kEventAdFailedToLoad,
        kEventAdOpened,
        kEventAdFailedToOpen,
        kEventAdClosed,
        kEventAdLeftApplication ];
}
- (instancetype)init{
    interstitialAds = [[NSMutableDictionary alloc] init];
    interstitialAdLoadRequests = [[NSMutableDictionary alloc] init];
    requestAdPromises = [[NSMutableDictionary alloc] init];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(willLeaveApplication:)
     name:UIApplicationWillResignActiveNotification
     object:nil];
    return self;
}
- (void)dealloc {
    NSLog(@"interstitial Object deallocated");
    //    interstitial = nil;
    interstitialAds = nil;
    interstitialAdLoadRequests = nil;
    requestAdPromises = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark exported methods

RCT_EXPORT_METHOD(setAdUnitID:(NSString *)adUnitID)
{
    //    _adUnitID = adUnitID;
    NSLog(@"adsLog setAdUnitID=>%@",adUnitID);
    if (![interstitialAdLoadRequests valueForKey:adUnitID]){
        NSLog(@"adsLog setAdUnitID not exist=>%@",adUnitID);
        InterstitialAdRequest *request = [[InterstitialAdRequest alloc] init];
        request.unitId = adUnitID;
        request.isLoading = false;
        request.isLoaded = false;
        request.InterstitialAdLoadCallback = ^(GADInterstitialAd *ad, NSError *error) {
            if (error) {
                NSLog(@"adsLog interstitial:didFailToReceiveAdWithError: %@", [error localizedDescription]);
                if (self->hasListeners) {
                    NSDictionary *jsError = RCTJSErrorFromCodeMessageAndNSError(@"E_AD_REQUEST_FAILED", error.localizedDescription, error);
                    [self sendEventWithName:kEventAdFailedToLoad body:jsError];
                }
                InterstitialAdRequest *request = (InterstitialAdRequest *)([self->interstitialAdLoadRequests objectForKey:adUnitID]);
                request.isLoading = false;
                request.isLoaded = false;
                [self->interstitialAdLoadRequests setObject:request  forKey:adUnitID];

                InterstitialAdPromise *promise =  (InterstitialAdPromise *)([self->requestAdPromises objectForKey:adUnitID]);
                if (promise) {
                    promise.reject(@"E_AD_REQUEST_FAILED", error.localizedDescription, error);
                    [self->requestAdPromises removeObjectForKey:adUnitID];
                }
                return;
            }

            InterstitialAdRequest *request =  (InterstitialAdRequest *)([self->interstitialAdLoadRequests valueForKey:adUnitID]);
            request.isLoading = false;
            request.isLoaded = true;
            [self->interstitialAdLoadRequests setObject:request  forKey:adUnitID];
            ad.fullScreenContentDelegate = self;
            if (self->hasListeners) {
                [self sendEventWithName:kEventAdLoaded body:nil];
            }
            [self->interstitialAds setObject:ad forKey:request.unitId];

            InterstitialAdPromise *promise =  (InterstitialAdPromise *)([self->requestAdPromises objectForKey:adUnitID]);
            if (promise) {
                promise.resolve(nil);
                [self->requestAdPromises removeObjectForKey:adUnitID];
            }


        };
        [interstitialAdLoadRequests setObject:request  forKey:adUnitID];
        NSLog(@"adsLog setAdUnitID interstitialAdLoadRequests count=>%lu",(unsigned long)[self->interstitialAdLoadRequests count]);
    }

}

RCT_EXPORT_METHOD(setTestDevices:(NSArray *)testDevices)
{
    _testDevices = RNAdMobProcessTestDevices(testDevices, kGADSimulatorID);
    GADMobileAds.sharedInstance.requestConfiguration.testDeviceIdentifiers = _testDevices;
}

RCT_EXPORT_METHOD(requestAd:(NSString *)adUnitID resolve:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{

    NSLog(@"adsLog interstitialAdLoadRequests count=>%lu",(unsigned long)[interstitialAdLoadRequests count]);
    InterstitialAdRequest *request =  (InterstitialAdRequest *) [interstitialAdLoadRequests objectForKey:adUnitID];
    if (request != nil){
        NSLog(@"adsLog unitId=>%@",request.unitId);
        if (request.isLoading || request.isLoaded){
            reject(@"E_AD_ALREADY_LOADED", @"Ad is already loaded.", nil);
        }else{
            GADRequest *AdRequest = [GADRequest request];
            request.unitId = adUnitID;
            request.adRequest = AdRequest;
            [GADInterstitialAd loadWithAdUnitID:adUnitID
                                        request:AdRequest
                              completionHandler:request.InterstitialAdLoadCallback];
            InterstitialAdPromise *promise = [[InterstitialAdPromise alloc] init];
            promise.resolve = resolve;
            promise.reject = reject;
            [requestAdPromises setObject:promise  forKey:adUnitID];
//            resolve(nil);
        }

    }
}

RCT_EXPORT_METHOD(showAd:(NSString *)adUnitID resolve:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    GADInterstitialAd *interstitialAd =  (GADInterstitialAd *)([interstitialAds objectForKey:adUnitID]);
    if (interstitialAd == nil){
        reject(@"E_AD_NOT_READY", @"Ad is not ready.", nil);
        return;
    }

    if ([self isReadyAd:adUnitID]){
        NSLog(@"adsLog ready=>%@",adUnitID);
        [interstitialAd presentFromRootViewController:[UIApplication sharedApplication].delegate.window.rootViewController];
        resolve(nil);
    }else{
        NSLog(@"adsLog notReady=>%@",adUnitID);
        reject(@"E_AD_NOT_READY", @"Ad is not ready.", nil);
    }
}

RCT_EXPORT_METHOD(isReady:(NSString *)adUnitID callback:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNumber numberWithBool:[self isReadyAd:adUnitID]]]);
}

- (void)startObserving
{
    hasListeners = YES;
}

- (void)stopObserving
{
    hasListeners = NO;
}

#pragma mark GADInterstitialDelegate

//MARK:in V8 Change to👇
- (void)adDidPresentFullScreenContent:(id)ad {
    NSLog(@"Ad did present full screen content.");
    GADInterstitialAd *interstitialAd = (GADInterstitialAd *)ad;
    InterstitialAdRequest *request = (InterstitialAdRequest *) [interstitialAdLoadRequests objectForKey:interstitialAd.adUnitID];
    request.isLoading = false;
    request.isLoaded = false;
    [interstitialAdLoadRequests setObject:request  forKey:interstitialAd.adUnitID];

    if (hasListeners){
        [self sendEventWithName:kEventAdOpened body:nil];
    }

}

- (void)ad:(id)ad didFailToPresentFullScreenContentWithError:(NSError *)error {
    NSLog(@"Ad failed to present full screen content with error %@.", [error localizedDescription]);

    if (hasListeners){
        [self sendEventWithName:kEventAdFailedToOpen body:nil];
    }
}


- (void)adDidDismissFullScreenContent:(id)ad {
    NSLog(@"Ad did dismiss full screen content.");
    GADInterstitialAd *interstitialAd = (GADInterstitialAd *)ad;
    [interstitialAds removeObjectForKey:interstitialAd.adUnitID];
    if (hasListeners) {
        [self sendEventWithName:kEventAdClosed body:nil];
    }
}

- (void)willLeaveApplication:(id) sender
{
    if (hasListeners) {
        [self sendEventWithName:kEventAdLeftApplication body:nil];
    }
    NSLog(@"applicationDidEnterBackground");
}

-(BOOL)isReadyAd:(NSString *)adUnitID{
    InterstitialAdRequest *request =  (InterstitialAdRequest *) [interstitialAdLoadRequests objectForKey:adUnitID];
    return request && request.isLoaded;
}
@end
