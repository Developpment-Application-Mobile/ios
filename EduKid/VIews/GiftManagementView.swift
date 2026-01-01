import SwiftUI

struct GiftManagementView: View {
    let childId: String
    let parentId: String
    @Environment(\.dismiss) var dismiss
    @State private var gifts: [Gift] = []
    @State private var inventory: [Gift] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var childScore: Int = 0
    @State private var showScoreAnimation = false
    @State private var selectedTab = 0 // 0 = Shop, 1 = Inventory
    
    // Add Gift Sheet State
    @State private var showAddGift = false
    
    // Predefined Icons
    let predefinedIcons = [
        "🍦", "⚽️", "🎮", "🎸", "🚲", "🧸", "📚", "🎨", "🧩", "🛹", "🍩", "🍕", "🍔"
    ]
    
    var body: some View {
        ZStack {
            // Radial Gradient Background (matching app style)
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
            
            VStack(spacing: 0) {
                Spacer().frame(height: 20)
                
                // Child Score Display
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.yellow.opacity(0.3))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Child's Points")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("\(childScore)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.12))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 16)
                
                // Add Reward Button
                Button(action: { showAddGift = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Add Reward")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "272052"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(25)
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                }
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 20)
                
                // Tabs
                HStack(spacing: 12) {
                    TabButton(title: "Available Rewards", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    TabButton(title: "Child's Inventory", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 20)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else if selectedTab == 0 {
                    // Available Rewards Tab
                    if gifts.isEmpty {
                        Spacer()
                        VStack(spacing: 20) {
                            Text("🎁")
                                .font(.system(size: 80))
                            Text("No rewards yet")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                            Button(action: { showAddGift = true }) {
                                Text("Add First Reward")
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(hex: "272052"))
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 14)
                                    .background(Color.white)
                                    .cornerRadius(25)
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            }
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(gifts) { gift in
                                    GiftCard(gift: gift) {
                                        deleteGift(gift)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                        }
                    }
                } else {
                    // Child's Inventory Tab
                    if inventory.isEmpty {
                        Spacer()
                        VStack(spacing: 20) {
                            Text("🎒")
                                .font(.system(size: 80))
                            Text("No purchases yet")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                            Text("Child hasn't bought any rewards")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(inventory) { gift in
                                    InventoryGiftCard(gift: gift)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
        }
        .onAppear {
            loadGifts()
            loadChildScore()
        }
        .refreshable {
            loadGifts()
            loadChildScore()
        }
        .sheet(isPresented: $showAddGift) {
            AddGiftSheet(isPresented: $showAddGift, icons: predefinedIcons) { title, cost in
                createGift(title: title, cost: cost)
            }
        }
        .alert(item: Binding<AlertItem?>(
            get: { errorMessage.map { AlertItem(message: $0) } },
            set: { _ in errorMessage = nil }
        )) { item in
            Alert(title: Text("Error"), message: Text(item.message), dismissButton: .default(Text("OK")))
        }
    }
    
    private func loadChildScore() {
        Task {
            do {
                guard let parentId = AuthService.shared.getParentId() else { return }
                
                // Use centralized calculation service to get TOTAL/GROSS score
                let stats = try await ScoreCalculationService.shared.loadAndCalculateStats(
                    for: childId,
                    parentId: parentId
                )
                
                // Get inventory to calculate NET score (after purchases)
                var inventory: [Gift] = []
                if let token = AuthService.shared.getToken() {
                    let baseURL = "https://preterrestrial-georgann-recappable.ngrok-free.dev"
                    let pUrl = URL(string: "\(baseURL)/parents/\(parentId)")!
                    var req = URLRequest(url: pUrl)
                    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    req.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
                    let (d, _) = try await URLSession.shared.data(for: req)
                    
                    if let json = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                       let childrenArr = json["children"] as? [[String: Any]] {
                        if let childDict = childrenArr.first(where: { ($0["_id"] as? String) == childId || ($0["id"] as? String) == childId }) {
                            if let invArr = childDict["inventory"] as? [[String: Any]] {
                                let data = try JSONSerialization.data(withJSONObject: invArr)
                                inventory = try JSONDecoder().decode([Gift].self, from: data)
                            }
                        }
                    }
                }
                
                // Calculate NET score (gross - spent)
                let netScore = ScoreCalculationService.shared.calculateNetScore(
                    grossScore: stats.totalScore,
                    inventory: inventory
                )
                
                await MainActor.run {
                    // Display NET score (same as child sees)
                    childScore = netScore
                }
            } catch {
                print("Error loading child score: \(error)")
            }
        }
    }
    
    private func loadGifts() {
        isLoading = true
        Task {
            do {
                gifts = try await GiftService.shared.getGifts(parentId: parentId, kidId: childId)
                
                // Also load inventory
                if let token = AuthService.shared.getToken() {
                    let baseURL = "https://preterrestrial-georgann-recappable.ngrok-free.dev"
                    let pUrl = URL(string: "\(baseURL)/parents/\(parentId)")!
                    var req = URLRequest(url: pUrl)
                    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    req.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
                    let (d, _) = try await URLSession.shared.data(for: req)
                    
                    if let json = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                       let childrenArr = json["children"] as? [[String: Any]] {
                        if let childDict = childrenArr.first(where: { ($0["_id"] as? String) == childId || ($0["id"] as? String) == childId }) {
                            if let invArr = childDict["inventory"] as? [[String: Any]] {
                                let data = try JSONSerialization.data(withJSONObject: invArr)
                                inventory = try JSONDecoder().decode([Gift].self, from: data)
                            }
                        }
                    }
                }
                
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func createGift(title: String, cost: Int) {
        isLoading = true
        Task {
            do {
                _ = try await GiftService.shared.createGift(parentId: parentId, kidId: childId, title: title, cost: cost)
                await loadGifts() 
                
                // Trigger score animation
                await MainActor.run {
                    showScoreAnimation = true
                }
                
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                await MainActor.run {
                    showScoreAnimation = false
                }
                
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func deleteGift(_ gift: Gift) {
        // Optimistic update
        let originalGifts = gifts
        gifts.removeAll { $0.id == gift.id }
        
        Task {
            do {
                try await GiftService.shared.deleteGift(parentId: parentId, kidId: childId, giftId: gift.id)
            } catch {
                gifts = originalGifts
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Subviews
struct GiftCard: View {
    let gift: Gift
    let onDelete: () -> Void
    
    // Extract icon from title (assuming format: "🎁 Gift Name")
    private var icon: String {
        if let firstChar = gift.title.first, firstChar.isEmoji {
            return String(firstChar)
        }
        return "🎁"
    }
    
    private var displayTitle: String {
        // Remove emoji from title if present
        let title = gift.title
        if let firstChar = title.first, firstChar.isEmoji {
            return String(title.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        return title
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Gift Icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                Text(icon)
                    .font(.system(size: 32))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(displayTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("\(gift.cost) points")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.red.opacity(0.8))
                    .padding(10)
                    .background(Color.red.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.12))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct AddGiftSheet: View {
    @Binding var isPresented: Bool
    let icons: [String]
    let onAdd: (String, Int) -> Void
    
    @State private var selectedIcon = "🍦"
    @State private var name = ""
    @State private var costString = "50"
    
    // Icon to name mapping
    let iconNames: [String: String] = [
        "🍦": "Ice Cream",
        "⚽️": "Soccer Ball",
        "🎮": "Video Game",
        "🎸": "Guitar",
        "🚲": "Bicycle",
        "🧸": "Teddy Bear",
        "📚": "Books",
        "🎨": "Art Set",
        "🧩": "Puzzle",
        "🛹": "Skateboard",
        "🍩": "Donut",
        "🍕": "Pizza",
        "🍔": "Burger"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Radial Gradient Background (matching app style)
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Icon Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose an Icon")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(icons, id: \.self) { icon in
                                        Button(action: {
                                            selectedIcon = icon
                                            // Auto-fill name based on icon
                                            if let defaultName = iconNames[icon] {
                                                name = defaultName
                                            }
                                        }) {
                                            Text(icon)
                                                .font(.system(size: 40))
                                                .frame(width: 70, height: 70)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .fill(selectedIcon == icon ? Color.white : Color.white.opacity(0.3))
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(selectedIcon == icon ? Color(red: 0.686, green: 0.494, blue: 0.906) : Color.clear, lineWidth: 3)
                                                )
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.15))
                        )
                        
                        // Details Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Details")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                TextField("e.g., Ice Cream", text: $name)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Cost (points)")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                TextField("50", text: $costString)
                                    .keyboardType(.numberPad)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.15))
                        )
                        
                        // Add Button
                        Button(action: {
                            if let cost = Int(costString), !name.isEmpty {
                                onAdd("\(selectedIcon) \(name)", cost)
                                isPresented = false
                            }
                        }) {
                            Text("Add Reward")
                                .font(.headline)
                                .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .disabled(name.isEmpty || Int(costString) == nil)
                        .opacity((name.isEmpty || Int(costString) == nil) ? 0.5 : 1.0)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Reward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            // Auto-fill name for default icon
            if let defaultName = iconNames[selectedIcon] {
                name = defaultName
            }
        }
    }
}

struct AlertItem: Identifiable {
    var id: String { message }
    let message: String
}



// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? Color(hex: "272052") : .white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.white : Color.white.opacity(0.15))
                .cornerRadius(20)
        }
    }
}

// MARK: - Inventory Gift Card
struct InventoryGiftCard: View {
    let gift: Gift
    
    // Extract icon from title (assuming format: "🎁 Gift Name")
    private var icon: String {
        if let firstChar = gift.title.first, firstChar.isEmoji {
            return String(firstChar)
        }
        return "🎁"
    }
    
    private var displayTitle: String {
        // Remove emoji from title if present
        let title = gift.title
        if let firstChar = title.first, firstChar.isEmoji {
            return String(title.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        return title
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Gift Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                Text(icon)
                    .font(.system(size: 32))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(displayTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("Purchased")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Cost badge
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    Text("\(gift.cost)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.15))
            .cornerRadius(12)
        }
        .padding(16)
        .background(Color.white.opacity(0.12))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
        )
    }
}
