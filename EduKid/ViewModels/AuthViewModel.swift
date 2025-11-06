
// AuthViewModel.swift
import Foundation
import Combine

class AuthViewModel: ObservableObject {
    // MARK: - États de Navigation
    enum AuthState: Equatable {
        case splash
        case welcome
        case parentSignUp
        case parentSignIn
        case parentDashboard
        case addChild
        case childDetail(Child)
        case childQRLogin
        case childHome(Child)
        case qrCodeDisplay(Child)

        static func == (lhs: AuthState, rhs: AuthState) -> Bool {
            switch (lhs, rhs) {
            case (.splash, .splash), (.welcome, .welcome),
                 (.parentSignUp, .parentSignUp), (.parentSignIn, .parentSignIn),
                 (.parentDashboard, .parentDashboard), (.addChild, .addChild),
                 (.childQRLogin, .childQRLogin):
                return true

            case let (.childDetail(c1), .childDetail(c2)),
                 let (.childHome(c1), .childHome(c2)),
                 let (.qrCodeDisplay(c1), .qrCodeDisplay(c2)):
                return c1.id == c2.id

            default:
                return false
            }
        }
    }
    @Published var authState: AuthState = .splash
    @Published var currentUser: Parent?
    @Published var selectedChild: Child?
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Simuler un chargement
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.authState = .welcome
        }
    }

    // MARK: - Auth Actions
    func signUp(fullName: String, email: String, password: String, confirmPassword: String) {
        guard password == confirmPassword else {
            errorMessage = "Les mots de passe ne correspondent pas"
            return
        }
        // TODO: API call
        let parent = Parent(
            name: fullName,
            email: email,
            children: [],
            totalScore: 0,
            isActive: true
        )
        currentUser = parent
        authState = .parentDashboard
    }

    func signIn(email: String, password: String) {
        // TODO: API call
        let mockChild = Child(
            name: "Emma",
            age: 8,
            level: "3",
            avatarEmoji: "girl",
            Score: 600,
            quizzes: ["q1", "q2"],
            totalPoints: 602,
            connectionToken: UUID().uuidString
        )
        let parent = Parent(
            name: "John Doe",
            email: email,
            children: [mockChild],
            totalScore: 602,
            isActive: true
        )
        currentUser = parent
        selectedChild = mockChild
        authState = .parentDashboard
    }

    func signOut() {
        currentUser = nil
        selectedChild = nil
        authState = .welcome
    }

    // MARK: - Enfant
    func addChild(name: String, age: Int, avatarEmoji: String) {
        let level = "\(age - 3)"
        let newChild = Child(
            name: name,
            age: age,
            level: level,
            avatarEmoji: avatarEmoji,
            Score: 0,
            quizzes: [],
            totalPoints: 0,
            connectionToken: UUID().uuidString
        )
        currentUser?.children.append(newChild)
        selectedChild = newChild
        authState = .parentDashboard
    }

    func selectChild(_ child: Child) {
        selectedChild = child
        authState = .childDetail(child)
    }

    // MARK: - QR Code
    func showQRCode(for child: Child) {
        selectedChild = child
        authState = .qrCodeDisplay(child)
    }

    func handleQRScan(token: String) {
        guard let child = currentUser?.children.first(where: { $0.connectionToken == token }) else {
            errorMessage = "QR Code invalide"
            return
        }
        selectedChild = child
        authState = .childHome(child)
    }

    // MARK: - Récompenses
    func addReward(to child: Child, name: String, cost: Int) {
        guard let childIndex = currentUser?.children.firstIndex(where: { $0.id == child.id }) else { return }
        let reward = Reward(name: name, cost: cost)
        currentUser?.children[childIndex].rewards.append(reward)
    }

    func updateReward(_ reward: Reward, name: String, cost: Int) {
        guard let child = selectedChild,
              let childIndex = currentUser?.children.firstIndex(where: { $0.id == child.id }),
              let rewardIndex = currentUser?.children[childIndex].rewards.firstIndex(where: { $0.id == reward.id }) else { return }
        currentUser?.children[childIndex].rewards[rewardIndex] = Reward(id: reward.id, name: name, cost: cost, isClaimed: reward.isClaimed)
    }

    func deleteReward(_ reward: Reward) {
        guard let child = selectedChild,
              let childIndex = currentUser?.children.firstIndex(where: { $0.id == child.id }) else { return }
        currentUser?.children[childIndex].rewards.removeAll { $0.id == reward.id }
    }

    func claimReward(_ reward: Reward) {
        guard let child = selectedChild,
              child.totalPoints >= reward.cost else { return }
        // Déduire les points + marquer comme réclamée
    }
}
