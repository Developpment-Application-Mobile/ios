import SwiftUI

struct MainNavigationView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        content
            .animation(.easeInOut, value: authVM.authState)
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
                onSignInClick: { email, password, rememberMe in
                    authVM.signIn(email: email, password: password, rememberMe: rememberMe)
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
            ChildDetailScreen(
                child: child,
                onBackClick: { authVM.authState = .parentDashboard },
                onAssignQuizClick: { },
                onGenerateQRClick: { authVM.showQRCode(for: child) },
                onEditClick: { authVM.authState = .editChildProfile(child) }
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
