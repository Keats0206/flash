import CoreLocation
import Foundation

final class LocationContext: NSObject, ObservableObject, CLLocationManagerDelegate, @unchecked Sendable {
    static let shared = LocationContext()

    @Published private(set) var cityString: String? = nil

    private let manager = CLLocationManager()
    private var pendingContinuation: CheckedContinuation<String?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }

    var authorizationStatus: CLAuthorizationStatus { manager.authorizationStatus }

    func fetchLocation() async -> String? {
        if let cached = cityString { return cached }
        let status = manager.authorizationStatus
        #if os(iOS)
        if status == .denied || status == .restricted { return nil }
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
            try? await Task.sleep(for: .milliseconds(1000))
        }
        let updated = manager.authorizationStatus
        guard updated == .authorizedWhenInUse || updated == .authorizedAlways else { return nil }
        #else
        guard status == .authorized else { return nil }
        #endif
        return await withCheckedContinuation { [weak self] cont in
            DispatchQueue.main.async {
                self?.pendingContinuation = cont
                self?.manager.requestLocation()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else {
            DispatchQueue.main.async {
                self.pendingContinuation?.resume(returning: nil)
                self.pendingContinuation = nil
            }
            return
        }
        CLGeocoder().reverseGeocodeLocation(loc) { [weak self] placemarks, _ in
            DispatchQueue.main.async {
                let p = placemarks?.first
                let parts = [p?.locality, p?.administrativeArea, p?.country].compactMap { $0 }
                let result = parts.isEmpty ? nil : parts.joined(separator: ", ")
                self?.cityString = result
                self?.pendingContinuation?.resume(returning: result)
                self?.pendingContinuation = nil
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.pendingContinuation?.resume(returning: nil)
            self.pendingContinuation = nil
        }
    }
}
