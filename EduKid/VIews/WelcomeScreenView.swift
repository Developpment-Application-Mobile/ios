import SwiftUI
import Network

struct WelcomeScreen: View {
    var onGetStartedClick: () -> Void = {}
    var onChildLoginClick: () -> Void = {}
    
    @State private var isOffline = false
    @State private var showArcadeGames = false
    @State private var showOfflineBanner = false
    
    let monitor = NWPathMonitor()
    
    var body: some View {
        ZStack {
            // Background gradient
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.686, green: 0.494, blue: 0.906).opacity(0.6),
                    Color(red: 0.153, green: 0.125, blue: 0.322)
                ]),
                center: .init(x: 0.3, y: 0.3),
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            // Decorative elements
            DecorativeElements()
            
            // Main content
            VStack(spacing: 0) {
                Spacer()
                
                // Offline Banner (appears at top when no internet)
                if showOfflineBanner {
                    OfflineBannerView(onPlayGamesClick: {
                        showArcadeGames = true
                    })
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                
                // Title
                Text("Welcome\nto EduKid Academy!")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
                    .lineSpacing(6)
                    .frame(maxWidth: 323, alignment: .leading)
                
                Spacer().frame(height: 15)
                
                // Subtitle
                Text("Play, Learn, and Explore with Exciting Quizzes!")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: 269, alignment: .leading)
                
                Spacer().frame(height: 34)
                
                // Get Started Button
                Button(action: onGetStartedClick) {
                    HStack(spacing: 12) {
                        Text("GET STARTED")
                            .font(.system(size: 16, weight: .bold))
                        
                        if isOffline {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 14))
                        }
                    }
                    .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.white)
                    .cornerRadius(30)
                }
                .disabled(isOffline)
                .opacity(isOffline ? 0.6 : 1.0)
                
                Spacer().frame(height: 20)
                
                // Child Login Button
                Button(action: onChildLoginClick) {
                    HStack(spacing: 12) {
                        Text("LOG IN AS CHILD")
                            .font(.system(size: 16, weight: .bold))
                        
                        if isOffline {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 14))
                        }
                    }
                    .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.white)
                    .cornerRadius(30)
                }
                .disabled(isOffline)
                .opacity(isOffline ? 0.6 : 1.0)
                
                // Offline Arcade Button (only shows when offline)
                if isOffline {
                    Spacer().frame(height: 20)
                    
                    Button(action: { showArcadeGames = true }) {
                        HStack(spacing: 12) {
                            Text("🎮")
                                .font(.system(size: 24))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PLAY OFFLINE GAMES")
                                    .font(.system(size: 16, weight: .bold))
                                
                                Text("No internet required")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.purple.opacity(0.9),
                                    Color.pink.opacity(0.9)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(30)
                        .shadow(color: Color.purple.opacity(0.4), radius: 15, x: 0, y: 8)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 20)
        }
        .fullScreenCover(isPresented: $showArcadeGames) {
            OfflineArcadeGamesView()
        }
        .onAppear {
            startNetworkMonitoring()
        }
        .onDisappear {
            stopNetworkMonitoring()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isOffline)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showOfflineBanner)
    }
    
    func startNetworkMonitoring() {
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                let wasOffline = isOffline
                isOffline = path.status != .satisfied
                
                // Show banner when going offline
                if !wasOffline && isOffline {
                    showOfflineBanner = true
                    // Auto-hide banner after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        showOfflineBanner = false
                    }
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    func stopNetworkMonitoring() {
        monitor.cancel()
    }
}

// MARK: - Offline Banner
struct OfflineBannerView: View {
    let onPlayGamesClick: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("No Internet Connection")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Try offline arcade games instead!")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button(action: onPlayGamesClick) {
                HStack(spacing: 6) {
                    Text("Play")
                        .font(.system(size: 13, weight: .bold))
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 12))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange)
                .cornerRadius(15)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.orange.opacity(0.6), lineWidth: 2)
                )
        )
        .shadow(color: Color.orange.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Decorative Elements
struct DecorativeElements: View {
    var body: some View {
        ZStack {
            // Book and Globe - Center
            Image("book_and_globe")
                .resizable()
                .scaledToFit()
                .frame(width: 426, height: 426)
                .offset(x: 0, y: -200)
            
            // Education Book - Top Left
            Image("education_book")
                .resizable()
                .scaledToFit()
                .frame(width: 224, height: 224)
                .offset(x: -160, y: -350)
            
            // Book Stacks - Bottom Right (with blur)
            Image("book_stacks")
                .resizable()
                .scaledToFit()
                .frame(width: 116, height: 116)
                .blur(radius: 2)
                .offset(x: 120, y: 250)
            
            // Coins 1 - Top Right
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 123, height: 123)
                .offset(x: 140, y: -350)
            
            // Coins 2 - Top Center (flipped horizontally)
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 53, height: 53)
                .scaleEffect(x: -1, y: 1)
                .offset(x: 20, y: -280)
            
            // Coins 3 - Middle Right (rotated)
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .rotationEffect(.degrees(28.68))
                .offset(x: 150, y: 10)
            
            // Coins 4 - Bottom Left (rotated)
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
                .rotationEffect(.degrees(38.66))
                .offset(x: -140, y: 250)
        }
    }
}

// MARK: - Preview
struct WelcomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeScreen()
    }
}
