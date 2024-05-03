//
//  ContentView.swift
//  QR Code Scanner
//
//  Created by Koray Akkilic on 03.05.24.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var isShowingScanner = false
    @State private var scannedCode: String?

    var body: some View {
        VStack {
            if let code = scannedCode {
                Text("Scanned QR Code: \(code)")
            } else {
                Button("Scan QR Code") {
                    isShowingScanner.toggle()
                }
            }
        }
        .sheet(isPresented: $isShowingScanner) {
            ScannerView(scannedCode: $scannedCode)
        }
        .padding()
    }
}

struct ScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?

    func makeUIViewController(context: Context) -> ScannerViewController {
        let scannerViewController = ScannerViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(scannedCode: $scannedCode)
    }

    class Coordinator: NSObject, ScannerViewControllerDelegate {
        @Binding var scannedCode: String?

        init(scannedCode: Binding<String?>) {
            _scannedCode = scannedCode
        }

        func didFindCode(_ code: String) {
            scannedCode = code
        }
    }
}

protocol ScannerViewControllerDelegate: AnyObject {
    func didFindCode(_ code: String)
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: ScannerViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup capture session
        let captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else { return }

        captureSession.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(metadataOutput)

        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }
        guard let code = metadataObject.stringValue else { return }

        delegate?.didFindCode(code)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
