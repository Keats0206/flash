import Foundation
import SwiftUI

@MainActor
final class FlashBindingStore: ObservableObject {
    @Published private var stringValues: [String: String] = [:]
    @Published private var boolValues: [String: Bool] = [:]
    @Published private var numberValues: [String: Double] = [:]
    @Published private var dateValues: [String: Date] = [:]

    func stringBinding(for key: String, default defaultValue: String = "") -> Binding<String> {
        Binding(
            get: { self.stringValues[key] ?? defaultValue },
            set: { self.stringValues[key] = $0 }
        )
    }

    func boolBinding(for key: String, default defaultValue: Bool = false) -> Binding<Bool> {
        Binding(
            get: { self.boolValues[key] ?? defaultValue },
            set: { self.boolValues[key] = $0 }
        )
    }

    func numberBinding(for key: String, default defaultValue: Double = 0) -> Binding<Double> {
        Binding(
            get: { self.numberValues[key] ?? defaultValue },
            set: { self.numberValues[key] = $0 }
        )
    }

    func dateBinding(for key: String, default defaultValue: Date = Date()) -> Binding<Date> {
        Binding(
            get: { self.dateValues[key] ?? defaultValue },
            set: { self.dateValues[key] = $0 }
        )
    }
}
