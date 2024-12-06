package com.sbugert.rnadmob;

import android.app.Activity;
import android.util.Log;

import androidx.annotation.Nullable;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.UiThreadUtil;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.appopen.AppOpenAd;


import java.util.Date;


public class RNAdMobOpenAppAdModule extends ReactContextBaseJavaModule {

  private static final String LOG_TAG = "RNAdMobOpenAppAdModule";
  public static final String REACT_CLASS = "RNAdMobOpenApp";

  public static final String EVENT_AD_LOADED = "openAppAdLoaded";
  public static final String EVENT_AD_FAILED_TO_LOAD = "openAppAdFailedToLoad";
  public static final String EVENT_AD_OPENED = "openAppAdOpened";
  public static final String EVENT_AD_CLOSED = "openAppAdClosed";
  public static final String EVENT_AD_FAILED_TO_OPEN = "openAppAdFailedToOpen";

  ReactApplicationContext mContext;

  String AD_UNIT_ID = "";
  private AppOpenAd appOpenAd = null;
  private boolean isLoadingAd = false;
  private boolean isShowingAd = false;

  /** Keep track of the time an app open ad is loaded to ensure you don't show an expired ad. */
  private long loadTime = 0;

  public RNAdMobOpenAppAdModule(ReactApplicationContext reactContext) {
    super(reactContext);
    mContext = reactContext;
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
    this.AD_UNIT_ID = adUnitID;
  }

  @ReactMethod
  public void setTestDevices(ReadableArray testDevices) {
    Utils.setTestDevices(testDevices);
  }

  @ReactMethod
  public void requestAd(final Promise promise) {
    UiThreadUtil.runOnUiThread(() -> {

      if (!AD_UNIT_ID.isEmpty()) {
        promise.reject("E_AD_UNIT_ID_IS_EMPTY", "should set ad unit id before request.");
        return;
      }

      if (isAdAvailable()) {
        promise.reject("E_AD_ALREADY_LOADED", "Ad is already loaded.");
      }

      if (isLoadingAd) {
        promise.reject("E_AD_IS_LOADING", "Ad is loading.");
        return;
      }

      isLoadingAd = true;
      AdRequest request = new AdRequest.Builder().build();
      AppOpenAd.load(
        mContext, AD_UNIT_ID, request,
        AppOpenAd.APP_OPEN_AD_ORIENTATION_PORTRAIT,
        new AppOpenAd.AppOpenAdLoadCallback() {
          @Override
          public void onAdLoaded(AppOpenAd ad) {
            // Called when an app open ad has loaded.
            Log.d(LOG_TAG, "Ad was loaded.");
            appOpenAd = ad;
            isLoadingAd = false;
            loadTime = (new Date()).getTime();
            sendEvent(EVENT_AD_LOADED, null);
            promise.resolve(null);
          }

          @Override
          public void onAdFailedToLoad(LoadAdError loadAdError) {
            // Called when an app open ad has failed to load.
            Log.d(LOG_TAG, loadAdError.getMessage());
            isLoadingAd = false;
            String errorString = "ERROR_UNKNOWN";
            String errorMessage = "Unknown error";
            switch (loadAdError.getCode()) {
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
            event.putString("message", errorMessage);
            event.putString("adUnitId", AD_UNIT_ID);
            sendEvent(EVENT_AD_FAILED_TO_LOAD, event);

            promise.reject(errorString, errorMessage);

          }
        });



    });
  }

  @ReactMethod
  public void showAd(final Promise promise) {
    UiThreadUtil.runOnUiThread(() -> {
      // If the app open ad is already showing, do not show the ad again.
      if (isShowingAd) {
        Log.d(LOG_TAG, "The app open ad is already showing.");
        promise.reject("E_AD_ALREADY_SHOWING", "The app open ad is already showing.");
        return;
      }

      // If the app open ad is not available yet, invoke the callback then load the ad.
      if (!isAdAvailable()) {
        Log.d(LOG_TAG, "The app open ad is not ready yet.");
        promise.reject("E_AD_NOT_LOADED_YET", "The app open ad is not ready yet.");
        return;
      }

      String errorString = "ERROR_FAILED_TO_SHOW";

      appOpenAd.setFullScreenContentCallback(
        new FullScreenContentCallback() {

          @Override
          public void onAdDismissedFullScreenContent() {
            // Called when fullscreen content is dismissed.
            // Set the reference to null so isAdAvailable() returns false.
            Log.d(LOG_TAG, "Ad dismissed fullscreen content.");
            appOpenAd = null;
            isShowingAd = false;
            sendEvent(EVENT_AD_CLOSED, null);
            promise.resolve(null);
          }

          @Override
          public void onAdFailedToShowFullScreenContent(AdError adError) {
            // Called when fullscreen content failed to show.
            // Set the reference to null so isAdAvailable() returns false.
            Log.d(LOG_TAG, adError.getMessage());
            appOpenAd = null;
            isShowingAd = false;


            String errorMessage = adError.getMessage().isEmpty() ? "Unknown error" : adError.getMessage();

            WritableMap event = Arguments.createMap();
            event.putString("message", errorMessage);
            event.putString("adUnitId", AD_UNIT_ID);
            sendEvent(EVENT_AD_FAILED_TO_OPEN, event);

            promise.reject(errorString, errorMessage);
          }

          @Override
          public void onAdShowedFullScreenContent() {
            // Called when fullscreen content is shown.
            Log.d(LOG_TAG, "Ad showed fullscreen content.");
            sendEvent(EVENT_AD_OPENED, null);
          }
        });
      isShowingAd = true;
      Activity activity = getCurrentActivity();
      if (activity == null) {
        promise.reject(errorString, "Activity is null");
        return;
      }
      appOpenAd.show(activity);

    });
  }



  @ReactMethod
  public void isReady(final Callback callback) {
    UiThreadUtil.runOnUiThread(() -> {
      callback.invoke(isAdAvailable());
    });
  }


  /** Check if ad exists and can be shown. */
  private boolean isAdAvailable() {
    return appOpenAd != null;
  }
}
