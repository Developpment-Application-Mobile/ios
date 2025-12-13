import SwiftUI

struct QuestListView: View {
    let childId: String
    let parentId: String
    @Environment(\.dismiss) var dismiss
    
    @State private var quests: [Quest] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var claimingQuestId: String?
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            HStack {
                Text("Mes Quêtes")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                // Refetch button
                Button(action: { loadQuests() }) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.title)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal)
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
            } else if quests.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.5))
                    Text("Aucune quête active")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 20) {
                    ForEach(quests.sorted(by: { $0.status == .completed && $1.status != .completed })) { quest in
                        QuestCard(quest: quest, isClaiming: claimingQuestId == quest.id) {
                            claimReward(for: quest)
                        }
                    }
                }
            }
        }
        .onAppear {
            loadQuests()
        }
        .alert(item: Binding<AlertItem?>(
            get: { errorMessage.map { AlertItem(message: $0) } },
            set: { _ in errorMessage = nil }
        )) { item in
            Alert(title: Text("Info"), message: Text(item.message), dismissButton: .default(Text("OK")))
        }
    }
    
    private func loadQuests() {
        isLoading = true
        Task {
            do {
                quests = try await QuestService.shared.getQuests(parentId: parentId, kidId: childId)
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func claimReward(for quest: Quest) {
        guard quest.status == .completed else { return }
        
        claimingQuestId = quest.id
        Task {
            do {
                _ = try await QuestService.shared.claimQuestReward(parentId: parentId, kidId: childId, questId: quest.id)
                // Refresh list to get new quest
                try await Task.sleep(nanoseconds: 500_000_000) // Small delay for effect
                await loadQuests()
                claimingQuestId = nil
                // Success feedback (sound removed for now)
            } catch {
                claimingQuestId = nil
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct QuestCard: View {
    let quest: Quest
    let isClaiming: Bool
    let onClaim: () -> Void
    @State private var animateProgress = false
    
    var progressPercent: Double {
        if quest.target == 0 { return 0 }
        return Double(quest.progress) / Double(quest.target)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title & Reward
            HStack(alignment: .top, spacing: 12) {
                // Quest Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.686, green: 0.494, blue: 0.906),
                                    Color(red: 0.153, green: 0.125, blue: 0.322)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: quest.status == .completed ? "checkmark.circle.fill" : "map.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                .shadow(color: Color(red: 0.686, green: 0.494, blue: 0.906).opacity(0.4), radius: 8, x: 0, y: 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(quest.title ?? quest.type.displayName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "1F2937"))
                        .lineLimit(2)
                    
                    if let description = quest.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Reward Badge
                VStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)
                    Text("+\(quest.reward)")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.yellow.opacity(0.15))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 2)
                )
            }
            
            // Progress Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progression")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(quest.progress) / \(quest.target)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.686, green: 0.494, blue: 0.906))
                }
                
                // Enhanced Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Background
                        Capsule()
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 14)
                        
                        // Progress Fill with Gradient
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.686, green: 0.494, blue: 0.906),
                                        Color(red: 0.153, green: 0.125, blue: 0.322)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: animateProgress ? max(0, min(geo.size.width, geo.size.width * progressPercent)) : 0,
                                height: 14
                            )
                            .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animateProgress)
                        
                        // Shimmer Effect for Active Quests
                        if quest.status == .active {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0),
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 50, height: 14)
                                .offset(x: animateProgress ? geo.size.width : -50)
                                .animation(
                                    Animation.linear(duration: 1.5)
                                        .repeatForever(autoreverses: false),
                                    value: animateProgress
                                )
                        }
                    }
                }
                .frame(height: 14)
            }
            
            // Action Button
            if quest.status == .completed {
                Button(action: onClaim) {
                    HStack(spacing: 8) {
                        if isClaiming {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 16))
                            Text("Réclamer la récompense !")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.green,
                                Color.green.opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .disabled(isClaiming)
            } else if quest.status == .claimed {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("Récompense réclamée")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    quest.status == .completed ? Color.green.opacity(0.5) : Color.clear,
                    lineWidth: 2
                )
        )
        .onAppear {
            animateProgress = true
        }
    }
}
