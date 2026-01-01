//
//  ParentPuzzleViews.swift
//  EduKid
//
//  FIXED: Image upload works, AI image puzzles hidden, custom images display
//

import SwiftUI
import PhotosUI

// MARK: - Parent Puzzle Creation Sheet
struct ParentPuzzleCreationSheet: View {
    let child: Child
    let onCreated: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var selectedType: PuzzleType = .image
    @State private var selectedDifficulty: PuzzleDifficulty = .easy
    @State private var selectedImage: PuzzleImage = .lion
    @State private var customImage: UIImage?
    @State private var showImagePicker = false
    @State private var isCreating = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.153, green: 0.125, blue: 0.322).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Child Info
                        HStack(spacing: 12) {
                            Image(child.avatarEmoji).resizable().scaledToFit().frame(width: 50, height: 50)
                                .background(Color.white.opacity(0.3)).clipShape(Circle())
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Creating puzzle for:").font(.caption).foregroundColor(.white.opacity(0.7))
                                Text(child.name).font(.headline).foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding().background(Color.white.opacity(0.1)).cornerRadius(16)
                        
                        // Puzzle Type Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Puzzle Type").font(.headline).foregroundColor(.white)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(PuzzleType.allCases, id: \.self) { type in
                                    ParentPuzzleTypeButton(type: type, isSelected: selectedType == type) { selectedType = type }
                                }
                            }
                        }
                        .padding().background(Color.white.opacity(0.1)).cornerRadius(16)
                        
                        // Image Selection (for image type)
                        if selectedType == .image {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Choose Image").font(.headline).foregroundColor(.white)
                                
                                // Custom Image Upload Button
                                Button(action: { showImagePicker = true }) {
                                    HStack {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.title3)
                                        Text("Upload Custom Image")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        LinearGradient(
                                            colors: [.purple.opacity(0.7), .blue.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                }
                                
                                if let customImage = customImage {
                                    VStack(spacing: 8) {
                                        Image(uiImage: customImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 150)
                                            .frame(maxWidth: .infinity)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        
                                        HStack {
                                            Text("✓ Custom Image Selected")
                                                .font(.subheadline.bold())
                                                .foregroundColor(.green)
                                            Spacer()
                                            Button("Remove") {
                                                self.customImage = nil
                                            }
                                            .font(.subheadline.bold())
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.red.opacity(0.2))
                                            .cornerRadius(8)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(12)
                                }
                                
                                if customImage == nil {
                                    Text("Or choose a preset:")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                                        ForEach(PuzzleImage.allCases, id: \.self) { image in
                                            ParentImageButton(image: image, isSelected: selectedImage == image && customImage == nil) {
                                                selectedImage = image
                                                customImage = nil
                                            }
                                        }
                                    }
                                }
                            }
                            .padding().background(Color.white.opacity(0.1)).cornerRadius(16)
                        }
                        
                        // Difficulty Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Difficulty").font(.headline).foregroundColor(.white)
                            HStack(spacing: 12) {
                                ForEach(PuzzleDifficulty.allCases, id: \.self) { diff in
                                    ParentDifficultyButton(difficulty: diff, isSelected: selectedDifficulty == diff) { selectedDifficulty = diff }
                                }
                            }
                        }
                        .padding().background(Color.white.opacity(0.1)).cornerRadius(16)
                        
                        // Preview
                        VStack(spacing: 12) {
                            Text("Preview").font(.headline).foregroundColor(.white)
                            ParentPuzzlePreviewView(
                                type: selectedType,
                                difficulty: selectedDifficulty,
                                image: selectedImage,
                                customImage: customImage
                            )
                        }
                        .padding().background(Color.white.opacity(0.1)).cornerRadius(16)
                        
                        // Create Button
                        Button(action: createPuzzle) {
                            HStack {
                                if isCreating { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.153, green: 0.125, blue: 0.322))) }
                                else { Image(systemName: "sparkles") }
                                Text(isCreating ? "Creating..." : "Create Puzzle").font(.headline)
                            }
                            .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322))
                            .frame(maxWidth: .infinity).frame(height: 56).background(Color.white).cornerRadius(16)
                        }
                        .disabled(isCreating)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Create Puzzle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $customImage)
            }
        }
    }
    
    private func createPuzzle() {
        isCreating = true
        let _ = LocalPuzzleManager.shared.generateLocalPuzzle(
            for: child,
            type: selectedType,
            difficulty: selectedDifficulty,
            puzzleImage: customImage != nil ? nil : selectedImage,
            customImage: customImage
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isCreating = false
            onCreated()
            dismiss()
        }
    }
}

// MARK: - Image Picker (PHPicker for better simulator support)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

// MARK: - Parent Puzzle Type Button
struct ParentPuzzleTypeButton: View {
    let type: PuzzleType, isSelected: Bool, action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon).font(.title2)
                Text(type.displayName).font(.caption.bold())
            }
            .foregroundColor(isSelected ? .white : type.color)
            .frame(maxWidth: .infinity).frame(height: 70)
            .background(isSelected ? type.color : type.color.opacity(0.2)).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.white : Color.clear, lineWidth: 2))
        }
    }
}

// MARK: - Parent Image Button
struct ParentImageButton: View {
    let image: PuzzleImage, isSelected: Bool, action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(image.backgroundColor).frame(height: 70)
                Text(image.emoji).font(.system(size: 36))
                if isSelected {
                    RoundedRectangle(cornerRadius: 12).stroke(Color.yellow, lineWidth: 3)
                    Circle().fill(Color.yellow).frame(width: 20, height: 20)
                        .overlay(Image(systemName: "checkmark").font(.caption.bold()).foregroundColor(.black)).offset(x: 25, y: -25)
                }
            }
        }
    }
}

// MARK: - Parent Difficulty Button
struct ParentDifficultyButton: View {
    let difficulty: PuzzleDifficulty, isSelected: Bool, action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(difficulty.displayName).font(.subheadline.bold())
                Text("\(difficulty.gridSize)×\(difficulty.gridSize)").font(.caption)
                Text("\(difficulty.gridSize * difficulty.gridSize) pieces").font(.caption2).opacity(0.7)
            }
            .foregroundColor(isSelected ? .white : difficulty.color)
            .frame(maxWidth: .infinity).frame(height: 70)
            .background(isSelected ? difficulty.color : difficulty.color.opacity(0.2)).cornerRadius(12)
        }
    }
}

// MARK: - Parent Puzzle Preview View
struct ParentPuzzlePreviewView: View {
    let type: PuzzleType
    let difficulty: PuzzleDifficulty
    let image: PuzzleImage
    let customImage: UIImage?
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(type == .image ? (customImage != nil ? Color.gray.opacity(0.3) : image.backgroundColor) : type.color.opacity(0.3))
                .frame(height: 150)
            
            if type == .image {
                ZStack {
                    // Show custom image or emoji
                    if let customImage = customImage {
                        Image(uiImage: customImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Text(image.emoji).font(.system(size: 80))
                    }
                    
                    // Grid overlay
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: difficulty.gridSize), spacing: 2) {
                        ForEach(0..<(difficulty.gridSize * difficulty.gridSize), id: \.self) { _ in
                            Rectangle().stroke(Color.white.opacity(0.6), lineWidth: 2).aspectRatio(1, contentMode: .fit)
                        }
                    }
                    .frame(width: 120, height: 120)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: type.icon).font(.system(size: 40)).foregroundColor(type.color)
                    Text("\(difficulty.gridSize)×\(difficulty.gridSize) grid").font(.caption).foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }
}

// MARK: - Parent Puzzle List Screen - FIXED to filter AI image puzzles
struct ParentPuzzleListScreen: View {
    let child: Child
    @State private var localPuzzles: [LocalPuzzle] = []
    @State private var serverPuzzles: [PuzzleResponse] = []
    @State private var isLoading = false
    @State private var showCreateSheet = false
    @State private var showAutoGenerate = false
    @State private var puzzleToDelete: (id: String, isLocal: Bool)?
    @State private var showDeleteAlert = false
    
    // Show all server puzzles including AI-generated image puzzles
    var displayServerPuzzles: [PuzzleResponse] {
        serverPuzzles
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Create Options Buttons
            HStack(spacing: 12) {
                Button(action: { showAutoGenerate = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "wand.and.stars").font(.title3)
                        Text("Auto Generate").font(.headline)
                    }
                    .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 56)
                    .background(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(16)
                }
                
                Button(action: { showCreateSheet = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3").font(.title3)
                        Text("Custom").font(.headline)
                    }
                    .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322)).frame(maxWidth: .infinity).frame(height: 56)
                    .background(Color.white).cornerRadius(16)
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 16)
            
            // Puzzles List
            if isLoading {
                Spacer()
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                Spacer()
            } else if localPuzzles.isEmpty && displayServerPuzzles.isEmpty {
                EmptyPuzzlesView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(localPuzzles) { puzzle in
                            ParentLocalPuzzleCardWithDelete(puzzle: puzzle, onDelete: {
                                puzzleToDelete = (id: puzzle.id, isLocal: true)
                                showDeleteAlert = true
                            })
                        }
                        
                        ForEach(displayServerPuzzles) { puzzle in
                            ParentServerPuzzleCardWithDelete(puzzle: puzzle, onDelete: {
                                puzzleToDelete = (id: puzzle.id, isLocal: false)
                                showDeleteAlert = true
                            })
                        }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 100)
                }
            }
        }
        .onAppear { loadPuzzles() }
        .sheet(isPresented: $showCreateSheet) {
            ParentPuzzleCreationSheet(child: child) { loadPuzzles() }
        }
        .sheet(isPresented: $showAutoGenerate) {
            AutoGeneratePuzzleSheet(child: child) { loadPuzzles() }
        }
        .alert("Delete Puzzle", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { puzzleToDelete = nil }
            Button("Delete", role: .destructive) {
                if let (id, isLocal) = puzzleToDelete {
                    deletePuzzle(id: id, isLocal: isLocal)
                }
            }
        } message: {
            Text("Are you sure you want to delete this puzzle? This cannot be undone.")
        }
    }
    
    private func loadPuzzles() {
        isLoading = true
        localPuzzles = LocalPuzzleManager.shared.getAllPuzzles(for: child.id)
        
        Task {
            do {
                guard let parentId = AuthService.shared.getParentId() else { return }
                let fetched = try await PuzzleService.shared.getPuzzles(parentId: parentId, kidId: child.id)
                await MainActor.run {
                    // Check if any puzzle has a date
                    let hasAnyDates = fetched.contains { $0.createdAt != nil }
                    
                    if hasAnyDates {
                        // Sort by createdAt descending (newest first) - handle nil dates
                        serverPuzzles = fetched.sorted { puzzle1, puzzle2 in
                            if let date1 = puzzle1.createdAt, let date2 = puzzle2.createdAt {
                                return date1 > date2
                            }
                            if puzzle1.createdAt != nil { return true }
                            if puzzle2.createdAt != nil { return false }
                            return false
                        }
                    } else {
                        // If no dates, reverse the array (assuming API returns oldest first)
                        serverPuzzles = Array(fetched.reversed())
                    }
                    isLoading = false 
                }
            } catch {
                print("Error loading server puzzles: \(error)")
                await MainActor.run { isLoading = false }
            }
        }
    }
    
    private func deletePuzzle(id: String, isLocal: Bool) {
        if isLocal {
            LocalPuzzleManager.shared.deletePuzzle(id: id, childId: child.id)
            loadPuzzles()
        } else {
            Task {
                do {
                    guard let parentId = AuthService.shared.getParentId() else { return }
                    print("🗑️ Attempting to delete puzzle: \(id)")
                    try await PuzzleService.shared.deletePuzzle(parentId: parentId, kidId: child.id, puzzleId: id)
                    print("✅ Puzzle deleted successfully")
                    await MainActor.run { loadPuzzles() }
                } catch {
                    print("❌ Failed to delete puzzle: \(error)")
                }
            }
        }
        puzzleToDelete = nil
    }
}

// MARK: - Auto Generate Sheet
struct AutoGeneratePuzzleSheet: View {
    let child: Child
    let onGenerated: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.153, green: 0.125, blue: 0.322).ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    ZStack {
                        Circle().fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 120, height: 120)
                        Image(systemName: "wand.and.stars").font(.system(size: 50)).foregroundColor(.white)
                    }
                    
                    VStack(spacing: 12) {
                        Text("Smart Puzzle Generator").font(.title.bold()).foregroundColor(.white)
                        Text("AI will create the perfect puzzle for \(child.name) based on their skill level")
                            .font(.body).foregroundColor(.white.opacity(0.8)).multilineTextAlignment(.center).padding(.horizontal, 40)
                    }
                    
                    Spacer()
                    
                    Button(action: generatePuzzle) {
                        HStack {
                            if isGenerating { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.153, green: 0.125, blue: 0.322))) }
                            else { Image(systemName: "sparkles") }
                            Text(isGenerating ? "Generating..." : "Generate Puzzle").font(.headline)
                        }
                        .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322))
                        .frame(maxWidth: .infinity).frame(height: 56).background(Color.white).cornerRadius(16)
                    }
                    .disabled(isGenerating).padding(.horizontal, 40).padding(.bottom, 40)
                }
            }
            .navigationTitle("Auto Generate").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.white)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Failed to generate puzzle")
            }
        }
    }
    
    private func generatePuzzle() {
        isGenerating = true
        Task {
            do {
                guard let parentId = AuthService.shared.getParentId() else { throw PuzzleError.noToken }
                _ = try await PuzzleService.shared.generateAdaptivePuzzle(parentId: parentId, kidId: child.id)
                await MainActor.run { isGenerating = false; onGenerated(); dismiss() }
            } catch {
                await MainActor.run { isGenerating = false; errorMessage = error.localizedDescription; showError = true }
            }
        }
    }
}

// MARK: - Parent Local Puzzle Card With Delete - FIXED to show custom image
struct ParentLocalPuzzleCardWithDelete: View {
    let puzzle: LocalPuzzle
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon/Image
            ZStack {
                Circle()
                    .fill(puzzle.customImagePath != nil ? Color.gray.opacity(0.3) : puzzle.puzzleImage.backgroundColor.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                if let imagePath = puzzle.customImagePath,
                   let customImage = LocalPuzzleManager.shared.loadCustomImage(path: imagePath) {
                    Image(uiImage: customImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                } else {
                    Text(puzzle.puzzleImage.emoji)
                        .font(.system(size: 30))
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(puzzle.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text("\(puzzle.difficulty.displayName) • \(puzzle.gridSize)×\(puzzle.gridSize)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 8) {
                    Label("\(puzzle.gridSize * puzzle.gridSize) pieces", systemImage: "puzzlepiece.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Status/Score
            if puzzle.isCompleted {
                VStack(spacing: 2) {
                    Text("\(puzzle.score)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                    Text("Pending")
                        .font(.caption2.bold())
                        .foregroundColor(.orange)
                }
            }
            
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

// MARK: - Parent Server Puzzle Card With Delete
struct ParentServerPuzzleCardWithDelete: View {
    let puzzle: PuzzleResponse
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon/Image
            ZStack {
                Circle()
                    .fill(puzzle.puzzleType.color.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                // Show image preview for image-type puzzles
                if puzzle.type.lowercased() == "image", 
                   let imageUrl = puzzle.imageUrl,
                   let url = URL(string: imageUrl) {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } placeholder: {
                        Image(systemName: puzzle.puzzleType.icon)
                            .font(.title2)
                            .foregroundColor(puzzle.puzzleType.color)
                    }
                } else {
                    Image(systemName: puzzle.puzzleType.icon)
                        .font(.title2)
                        .foregroundColor(puzzle.puzzleType.color)
                }
                
                // AI badge for adaptive puzzles
                if puzzle.title.contains("IMAGE PUZZLE") {
                    VStack {
                        HStack {
                            Spacer()
                            Text("AI")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.purple)
                                .cornerRadius(4)
                        }
                        Spacer()
                    }
                    .frame(width: 60, height: 60)
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(puzzle.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text("\(puzzle.difficulty.capitalized) • \(puzzle.gridSize)×\(puzzle.gridSize)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 8) {
                    Label("\(puzzle.gridSize * puzzle.gridSize) pieces", systemImage: "puzzlepiece.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Status/Score
            if puzzle.isCompleted {
                VStack(spacing: 2) {
                    Text("\(puzzle.score)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                    Text("Pending")
                        .font(.caption2.bold())
                        .foregroundColor(.orange)
                }
            }
            
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

// MARK: - Empty State
struct EmptyPuzzlesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("🧩").font(.system(size: 60))
            Text("No puzzles yet").font(.headline).foregroundColor(.white)
            Text("Create a puzzle to get started!").font(.subheadline).foregroundColor(.white.opacity(0.8))
            Spacer()
        }
    }
}
