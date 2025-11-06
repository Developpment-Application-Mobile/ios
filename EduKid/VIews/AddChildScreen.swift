//
//  AddChildScreen.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//

import Foundation
import SwiftUI

struct AddChildScreen: View {
    @State private var name = ""
    @State private var age = ""
    @State private var selectedEmoji = "boy"
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthViewModel

    let emojis = ["boy", "girl", "child", "child2", "child3"]

    var onSave: (String, Int, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Informations") {
                    TextField("Nom", text: $name)
                    TextField("Âge", text: $age)
                        .keyboardType(.numberPad)
                }

                Section("Avatar") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5)) {
                        ForEach(emojis, id: \.self) { emoji in
                            Button {
                                selectedEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.title)
                                    .padding(8)
                                    .background(selectedEmoji == emoji ? Color.purple.opacity(0.3) : Color.clear)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
            }
            .navigationTitle("Nouvel Enfant")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sauvegarder") {
                        if let ageInt = Int(age), !name.isEmpty {
                            onSave(name, ageInt, selectedEmoji)
                        }
                    }
                    .disabled(name.isEmpty || age.isEmpty)
                }
            }
        }
    }
}
