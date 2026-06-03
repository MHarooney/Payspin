import Flutter
import UIKit
import FirebaseCore
import FirebaseAuth

/// Classic AppDelegate lifecycle. UIScene + [FlutterImplicitEngineDelegate] can leave the
/// simulator with a black screen and no VM service on iOS 26+ (flutter/flutter#186572).
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    GeneratedPluginRegistrant.register(with: self)
    // Required for Firebase Phone Auth silent verification on physical devices.
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    if FirebaseApp.app() != nil {
      Auth.auth().setAPNSToken(deviceToken, type: .unknown)
    }
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if FirebaseApp.app() != nil, Auth.auth().canHandleNotification(userInfo) {
      completionHandler(.noData)
      return
    }
    super.application(
      application,
      didReceiveRemoteNotification: userInfo,
      fetchCompletionHandler: completionHandler
    )
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    // Firebase Phone Auth's reCAPTCHA redirects back via the encoded-app-id
    // scheme (app-1-…://firebaseauth/link). Since Flutter 3.27 changed iOS
    // deep-link handling, forwarding this URL to super lets Flutter/go_router
    // consume it and pop the onboarding screens back to Welcome
    // (flutterfire #17135). Let Firebase handle it and stop here so Flutter
    // never routes on it.
    if FirebaseApp.app() != nil {
      if Auth.auth().canHandle(url) {
        return true
      }
      if let scheme = url.scheme,
         let encodedAppId = Bundle.main.object(forInfoDictionaryKey: "FirebaseEncodedAppId") as? String,
         scheme.caseInsensitiveCompare(encodedAppId) == .orderedSame {
        return true
      }
    }
    return super.application(app, open: url, options: options)
  }
}
