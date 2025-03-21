import SwiftUI
import FirebaseCore
import FirebaseAuth



class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // ✅ Solicitar permiso para notificaciones remotas
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("Notification permission granted: \(granted)")
        }
        
        application.registerForRemoteNotifications()
        
        return true
    }
    
    // ✅ Manejar recepción de notificaciones remotas
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        
        completionHandler(.newData)
    }
}

@main
struct YourApp: App {
  // register app delegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    let signInService = SignInUserService.shared


    var body: some Scene {
            WindowGroup {
                if isLoggedIn {
                    MainTabView()
                        .environmentObject(signInService) // ✅ Inyectar aquí directamente
                } else {
                    ContentView(isLoggedIn: $isLoggedIn)
                        .environmentObject(signInService) // ✅ Inyectar aquí también
                }
            }
    }
}
