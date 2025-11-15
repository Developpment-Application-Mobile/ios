//
//  EditChildProfileScreen.swift
//  EduKid
//
//  Created by mac on 15/11/2025.
//
import SwiftUI

struct EditChildProfileScreen: View {
    let child: Child
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var age: String
    @State private var selectedAvatarIndex: Int
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    // 42 avatars locaux
    private let avatars: [String] = (1...42).map { "avatar_\($0)" }
    
    init(child: Child) {
        self.child = child
        _name = State(initialValue: child.name)
        _age = State(initialValue: "\(child.age)")
        
        // Find the index of the current avatar
        let avatarList = (1...42).map { "avatar_\($0)" }
        if let index = avatarList.firstIndex(of: child.avatarEmoji) {
            _selectedAvatarIndex = State(initialValue: index)
        } else {
            _selectedAvatarIndex = State(initialValue: 0)
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(hex: "AF7EE7").opacity(0.6),
                    Color(hex: "272052")
                ]),
                center: .init(x: 0.15, y: 0.15),
                startRadius: 50,
                endRadius: 600
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Edit Child Profile")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text("Update \(child.name)'s information")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    // Avatar Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose an Avatar")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6), spacing: 12) {
                            ForEach(avatars.indices, id: \.self) { index in
                                AvatarOption(
                                    imageName: avatars[index],
                                    isSelected: selectedAvatarIndex == index
                                ) {
                                    selectedAvatarIndex = index
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.95))
                        .cornerRadius(16)
                    }
                    
                    // Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Child's Name")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        TextField("Enter child's name", text: $name)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                    }
                    
                    // Age Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Age")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        TextField("Enter age (1–18)", text: $age)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                            .onChange(of: age) { oldValue, newValue in
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if let num = Int(filtered), num >= 1 && num <= 18 {
                                    age = String(num)
                                } else if filtered.isEmpty {
                                    age = ""
                                } else {
                                    age = String(filtered.prefix(2))
                                }
                            }
                    }
                    
                    // Success/Error Messages
                    if let successMessage = successMessage {
                        Text(successMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.8))
                            .cornerRadius(12)
                    }
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(12)
                    }
                    
                    // Save Button
                    Button(action: saveChanges) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                    .scaleEffect(0.8)
                            }
                            Text(isLoading ? "SAVING..." : "SAVE CHANGES")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.white)
                        .foregroundColor(Color(hex: "2E2E2E"))
                        .cornerRadius(30)
                    }
                    .disabled(isLoading || name.trimmingCharacters(in: .whitespaces).isEmpty || age.isEmpty)
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
    }
    
    private func saveChanges() {
        guard let ageInt = Int(age),
              !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a valid name and age (1–18)."
            return
        }
        
        errorMessage = nil
        successMessage = nil
        isLoading = true
        
        let avatarName = avatars[selectedAvatarIndex]
        
        Task {
            do {
                try await authVM.updateChild(
                    childId: child.id,
                    name: name,
                    age: ageInt,
                    avatarEmoji: avatarName
                )
                
                await MainActor.run {
                    isLoading = false
                    successMessage = "Profile updated successfully!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
