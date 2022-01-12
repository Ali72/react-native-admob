package com.sbugert.rnadmob;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.UiThread;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableNativeArray;
import com.facebook.react.bridge.UiThreadUtil;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.RequestConfiguration;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

public class RNAdMobInterstitialAdModule extends ReactContextBaseJavaModule {

  public static final String REACT_CLASS = "RNAdMobInterstitial";

  public static final String EVENT_AD_LOADED = "interstitialAdLoaded";
  public static final String EVENT_AD_FAILED_TO_LOAD = "interstitialAdFailedToLoad";
  public static final String EVENT_AD_OPENED = "interstitialAdOpened";
  public static final String EVENT_AD_CLOSED = "interstitialAdClosed";
  public static final String EVENT_AD_LEFT_APPLICATION = "interstitialAdLeftApplication";
  private final Map<String, Promise> mRequestAdPromises;
  ReactApplicationContext mContext;
  Map<String, InterstitialAd> mInterstitialAds;
  Map<String, InterstitialAdLoadRequest> mInterstitialAdLoadRequests;

  public RNAdMobInterstitialAdModule(ReactApplicationContext reactContext) {
    super(reactContext);
    mContext = reactContext;
    mInterstitialAds = new HashMap<>();
    mRequestAdPromises = new HashMap<>();
    mInterstitialAdLoadRequests = new HashMap<>();
  }

  @Override
  public String getName() {
    return REACT_CLASS;
  }

  private void sendEvent(String eventName, @Nullable WritableMap params) {
    getReactApplicationContext().getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(eventName, params);
  }

  @ReactMethod
  public void setAdUnitID(final String adUnitID) {
    UiThreadUtil.runOnUiThread(() -> {
      if (!mInterstitialAds.containsKey(adUnitID)) {
        mInterstitialAdLoadRequests.put(adUnitID,
          new InterstitialAdLoadRequest(mContext, adUnitID, new InterstitialAdLoadCallback() {
            @Override
            public void onAdLoaded(@NonNull InterstitialAd interstitialAd) {
              WritableMap params = Arguments.createMap();
              params.putString("adUnitId", adUnitID);
              sendEvent(EVENT_AD_LOADED, params);
              if (mInterstitialAdLoadRequests.containsKey(adUnitID)) {
                mInterstitialAdLoadRequests.get(adUnitID).isLoading = false;
                mInterstitialAdLoadRequests.get(adUnitID).isLoaded = true;
              }

              mInterstitialAds.put(adUnitID, interstitialAd);
              if (mRequestAdPromises.get(adUnitID) != null) {
                mRequestAdPromises.get(adUnitID).resolve(null);
                // todo:: check how to set promise to null
                mRequestAdPromises.put(adUnitID, null);
              }
            }

            @Override
            public void onAdFailedToLoad(LoadAdError adError) {
              String errorString = "ERROR_UNKNOWN";
              String errorMessage = "Unknown error";
              switch (adError.getCode()) {
                case AdRequest.ERROR_CODE_INTERNAL_ERROR:
                  errorString = "ERROR_CODE_INTERNAL_ERROR";
                  errorMessage = "Internal error, an invalid response was received from the ad server.";
                  break;
                case AdRequest.ERROR_CODE_INVALID_REQUEST:
                  errorString = "ERROR_CODE_INVALID_REQUEST";
                  errorMessage = "Invalid ad request, possibly an incorrect ad unit ID was given.";
                  break;
                case AdRequest.ERROR_CODE_NETWORK_ERROR:
                  errorString = "ERROR_CODE_NETWORK_ERROR";
                  errorMessage = "The ad request was unsuccessful due to network connectivity.";
                  break;
                case AdRequest.ERROR_CODE_NO_FILL:
                  errorString = "ERROR_CODE_NO_FILL";
                  errorMessage = "The ad request was successful, but no ad was returned due to lack of ad inventory.";
                  break;
              }
              WritableMap event = Arguments.createMap();
              WritableMap error = Arguments.createMap();
              event.putString("message", errorMessage);
              event.putString("adUnitId", adUnitID);
              sendEvent(EVENT_AD_FAILED_TO_LOAD, event);
              if (mInterstitialAdLoadRequests.containsKey(adUnitID)) {
                mInterstitialAdLoadRequests.get(adUnitID).isLoading = false;
                mInterstitialAdLoadRequests.get(adUnitID).isLoaded = false;
              }
              if (mRequestAdPromises.get(adUnitID) != null) {
                mRequestAdPromises.get(adUnitID).reject(errorString, errorMessage);
                // todo:: check how to set promise to null
                mRequestAdPromises.put(adUnitID, null);
              }
            }
          }));
      }
    });
  }

  @ReactMethod
  public void setTestDevices(ReadableArray testDevices) {
    Utils.setTestDevices(testDevices);
  }

  @ReactMethod
  public void requestAd(final String adUnitId, final Promise promise) {
    UiThreadUtil.runOnUiThread(() -> {
      if (!mInterstitialAdLoadRequests.containsKey(adUnitId)) {
        return;
      }
      if (mInterstitialAdLoadRequests.get(adUnitId).isLoading ||
        mInterstitialAdLoadRequests.get(adUnitId).isLoaded) {
        promise.reject("E_AD_ALREADY_LOADED", "Ad is already loaded.");
      } else {
        mRequestAdPromises.put(adUnitId, promise);
        AdRequest adRequest = new AdRequest.Builder().build();
        mInterstitialAdLoadRequests.get(adUnitId).adRequest = adRequest;
        mInterstitialAdLoadRequests.get(adUnitId).loadAd();
      }
    });
  }

  @ReactMethod
  public void showAd(final String adUnitId, final Promise promise) {
    UiThreadUtil.runOnUiThread(() -> {
      if (
        mInterstitialAdLoadRequests.containsKey(adUnitId) &&
          mInterstitialAdLoadRequests.get(adUnitId).isLoaded &&
          mInterstitialAds.containsKey(adUnitId)) {
        mInterstitialAds.get(adUnitId).setFullScreenContentCallback(new FullScreenContentCallback() {
          @Override
          public void onAdDismissedFullScreenContent() {
            // Called when fullscreen content is dismissed.
            // Log.d("TAG", "The ad was dismissed.");
            sendEvent(EVENT_AD_CLOSED, null);
          }

          @Override
          public void onAdFailedToShowFullScreenContent(AdError adError) {
            // Called when fullscreen content failed to show.
            // Log.d("TAG", "The ad failed to show.");
          }

          @Override
          public void onAdShowedFullScreenContent() {
            // Called when fullscreen content is shown.
            // Make sure to set your reference to null so you don't
            // show it a second time.
            // mInterstitialAd = null;
            // Log.d("TAG", "The ad was shown.");

            if (mInterstitialAdLoadRequests.containsKey(adUnitId)) {
              mInterstitialAdLoadRequests.get(adUnitId).isLoading = false;
              mInterstitialAdLoadRequests.get(adUnitId).isLoaded = false;
            }
            mInterstitialAds.remove(adUnitId);
            sendEvent(EVENT_AD_LEFT_APPLICATION, null);
          }
        });
        if (mInterstitialAds.containsKey(adUnitId)) {
          mInterstitialAds.get(adUnitId).show(getCurrentActivity());
        }
        promise.resolve(null);
      } else {
        promise.reject("E_AD_NOT_READY", "Ad is not ready.");
      }
    });
  }

  @ReactMethod
  public void isReady(final String adUnitId, final Callback callback) {
    UiThreadUtil.runOnUiThread(() -> {
      if (mInterstitialAds.containsKey(adUnitId)) {
        callback.invoke(mInterstitialAdLoadRequests.get(adUnitId).isLoaded);
      } else {
        callback.invoke(false);
      }
    });
  }
}
