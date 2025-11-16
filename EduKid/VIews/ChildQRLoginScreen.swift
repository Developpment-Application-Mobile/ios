//
//  ChildQRLoginScreen.swift
//  EduKid
//
//  Updated: November 15, 2025 – QR/Code login with API integration
//

import SwiftUI
import AVFoundation

struct ChildQRLoginScreen: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showScanner = false
    @State private var showPermissionAlert = false
    @State private var showCodeEntry = false
    @State private var manualCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            // MARK: – Background
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

            // MARK: – Decorative elements
            DecorativeElementsChildLogin()

            VStack(spacing: 0) {
                Spacer().frame(height: 80)

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

                // MARK: – Scanner frame
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 280, height: 280)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white, lineWidth: 4)
                        )

                    QRCornerDecorations()

                    if showScanner {
                        QRCodeScannerView { result in
                            if let code = result {
                                handleLogin(token: code)
                                showScanner = false
                            }
                        }
                        .frame(width: 280, height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    } else {
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

                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(8)
                        .padding(.horizontal, 20)
                }

                Text("Ask your parent for the QR code")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)

                Spacer()

                // MARK: – Buttons
                VStack(spacing: 16) {
                    Button(action: requestCameraPermission) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.18, green: 0.18, blue: 0.18)))
                        } else {
                            Text("OPEN SCANNER")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.white)
                    .cornerRadius(30)
                    .disabled(isLoading)

                    Button(action: { showCodeEntry = true }) {
                        Text("ENTER CODE MANUALLY")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal, 20)

                Spacer().frame(height: 16)

                Button(action: { authVM.authState = .welcome }) {
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
                .padding(.horizontal, 20)
                .disabled(isLoading)

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 20)
        }
        .alert("Camera Permission Required", isPresented: $showPermissionAlert) {
            Button("Settings", action: openSettings)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable camera access in Settings to scan QR codes.")
        }
        .sheet(isPresented: $showCodeEntry) {
            CodeEntrySheet(isPresented: $showCodeEntry, manualCode: $manualCode) { token in
                handleLogin(token: token)
            }
        }
    }

    // MARK: – Login Handler
    private func handleLogin(token: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Find child by connection token
                let child = try await authVM.loginChildWithToken(token)
                
                await MainActor.run {
                    isLoading = false
                    authVM.selectedChild = child
                    authVM.authState = .childHome(child)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: – Camera permission
    private func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: showScanner = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { if granted { showScanner = true } }
            }
        case .denied, .restricted: showPermissionAlert = true
        @unknown default: break
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: – Manual Code Entry Sheet

private struct CodeEntrySheet: View {
    @Binding var isPresented: Bool
    @Binding var manualCode: String
    let onSubmit: (String) -> Void

    private var cleaned: String {
        manualCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var isValid: Bool {
        let code = cleaned
        
        // Accept MongoDB ObjectId (24 hex characters)
        if code.count == 24 {
            return code.allSatisfy { $0.isHexDigit }
        }
        
        // Accept short code (6 alphanumeric characters)
        if code.count == 6 {
            return code.allSatisfy { $0.isNumber || $0.isLetter }
        }
        
        // Accept UUID format (36 characters with dashes)
        if code.count == 36 {
            return code.range(of: #"^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$"#, options: .regularExpression) != nil
        }
        
        return false
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 44))
                        .foregroundColor(.blue)
                    Text("Enter Login Code")
                        .font(.title2.bold())
                }
                .padding(.top)

                TextField("Enter code", text: $manualCode)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .font(.system(size: 18, design: .monospaced))
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isValid ? Color.green : Color.clear, lineWidth: 2)
                    )

                if !manualCode.isEmpty && !isValid {
                    Text("Code must be 6 characters, 24-character ID, or a valid UUID")
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Login") {
                        if isValid {
                            onSubmit(cleaned)
                            isPresented = false
                        }
                    }
                    .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
// MARK: – Decorative Elements
private struct DecorativeElementsChildLogin: View {
    var body: some View {
        ZStack {
            Image(systemName: "book.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .blur(radius: 1)
                .offset(x: 0, y: -310)

            Image(systemName: "book")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .blur(radius: 1)
                .offset(x: -140, y: -280)

            Image(systemName: "dollarsign.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .offset(x: 140, y: -290)

            Image(systemName: "dollarsign.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(15))
                .scaleEffect(x: -1, y: 1)
                .offset(x: -120, y: -220)

            Image(systemName: "books.vertical")
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 110)
                .blur(radius: 2)
                .offset(x: 120, y: 340)

            Image(systemName: "dollarsign.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(38.66))
                .offset(x: -140, y: 350)

            Image(systemName: "dollarsign.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 45, height: 45)
                .rotationEffect(.degrees(28.68))
                .offset(x: 150, y: 50)
        }
    }
}

// MARK: – Corner decorations
private struct QRCornerDecorations: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.yellow, lineWidth: 4)
                .frame(width: 40, height: 40)
                .offset(x: -108, y: -108)

            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.yellow, lineWidth: 4)
                .frame(width: 40, height: 40)
                .offset(x: 108, y: -108)

            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.yellow, lineWidth: 4)
                .frame(width: 40, height: 40)
                .offset(x: -108, y: 108)

            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.yellow, lineWidth: 4)
                .frame(width: 40, height: 40)
                .offset(x: 108, y: 108)
        }
    }
}

// MARK: – QR Scanner
private struct QRCodeScannerView: UIViewControllerRepresentable {
    let onResult: (String?) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let vc = QRScannerViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onResult: onResult) }

    class Coordinator: NSObject, QRScannerDelegate {
        let onResult: (String?) -> Void
        init(onResult: @escaping (String?) -> Void) { self.onResult = onResult }
        func didScanQRCode(_ code: String) { onResult(code) }
    }
}

private protocol QRScannerDelegate: AnyObject {
    func didScanQRCode(_ code: String)
}

private class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: QRScannerDelegate?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: videoDevice),
              let session = captureSession, session.canAddInput(input) else { return }

        session.addInput(input)

        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        if let preview = previewLayer { view.layer.addSublayer(preview) }

        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        if let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let code = obj.stringValue {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didScanQRCode(code)
            captureSession?.stopRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
}
