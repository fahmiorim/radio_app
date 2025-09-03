package com.example.radio_odan_app

import io.flutter.app.FlutterApplication
import com.facebook.FacebookSdk

class MainApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        FacebookSdk.sdkInitialize(applicationContext)
    }
}
