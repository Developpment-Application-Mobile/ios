import SwiftUI
import Network

// Network Monitor to detect offline status
class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected: Bool = true
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

struct MainNavigationView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var showArcadeGames = false

    var body: some View {
        ZStack {
            content
                .animation(.easeInOut, value: authVM.authState)
            
            // Floating Arcade Button (visible on most screens)
            if shouldShowArcadeButton {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showArcadeGames = true }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.purple, Color.pink]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 70, height: 70)
                                    .shadow(color: Color.purple.opacity(0.5), radius: 10, x: 0, y: 5)
                                
                                VStack(spacing: 4) {
                                    Text("🎮")
                                        .font(.system(size: 30))
                                    Text("Arcade")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .fullScreenCover(isPresented: $showArcadeGames) {
            OfflineArcadeGamesView()
        }
    }
    
    var shouldShowArcadeButton: Bool {
        // Only show arcade button when user is offline
        guard !networkMonitor.isConnected else {
            return false
        }
        
        switch authVM.authState {
        case .parentDashboard, .childHome, .childDetail:
            return true
        default:
            return false
        }
    }

    @ViewBuilder
    private var content: some View {
        switch authVM.authState {
        
        case .splash:
            EmptyView()
        
        case .welcome:
            WelcomeScreen(
                onGetStartedClick: { authVM.authState = .parentSignUp },
                onChildLoginClick: { authVM.authState = .childQRLogin }
            )

        case .parentSignUp:
            ParentSignUpScreen(
                onSignUpClick: { fullName, email, password, confirmPassword in
                    authVM.signUp(fullName: fullName, email: email, password: password, confirmPassword: confirmPassword)
                },
                onSignInClick: { authVM.authState = .parentSignIn },
                isLoading: authVM.isLoading,
                errorMessage: authVM.errorMessage
            )

        case .parentSignIn:
            ParentSignInScreen(
                onSignInClick: { email, password in
                    authVM.signIn(email: email, password: password, rememberMe: true)
                },
                onSignUpClick: { authVM.authState = .parentSignUp },
                onForgotPasswordClick: { authVM.authState = .forgotPassword },
                isLoading: authVM.isLoading,
                errorMessage: authVM.errorMessage
            )

        case .forgotPassword:
            ForgotPasswordScreen()
                .environmentObject(authVM)
            
            
        case .resetPassword(let token):
            ResetPasswordScreen(token: token)
                .environmentObject(authVM)
            
            
        case .parentDashboard:
            if let parent = authVM.currentUser {
                ParentTabView(parent: parent)
                    .environmentObject(authVM)
            } else {
                EmptyView()
            }
            
        case .parentProfile:
            ParentProfileScreen()
                .environmentObject(authVM)
        
        case .editParentProfile:
            EditParentProfileScreen()
                .environmentObject(authVM)

        case .addChild:
            AddChildScreen(onBackClick: {
                authVM.authState = .parentDashboard
            })
            .environmentObject(authVM)

        case .childDetail(let child):
            EnhancedChildDetailScreen(
                child: child,
                onBackClick: { authVM.authState = .parentDashboard },
                onAssignQuizClick: {
                    // Navigate to quiz creation if needed, or handle in view
                },
                onGenerateQRClick: { authVM.showQRCode(for: child) },
                onEditClick: { authVM.authState = .editChildProfile(child) },
                onCreatePuzzleClick: {
                    // Navigate to puzzle creation if needed
                }
            )
            .environmentObject(authVM)
        
        case .editChildProfile(let child):
            EditChildProfileScreen(
                child: child,
                onBackClick: {
                    authVM.authState = .childDetail(child)
                }
            )
            .environmentObject(authVM)

        case .childQRLogin:
            ChildQRLoginScreen()
                .environmentObject(authVM)

        case .childHome(let child):
            NavigationStack {
                ChildDashboardScreen(child: child)
                    .environmentObject(authVM)
            }
            .onAppear { authVM.selectedChild = child }

        case .qrCodeDisplay(let child):
            QRScreenParentView(child: child)
                .environmentObject(authVM)
                .onAppear { authVM.selectedChild = child }
        }
    }
}
