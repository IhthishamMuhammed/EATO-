// 📱 iOS Setup - Update ios/Runner/AppDelegate.swift

import UIKit
import Flutter
import GoogleMaps  // ✅ ADD: Import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // ✅ ADD: Initialize Google Maps with your API key
    GMSServices.provideAPIKey("AIzaSyB6vbdnp4ydO2wUQv0TxyJ_NCNVhxHEMH4")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
