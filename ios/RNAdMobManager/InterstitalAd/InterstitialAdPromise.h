//
//  InterstitialAdPromise.h
//  Pods
//
//  Created by Ali on 7/31/21.
//

#if __has_include(<React/RCTBridgeModule.h>)
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#else
#import "RCTBridgeModule.h"
#import "RCTEventEmitter.h"
#endif


@interface InterstitialAdPromise:NSObject
@property RCTPromiseResolveBlock resolve;
@property RCTPromiseRejectBlock reject;
@end
