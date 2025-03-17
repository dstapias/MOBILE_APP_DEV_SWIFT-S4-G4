import SwiftUI
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct YourApp: App {
  // register app delegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false


  var body: some Scene {
    WindowGroup {
        if isLoggedIn {
            MainTabView()
        } else {
            ContentView(isLoggedIn: $isLoggedIn)
        }
    }
  }
}
