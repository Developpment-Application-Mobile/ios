//
//  QRScreenParentView.swift
//  EduKid
//
//  Updated: November 15, 2025 – Added visible connection code for manual entry
//

import Foundation
import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRScreenParentView: View {
    let child: Child
    @EnvironmentObject var authVM: AuthViewModel
    
    var onBackClick: (() -> Void)?

    var body: some View {
        ZStack {
            // Background gradient
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(hex: "AF7EE7").opacity(0.6),
                    Color(hex: "272052")
                ]),
                center: .init(x: 0.3, y: 0.3),
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        if let onBackClick = onBackClick {
                            onBackClick()
                        } else {
                            authVM.authState = .childDetail(child)
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("QR Code")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("Scan to login as \(child.name)")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                // QR Code Card
                VStack(spacing: 24) {
                    // Child Avatar
                    Image(child.avatarEmoji)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .background(Color(hex: "AF7EE7").opacity(0.2))
                        .clipShape(Circle())
                    
                    // Child Name
                    Text(child.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "2E2E2E"))
                    
                    // QR Code
                    if let qrImage = generateQRCode(from: child.connectionToken) {
                        Image(uiImage: qrImage)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 80))
                                .foregroundColor(.gray)
                            Text("Unable to generate QR code")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 220, height: 220)
                        .background(Color.white)
                        .cornerRadius(16)
                    }
                    
                    // MARK: - NEW: Connection Code Display
                    VStack(spacing: 12) {
                        Text("Or enter this code manually:")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "2E2E2E"))
                        
                        HStack {
                            Text(child.connectionToken)
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundColor(.purple)
                                .tracking(4)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            Spacer()
                            
                            Button {
                                UIPasteboard.general.string = child.connectionToken
                                // Optional: add haptic feedback
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                            } label: {
                                Image(systemName: "doc.on.doc.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white.opacity(0.3))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Instructions
                    VStack(spacing: 8) {
                        Text("How to use:")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "2E2E2E"))
                        
                        Text("Open the EduKid app on the child's device and scan this QR code or enter the code above")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "666666"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(32)
                .background(Color.white.opacity(0.95))
                .cornerRadius(24)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Close Button
                Button(action: {
                    if let onBackClick = onBackClick {
                        onBackClick()
                    } else {
                        authVM.authState = .childDetail(child)
                    }
                }) {
                    Text("CLOSE")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.white)
                        .foregroundColor(Color(hex: "2E2E2E"))
                        .cornerRadius(30)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - QR Code Generator
    func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        filter.setValue("H", forKey: "inputCorrectionLevel")
        
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}

// MARK: - Preview
struct QRScreenParentView_Previews: PreviewProvider {
    static var previews: some View {
        QRScreenParentView(
            child: Child(
                name: "Emma",
                age: 8,
                level: "3",
                avatarEmoji: "avatar_1",
                Score: 85,
                quizzes: [],
                connectionToken: "ABC123"
            )
        )
        .environmentObject(AuthViewModel())
    }
}
