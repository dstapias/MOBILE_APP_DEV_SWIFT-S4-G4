import SwiftUI
import FirebaseCore
import FirebaseAuth
import RealmSwift



class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        let schemaVersion: UInt64 = 1 // <-- AJUSTA ESTE NÚMERO SI ES NECESARIO

            // 2. Crea el objeto de configuración
            let config = Realm.Configuration(
                schemaVersion: schemaVersion, // Le dices a Realm cuál es la versión actual de tu código
                migrationBlock: { migration, oldSchemaVersion in
                    // Este bloque se ejecuta SÓLO si Realm abre una base de datos
                    // con una versión de esquema MÁS ANTIGUA que la 'schemaVersion' definida arriba.

                    if oldSchemaVersion < schemaVersion {
                        // Como SOLO añadiste propiedades nuevas ('needsSync', 'isDeletedLocally')
                        // a RealmCartItem y les diste un valor por defecto (= false),
                        // Realm puede manejar la migración automáticamente.
                        // Por lo tanto, este bloque puede estar vacío.
                        print("Realizando migración de Realm de v\(oldSchemaVersion) a v\(schemaVersion)...")
                        // Si en el futuro renombraras una propiedad (ej. 'name' a 'fullName'),
                        // aquí sí necesitarías código como:
                        // migration.renameProperty(onType: RealmCartItem.className(), from: "name", to: "fullName")
                    }
                },
                deleteRealmIfMigrationNeeded: true
            )

            // 3. Establece esta configuración como la predeterminada para toda la app
            Realm.Configuration.defaultConfiguration = config

        do {
            let realm = try Realm()
        } catch { print("Realm wipe failed: \(error)") }
            // 4. (Opcional pero recomendado) Intenta abrir Realm ahora mismo para forzar la migración.
            //    Esto asegura que cualquier error de migración ocurra aquí al inicio.
            do {
                _ = try Realm() // Intenta abrir con la nueva configuración
                print("✅ Realm configurado y migrado (si fue necesario) a versión \(schemaVersion). Path: \(Realm.Configuration.defaultConfiguration.fileURL?.path ?? "N/A")")
            } catch {
                print("❌❌❌ ERROR CRÍTICO EN APPDELEGATE: No se pudo abrir Realm después de configurar migración: \(error)")
                // Aquí podrías querer manejar el error de forma más drástica,
                // porque si Realm no funciona, muchas partes de tu app podrían fallar.
            }
        
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
    @StateObject var networkMonitor = NetworkMonitor()

    
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    let signInService = SignInUserService.shared


    var body: some Scene {
            WindowGroup {
                if isLoggedIn {
                    MainTabView(networkMonitor: networkMonitor, signInService: signInService)
                        .environmentObject(signInService)
                        .environmentObject(networkMonitor)

                } else {
                    ContentView(isLoggedIn: $isLoggedIn)
                        .environmentObject(signInService)
                        .environmentObject(networkMonitor)
                }
            }
    }
}
