//
//  flashappApp.swift
//  flashapp
//
//  Created by Peter Keating on 4/28/26.
//

import SwiftUI

@main
struct flashappApp: App {
    @StateObject private var coinStore = CoinStore()
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var sharedInboxStore = SharedInboxStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coinStore)
                .environmentObject(sessionStore)
                .environmentObject(sharedInboxStore)
                .background(FlashPalette.canvasLight.ignoresSafeArea())
                .fullScreenCover(isPresented: Binding(
                    get: { !sessionStore.hasCompletedOnboarding },
                    set: { _ in }
                )) {
                    OnboardingView()
                        .environmentObject(sessionStore)
                }
        }
    }
}


