import SwiftUI
import UIKit
import AVFoundation

struct CameraPicker: UIViewControllerRepresentable {
    var onImagePicked: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIViewController {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return CameraUnavailableViewController(
                message: "La caméra n'est pas disponible sur cet appareil. Importez une photo depuis la photothèque.",
                showsSettingsButton: false,
                onCancel: { dismiss() }
            )
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied, .restricted:
            return CameraUnavailableViewController(
                message: "L'accès à la caméra est refusé. Autorisez DoseSnap dans Réglages pour prendre une photo.",
                showsSettingsButton: true,
                onCancel: { dismiss() }
            )
        case .authorized, .notDetermined:
            break
        @unknown default:
            break
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: CameraPicker

        init(parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }

            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

private final class CameraUnavailableViewController: UIViewController {
    private let message: String
    private let showsSettingsButton: Bool
    private let onCancel: () -> Void

    init(message: String, showsSettingsButton: Bool, onCancel: @escaping () -> Void) {
        self.message = message
        self.showsSettingsButton = showsSettingsButton
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(AppTheme.deepNavy)

        let icon = UIImageView(image: UIImage(systemName: "camera.badge.exclamationmark"))
        icon.tintColor = UIColor(AppTheme.secondaryAccent)
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Caméra indisponible"
        titleLabel.textColor = .white
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = UIColor.white.withAlphaComponent(0.78)
        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Fermer", for: .normal)
        closeButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor(AppTheme.accent)
        closeButton.layer.cornerRadius = 16
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [icon, titleLabel, messageLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        view.addSubview(closeButton)

        if showsSettingsButton {
            let settingsButton = UIButton(type: .system)
            settingsButton.setTitle("Ouvrir Réglages", for: .normal)
            settingsButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
            settingsButton.tintColor = UIColor(AppTheme.secondaryAccent)
            settingsButton.translatesAutoresizingMaskIntoConstraints = false
            settingsButton.addTarget(self, action: #selector(openSettingsTapped), for: .touchUpInside)
            view.addSubview(settingsButton)

            NSLayoutConstraint.activate([
                settingsButton.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 16),
                settingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        }

        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 56),
            icon.heightAnchor.constraint(equalToConstant: 56),

            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -36),

            closeButton.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 28),
            closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            closeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 180),
            closeButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }

    @objc private func closeTapped() {
        onCancel()
    }

    @objc private func openSettingsTapped() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
