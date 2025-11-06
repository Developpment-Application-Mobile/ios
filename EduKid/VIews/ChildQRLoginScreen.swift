//
//  ChildQRLoginScreen.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//

import Foundation
import SwiftUI
import AVFoundation

struct ChildQRLoginScreen: View {
    @State private var showScanner = false
    @State private var showPermissionAlert = false
    
    var onQRScanned: (String) -> Void = { _ in }
    var onBackClick: () -> Void = {}
    
    var body: some View {
        ZStack {
            // Background gradient
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
            
            // Decorative elements
            DecorativeElementsChildLogin()
            
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                
                // Title
                Text("Welcome,\nKid Explorer!")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                
                Spacer().frame(height: 12)
                
                Text("Scan your QR code to start learning")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                Spacer().frame(height: 50)
                
                // QR Code Scanner Frame
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 280, height: 280)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white, lineWidth: 4)
                        )
                    
                    // Scanner corners decoration
                    QRCornerDecorations()
                    
                    if showScanner {
                        QRCodeScannerView { result in
                            if let qrCode = result {
                                onQRScanned(qrCode)
                                showScanner = false
                            }
                        }
                        .frame(width: 280, height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    } else {
                        // Camera preview placeholder
                        VStack(spacing: 8) {
                            Text("📷")
                                .font(.system(size: 60))
                            
                            Text("Position QR code\nwithin frame")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineSpacing(6)
                        }
                    }
                }
                .frame(width: 280, height: 280)
                
                Spacer().frame(height: 40)
                
                // Instruction text
                Text("Ask your parent for the QR code")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                // Scan button
                Button(action: {
                    requestCameraPermission()
                }) {
                    Text("OPEN SCANNER")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.white)
                        .cornerRadius(30)
                }
                
                Spacer().frame(height: 16)
                
                // Back button
                Button(action: onBackClick) {
                    Text("BACK TO HOME")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
                
                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 20)
        }
        .alert("Camera Permission Required", isPresented: $showPermissionAlert) {
            Button("Settings", action: openSettings)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable camera access in Settings to scan QR codes.")
        }
    }
    
    // MARK: - Camera Permission
    private func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showScanner = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showScanner = true
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            break
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - QR Corner Decorations
struct QRCornerDecorations: View {
    var body: some View {
        ZStack {
            // Top-left corner
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 1.0, green: 0.843, blue: 0.0), lineWidth: 4)
                .frame(width: 40, height: 40)
                .offset(x: -108, y: -108)
                .mask(
                    Rectangle()
                        .frame(width: 40, height: 40)
                        .offset(x: -108, y: -108)
                )
            
            // Top-right corner
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 1.0, green: 0.843, blue: 0.0), lineWidth: 4)
                .frame(width: 40, height: 40)
                .offset(x: 108, y: -108)
                .mask(
                    Rectangle()
                        .frame(width: 40, height: 40)
                        .offset(x: 108, y: -108)
                )
            
            // Bottom-left corner
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 1.0, green: 0.843, blue: 0.0), lineWidth: 4)
                .frame(width: 40, height: 40)
                .offset(x: -108, y: 108)
                .mask(
                    Rectangle()
                        .frame(width: 40, height: 40)
                        .offset(x: -108, y: 108)
                )
            
            // Bottom-right corner
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 1.0, green: 0.843, blue: 0.0), lineWidth: 4)
                .frame(width: 40, height: 40)
                .offset(x: 108, y: 108)
                .mask(
                    Rectangle()
                        .frame(width: 40, height: 40)
                        .offset(x: 108, y: 108)
                )
        }
    }
}

// MARK: - QR Code Scanner View
struct QRCodeScannerView: UIViewControllerRepresentable {
    let onResult: (String?) -> Void
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult)
    }
    
    class Coordinator: NSObject, QRScannerDelegate {
        let onResult: (String?) -> Void
        
        init(onResult: @escaping (String?) -> Void) {
            self.onResult = onResult
        }
        
        func didScanQRCode(_ code: String) {
            onResult(code)
        }
    }
}

// MARK: - QR Scanner Delegate
protocol QRScannerDelegate: AnyObject {
    func didScanQRCode(_ code: String)
}

// MARK: - QR Scanner View Controller
class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: QRScannerDelegate?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              let captureSession = captureSession else { return }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didScanQRCode(stringValue)
            captureSession?.stopRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
}

// MARK: - Decorative Elements Child Login
struct DecorativeElementsChildLogin: View {
    var body: some View {
        ZStack {
            // Book and Globe - Top Center
            Image("book_and_globe")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .blur(radius: 1)
                .offset(x: 0, y: -310)
            
            // Education Book - Top Left
            Image("education_book")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .blur(radius: 1)
                .offset(x: -140, y: -280)
            
            // Coins - Top Right
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .offset(x: 140, y: -290)
            
            // Coins - Top Left
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(15))
                .scaleEffect(x: -1, y: 1)
                .offset(x: -120, y: -220)
            
            // Book Stacks - Bottom Right
            Image("book_stacks")
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 110)
                .blur(radius: 2)
                .offset(x: 120, y: 340)
            
            // Coins - Bottom Left
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(38.66))
                .offset(x: -140, y: 350)
            
            // Coins - Middle Right
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 45, height: 45)
                .rotationEffect(.degrees(28.68))
                .offset(x: 150, y: 50)
        }
    }
}

// MARK: - Preview
struct ChildQRLoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        ChildQRLoginScreen()
    }
}
