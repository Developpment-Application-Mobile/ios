import SwiftUI

struct GiftManagementView: View {
    let childId: String
    let parentId: String
    @Environment(\.dismiss) var dismiss
    @State private var gifts: [Gift] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
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
                // Header
                HStack(spacing: 16) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Text("Gift Shop")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { showAddGift = true }) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer().frame(height: 30)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else if gifts.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "gift.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.5))
                        Text("No rewards yet")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                        Button(action: { showAddGift = true }) {
                            Text("Add Reward")
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322))
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
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                            ForEach(gifts) { gift in
                                GiftCard(gift: gift) {
                                    deleteGift(gift)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                }
            }
        }
        .onAppear {
            loadGifts()
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
    
    private func loadGifts() {
        isLoading = true
        Task {
            do {
                gifts = try await GiftService.shared.getGifts(parentId: parentId, kidId: childId)
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
                await loadGifts() // Reload list
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
    
    var body: some View {
        VStack(spacing: 10) {
            // Delete button
            HStack {
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red.opacity(0.8))
                }
            }
            .padding([.top, .trailing], 8)
            
            // Icon extraction (assuming title contains emoji)
            let icon = gift.title.unicodeScalars.first(where: { $0.properties.isEmoji })
            Text(String(icon ?? "🎁"))
                .font(.system(size: 50))
                .padding(.vertical, 5)
            
            Text(gift.title)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322))
                .padding(.horizontal, 8)
            
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                Text("\(gift.cost)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.yellow.opacity(0.15))
            )
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
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
