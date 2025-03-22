import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()

    @Published var latitude: Double? = nil
    @Published var longitude: Double? = nil
    @Published var isAuthorized = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkAuthorizationStatus()
    }

    // ✅ Check Authorization Status
    private func checkAuthorizationStatus() {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            print("📍 Requesting location permission...")
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
            print("✅ Location Authorized")
            DispatchQueue.global().async { [weak self] in
                self?.startUpdating()
            }
        default:
            isAuthorized = false
            print("❌ Location not authorized")
        }
    }

    // ✅ Called when Authorization Changes
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("🔄 Authorization Changed: \(manager.authorizationStatus.rawValue)")
        checkAuthorizationStatus()
    }

    // ✅ Start Updating Location (Runs on Background Thread)
    func startUpdating() {
        if CLLocationManager.locationServicesEnabled() {
            print("📍 Starting location updates...")
            DispatchQueue.global().async {
                self.locationManager.startUpdatingLocation()
            }
        } else {
            print("❌ Location services disabled")
        }
    }

    // ✅ Stop Updating Location
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }

    // ✅ Get Updated Location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        DispatchQueue.main.async { [weak self] in
            self?.latitude = location.coordinate.latitude
            self?.longitude = location.coordinate.longitude
            print("📍 Updated Location - Lat: \(self?.latitude ?? 0), Lon: \(self?.longitude ?? 0)")
        }
        
        stopUpdating() // ✅ Stop after getting location
    }
}
