import Flutter
import UIKit
import FirebaseAuth

/// Forwards Firebase Phone Auth reCAPTCHA callbacks when using UIScene lifecycle.
/// Without this, the simulator browser closes but verification never completes.
class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    for context in URLContexts {
      if Auth.auth().canHandle(context.url) {
        return
      }
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
