import SwiftUI

@main
struct EduKidApp: App {
    @StateObject private var authVM = AuthViewModel()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main content - always present but might be hidden by splash
                MainNavigationView()
                    .environmentObject(authVM)
                    .opacity(showSplash ? 0 : 1)

                // Splash screen overlay
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                print("\n🎬 APP: onAppear called")
                print("🎬 APP: Starting splash and session initialization")
                
                // Initialize session in background while splash is showing
                Task {
                    await authVM.initializeSession()
                    print("🎬 APP: Session initialization complete")
                }
                
                // Hide splash after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    print("🎬 APP: Splash timer finished, hiding splash")
                    print("🎬 APP: Current auth state: \(authVM.authState)")
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}
