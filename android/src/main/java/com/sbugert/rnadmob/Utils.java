package com.sbugert.rnadmob;

import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableNativeArray;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.RequestConfiguration;

import java.util.ArrayList;

public class Utils {
  static public void setTestDevices(ReadableArray testDevices) {
    if(!(testDevices instanceof ReadableNativeArray)){return;}
    ReadableNativeArray nativeArray = (ReadableNativeArray) testDevices;
    ArrayList<String> deviceList = new ArrayList<>();
    for (Object item : nativeArray.toArrayList()) {
      if (item instanceof String) {
        deviceList.add(String.valueOf(item));
      }
    }
    RequestConfiguration configuration =
      new RequestConfiguration.Builder().setTestDeviceIds(deviceList).build();
    MobileAds.setRequestConfiguration(configuration);
  }
}
