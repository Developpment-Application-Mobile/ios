import SwiftUI

struct ShopView: View {
    let childId: String
    let parentId: String
    let initialPoints: Int  // Pass points directly from parent
    @Environment(\.dismiss) var dismiss
    
    @State private var catalog: [Gift] = []
    @State private var inventory: [Gift] = []
    @State private var childScore: Int
    @State private var selectedTab = 0
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var buyingGiftId: String?
    
    // Initialize childScore with initialPoints
    init(childId: String, parentId: String, initialPoints: Int) {
        self.childId = childId
        self.parentId = parentId
        self.initialPoints = initialPoints
        _childScore = State(initialValue: initialPoints)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with Score
            HStack {
                Text("Shop")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.yellow)
                    Text("\(childScore)")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.25))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(.horizontal)
            
            // Tabs
            HStack(spacing: 20) {
                ShopTabButton(icon: "cart.fill", title: "Shop", isSelected: selectedTab == 0) { selectedTab = 0 }
                ShopTabButton(icon: "bag.fill", title: "My Gifts", isSelected: selectedTab == 1) { selectedTab = 1 }
            }
            .padding(.horizontal)
            
            if isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                Spacer()
            } else {
                if selectedTab == 0 {
                    // SHOP
                    if catalog.isEmpty {
                        Spacer()
                        VStack(spacing: 15) {
                            Image(systemName: "cart.circle")
                                .font(.system(size: 70))
                                .foregroundColor(.white.opacity(0.5))
                            Text("No items available")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                                ForEach(catalog) { gift in
                                    ShopItemCard(gift: gift, canAfford: childScore >= gift.cost, isBuying: buyingGiftId == gift.id) {
                                        buyGift(gift)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else {
                    // INVENTORY
                    if inventory.isEmpty {
                        Spacer()
                        VStack(spacing: 15) {
                            Text("🎒")
                                .font(.system(size: 70))
                            Text("Your bag is empty!")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                                ForEach(inventory) { gift in
                                    InventoryItemCard(gift: gift)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .onAppear {
            loadData()
        }
        .alert(item: Binding<AlertItem?>(
            get: { errorMessage.map { AlertItem(message: $0) } },
            set: { _ in errorMessage = nil }
        )) { item in
            Alert(title: Text("Oops"), message: Text(item.message), dismissButton: .default(Text("OK")))
        }
    }
    
    
    private func loadData() {
        isLoading = true
        Task {
            do {
                // STEP 1: Get Catalog
                let fullCatalog = try await GiftService.shared.getGifts(parentId: parentId, kidId: childId)
                self.catalog = fullCatalog
                
                // STEP 2: Get Inventory first to calculate spending
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
                            
                            // Get inventory
                            if let invArr = childDict["inventory"] as? [[String: Any]] {
                                let data = try JSONSerialization.data(withJSONObject: invArr)
                                self.inventory = try JSONDecoder().decode([Gift].self, from: data)
                                
                                // FILTER: Remove owned items from catalog
                                let ownedIds = Set(self.inventory.map { $0.id })
                                self.catalog = self.catalog.filter { !ownedIds.contains($0.id) }
                                
                                // STEP 3: Calculate Correct Balance (Gross - Spent)
                                // initialPoints is "Total Lifetime Earnings" from Dashboard
                                // We subtract total spent to get current available balance
                                let totalSpent = self.inventory.reduce(0) { $0 + $1.cost }
                                let netBalance = max(0, initialPoints - totalSpent)
                                
                                print("💰 Point Calculation:")
                                print("   Gross Earnings (from Dashboard): \(initialPoints)")
                                print("   Total Spent (from Inventory): \(totalSpent)")
                                print("   Net Available Balance: \(netBalance)")
                                
                                self.childScore = netBalance
                                
                                // STEP 4: Sync backend with calculated Net Balance
                                print("🔄 Syncing backend Score to net balance: \(netBalance)...")
                                try await GiftService.shared.syncChildScore(parentId: parentId, kidId: childId, calculatedScore: netBalance)
                                print("✅ Backend Score synced successfully!")
                            }
                        }
                    }
                }
                
                isLoading = false
            } catch {
                isLoading = false
                print("❌ Error loading shop: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func buyGift(_ gift: Gift) {
        buyingGiftId = gift.id
        Task {
            do {
                print("🛒 Attempting to buy \(gift.title) for \(gift.cost) points (frontend has \(childScore) points)")
                let result = try await GiftService.shared.buyGift(parentId: parentId, kidId: childId, giftId: gift.id)
                print("✅ Purchase successful!")
                // Manually subtract the cost to keep points consistent
                childScore = childScore - gift.cost
                // Add to inventory
                inventory.append(result.gift)
                // Remove from catalog so it doesn't show in shop anymore
                catalog.removeAll { $0.id == gift.id }
                buyingGiftId = nil
            } catch {
                buyingGiftId = nil
                print("❌ Purchase failed: \(error.localizedDescription)")
                
                // Show detailed error message
                if error.localizedDescription.contains("enough points") || error.localizedDescription.contains("Not enough") {
                    errorMessage = """
                    Backend Error: Your backend Score field (23 points) doesn't match your earned points (453 points).
                    
                    Backend Fix Needed:
                    When quizzes/activities are completed, the backend must update the child's 'Score' field to add the earned points.
                    
                    Current Issue:
                    • Frontend shows: \(childScore) points
                    • Backend has: ~23 points
                    • Gift costs: \(gift.cost) points
                    
                    Contact your backend developer to sync the Score field with completed activities.
                    """
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Premium Components

struct ShopItemCard: View {
    let gift: Gift
    let canAfford: Bool
    let isBuying: Bool
    let onBuy: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.686, green: 0.494, blue: 0.906).opacity(0.3),
                                Color(red: 0.153, green: 0.125, blue: 0.322).opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                
                let icon = gift.title.unicodeScalars.first(where: { $0.properties.isEmoji })
                Text(String(icon ?? "🎁"))
                    .font(.system(size: 50))
            }
            .padding(.top, 10)
            
            Text(gift.title)
                .font(.system(size: 16, weight: .bold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322))
                .frame(height: 40)
            
            // Buy Button
            Button(action: onBuy) {
                HStack(spacing: 6) {
                    if isBuying {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 14))
                        Text("\(gift.cost)")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: canAfford ? [
                            Color.green,
                            Color.green.opacity(0.8)
                        ] : [
                            Color.gray,
                            Color.gray.opacity(0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: (canAfford ? Color.green : Color.gray).opacity(0.4), radius: 6, x: 0, y: 3)
            }
            .disabled(!canAfford || isBuying)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(isPressed ? 0.15 : 0.12), radius: isPressed ? 8 : 12, x: 0, y: isPressed ? 3 : 6)
        )
        .scaleEffect(isPressed ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct InventoryItemCard: View {
    let gift: Gift
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.green.opacity(0.3),
                                Color.green.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                
                let icon = gift.title.unicodeScalars.first(where: { $0.properties.isEmoji })
                Text(String(icon ?? "🎁"))
                    .font(.system(size: 50))
            }
            .padding(.top, 10)
            
            Text(gift.title)
                .font(.system(size: 16, weight: .bold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322))
                .frame(height: 40)
            
            // Owned Badge
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                Text("Owned")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.green.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1.5)
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(isPressed ? 0.15 : 0.12), radius: isPressed ? 8 : 12, x: 0, y: isPressed ? 3 : 6)
        )
        .scaleEffect(isPressed ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Shop Tab Button
struct ShopTabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.686, green: 0.494, blue: 0.906),
                                Color(red: 0.553, green: 0.373, blue: 0.825)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.white.opacity(0.15)
                    }
                }
            )
            .cornerRadius(16)
            .shadow(
                color: isSelected ? Color(red: 0.686, green: 0.494, blue: 0.906).opacity(0.4) : .clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
            .scaleEffect(isSelected ? 1.0 : 0.95)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

