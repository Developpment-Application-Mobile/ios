//
//  PuzzleImagePlaceholder.swift
//  EduKid
//
//  Created by mac on 22/11/2025.
//

import SwiftUI

struct PuzzlePieceImageView: View {
    let piece: PuzzlePiece
    let puzzleType: PuzzleType
    let size: CGFloat
    
    var body: some View {
        Group {
            if let imageUrl = piece.imageUrl, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                // Load actual image from URL
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: size, height: size)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipped()
                    case .failure:
                        // Fallback to content text
                        ContentPlaceholder(content: piece.content, type: puzzleType)
                            .frame(width: size, height: size)
                    @unknown default:
                        ContentPlaceholder(content: piece.content, type: puzzleType)
                            .frame(width: size, height: size)
                    }
                }
            } else {
                // Use content as text/emoji
                ContentPlaceholder(content: piece.content, type: puzzleType)
                    .frame(width: size, height: size)
            }
        }
    }
}

struct ContentPlaceholder: View {
    let content: String
    let type: PuzzleType
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(type.color.opacity(0.1))
            
            Text(content)
                .font(.system(size: contentFontSize))
                .fontWeight(.bold)
                .foregroundColor(type.color)
                .multilineTextAlignment(.center)
                .padding(4)
                .minimumScaleFactor(0.5)
        }
    }
    
    var contentFontSize: CGFloat {
        // Adjust font size based on content length
        if content.count <= 3 {
            return 32
        } else if content.count <= 10 {
            return 24
        } else {
            return 16
        }
    }
}
