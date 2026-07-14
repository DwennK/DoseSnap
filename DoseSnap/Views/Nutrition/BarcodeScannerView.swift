@preconcurrency import AVFoundation
import SwiftUI

struct BarcodeScannerView: UIViewControllerRepresentable {
    var onCodeDetected: (String) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let controller = BarcodeScannerViewController()
        controller.onCodeDetected = onCodeDetected
        controller.onCancel = onCancel
        return controller
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {}
}

final class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeDetected: ((String) -> Void)?
    var onCancel: (() -> Void)?

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var didDetectCode = false
    private var isScannerConfigured = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureOverlay()
        configureScannerWithPermission()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isScannerConfigured && !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [captureSession] in
                captureSession.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !didDetectCode,
              let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = metadataObject.stringValue else {
            return
        }

        didDetectCode = true
        captureSession.stopRunning()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onCodeDetected?(code)
    }

    private func configureScannerWithPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureScanner()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] isGranted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if isGranted {
                        self.configureScanner()
                        DispatchQueue.global(qos: .userInitiated).async { [captureSession = self.captureSession] in
                            captureSession.startRunning()
                        }
                    } else {
                        self.showScannerUnavailable(
                            title: "Caméra refusée",
                            message: "Autorisez DoseSnap dans Réglages pour scanner un code-barres.",
                            showsSettingsButton: true
                        )
                    }
                }
            }
        case .denied, .restricted:
            showScannerUnavailable(
                title: "Caméra refusée",
                message: "Autorisez DoseSnap dans Réglages pour scanner un code-barres.",
                showsSettingsButton: true
            )
        @unknown default:
            showScannerUnavailable(
                title: "Scanner indisponible",
                message: "La caméra n'a pas pu être initialisée sur cet appareil.",
                showsSettingsButton: false
            )
        }
    }

    private func configureScanner() {
        guard !isScannerConfigured else { return }

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession.canAddInput(videoInput) else {
            showScannerUnavailable(
                title: "Scanner indisponible",
                message: "La caméra n'a pas pu être initialisée sur cet appareil.",
                showsSettingsButton: false
            )
            return
        }

        captureSession.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(metadataOutput) else {
            showScannerUnavailable(
                title: "Scanner indisponible",
                message: "La lecture du code-barres n'a pas pu être configurée.",
                showsSettingsButton: false
            )
            return
        }

        captureSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [
            .ean8,
            .ean13,
            .upce,
            .code39,
            .code93,
            .code128,
            .qr
        ]

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer
        isScannerConfigured = true
    }

    private func configureOverlay() {
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        closeButton.layer.cornerRadius = 22
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let label = UILabel()
        label.text = "Cadrez le code-barres"
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .headline)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let guide = UIView()
        guide.layer.borderColor = UIColor.white.withAlphaComponent(0.9).cgColor
        guide.layer.borderWidth = 2
        guide.layer.cornerRadius = 18
        guide.backgroundColor = UIColor.clear
        guide.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(closeButton)
        view.addSubview(label)
        view.addSubview(guide)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            label.bottomAnchor.constraint(equalTo: guide.topAnchor, constant: -18),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            guide.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            guide.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            guide.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.78),
            guide.heightAnchor.constraint(equalToConstant: 170)
        ])
    }

    @objc private func closeTapped() {
        onCancel?()
    }

    private func showScannerUnavailable(title: String, message: String, showsSettingsButton: Bool) {
        let container = UIView()
        container.backgroundColor = UIColor(AppTheme.deepNavy)
        container.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: "camera.badge.exclamationmark"))
        icon.tintColor = UIColor(AppTheme.secondaryAccent)
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center

        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = UIColor.white.withAlphaComponent(0.78)
        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Fermer", for: .normal)
        closeButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor(AppTheme.accent)
        closeButton.layer.cornerRadius = 16
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [icon, titleLabel, messageLabel, closeButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        view.addSubview(container)

        let constraints: [NSLayoutConstraint] = [
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            icon.widthAnchor.constraint(equalToConstant: 56),
            icon.heightAnchor.constraint(equalToConstant: 56),

            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -28),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            closeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 180),
            closeButton.heightAnchor.constraint(equalToConstant: 52)
        ]

        if showsSettingsButton {
            let settingsButton = UIButton(type: .system)
            settingsButton.setTitle("Ouvrir Réglages", for: .normal)
            settingsButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
            settingsButton.tintColor = UIColor(AppTheme.secondaryAccent)
            settingsButton.addTarget(self, action: #selector(openSettingsTapped), for: .touchUpInside)
            stack.addArrangedSubview(settingsButton)
        }

        NSLayoutConstraint.activate(constraints)
    }

    @objc private func openSettingsTapped() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
