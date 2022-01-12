package com.sbugert.rnadmob;

import com.facebook.react.bridge.ReactApplicationContext;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;

public class InterstitialAdLoadRequest {

  String UnitId;
  AdRequest adRequest;
  InterstitialAdLoadCallback loadCallback;
  ReactApplicationContext mContext;
  Boolean isLoading = false;
  Boolean isLoaded = false;



  InterstitialAdLoadRequest(ReactApplicationContext c, String Id, InterstitialAdLoadCallback loadCallback){
    UnitId = Id;
    mContext = c;
    this.loadCallback = loadCallback;
  }

  public void loadAd() {
    InterstitialAd.load(mContext, UnitId, adRequest, loadCallback);
    isLoading = true;
    isLoaded = false;
  }

}
