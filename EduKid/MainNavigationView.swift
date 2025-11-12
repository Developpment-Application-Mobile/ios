//
//  MainNavigationView.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//

// MainNavigationView.swift
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
                onForgotPasswordClick: { },
                isLoading: authVM.isLoading,
                errorMessage: authVM.errorMessage
            )

        case .parentDashboard:
            if let parent = authVM.currentUser {
                ParentDashboardScreen(
                    parent: parent,
                    onAddChildClick: { authVM.authState = .addChild },
                    onChildClick: authVM.selectChild,
                    onLogoutClick: authVM.signOut,
                    onProfileClick: { authVM.authState = .parentProfile }
                )
            } else {
                EmptyView()
            }
            
        case .parentProfile:
            ParentProfileScreen()
                .environmentObject(authVM)

        case .addChild:
            AddChildScreen { name, age, emoji in
                authVM.addChild(name: name, age: age, avatarEmoji: emoji)
            }

        case .childDetail(let child):
            ChildDetailScreen(
                child: child,
                quizResults: mockQuizResults(for: child),
                onBackClick: { authVM.authState = .parentDashboard },
                onAssignQuizClick: { },
                onGenerateQRClick: { authVM.showQRCode(for: child) }
            )

        case .childQRLogin:
            ChildQRLoginScreen(
                onQRScanned: authVM.handleQRScan,
                onBackClick: { authVM.authState = .welcome }
            )

        case .childHome(let child):
            HomeScreen()
                .environmentObject(authVM)
                .onAppear { authVM.selectedChild = child }

        case .qrCodeDisplay(let child):
            QRScreenParentView(child: child)
                .onAppear { authVM.selectedChild = child }

        case .splash:
            EmptyView()
        }
    }

    private func mockQuizResults(for child: Child) -> [QuizResult] {
        [
            QuizResult(id: "1", quizName: "Math Basics", category: "Math", score: 90, totalQuestions: 10, date: "Nov 4", duration: "8 min"),
            QuizResult(id: "2", quizName: "Animals", category: "Science", score: 75, totalQuestions: 15, date: "Nov 3", duration: "12 min")
        ]
    }
}
