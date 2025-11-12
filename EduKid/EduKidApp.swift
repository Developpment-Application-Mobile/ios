//
//  EduKidApp.swift
//  EduKid
//
//  Created by Mac Mini 11 on 4/11/2025.
//


// EduKidApp.swift
import SwiftUI

@main
struct EduKidApp: App {
    @StateObject private var authVM = AuthViewModel()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !showSplash {
                    MainNavigationView()
                        .environmentObject(authVM)
                        .transition(.opacity)
                }

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        showSplash = false
                        authVM.authState = .welcome
                    }
                }
            }
        }
    }
}
