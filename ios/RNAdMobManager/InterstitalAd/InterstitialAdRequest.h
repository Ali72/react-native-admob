//
//  InterstitialAdRequest.h
//  Pods
//
//  Created by Ali on 7/31/21.
//



@import GoogleMobileAds;

@interface InterstitialAdRequest:NSObject

@property NSString *unitId;
@property GADRequest *adRequest;
@property void (^InterstitialAdLoadCallback) (GADInterstitialAd *ad, NSError *error);
@property bool isLoading;
@property bool isLoaded;

@end

