//
//  QRScreenParentView.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//

import Foundation
import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRScreenParentView: View {
    let child: Child
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("QR Code pour \(child.name)")
                .font(.title2.bold())

            if let qrImage = generateQRCode(from: child.connectionToken) {
                Image(uiImage: qrImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
            }

            Text("Scannez avec l’app enfant")
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Connexion Enfant")
        .toolbar {
            Button("Fermer") { dismiss() }
        }
    }

    func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            return context.createCGImage(scaledImage, from: scaledImage.extent).map { UIImage(cgImage: $0) }
        }
        return nil
    }
}
