import CryptoKit
import DeviceCheck
import Foundation

struct DeviceIntegrityHeaders {
    var installationId: String
    var appAttestKeyId: String?
    var appAttestAssertion: String?
    var deviceCheckToken: String?
}

actor DeviceIntegrityService {
    static let shared = DeviceIntegrityService()

    private let installationIdKey = "DoseSnapInstallationID"
    private let appAttestKeyIdKey = "DoseSnapAppAttestKeyID"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func headers(for requestBody: Data?) async -> DeviceIntegrityHeaders {
        let installationId = installationId()
        let bodyHash = Data(SHA256.hash(data: requestBody ?? Data()))

        async let appAttest = appAttestAssertion(clientDataHash: bodyHash)
        async let deviceCheck = deviceCheckToken()

        let appAttestResult = await appAttest

        return DeviceIntegrityHeaders(
            installationId: installationId,
            appAttestKeyId: appAttestResult?.keyId,
            appAttestAssertion: appAttestResult?.assertion,
            deviceCheckToken: await deviceCheck
        )
    }

    private func installationId() -> String {
        if let existing = userDefaults.string(forKey: installationIdKey), !existing.isEmpty {
            return existing
        }

        let id = UUID().uuidString
        userDefaults.set(id, forKey: installationIdKey)
        return id
    }

    private func appAttestAssertion(clientDataHash: Data) async -> (keyId: String, assertion: String)? {
        guard DCAppAttestService.shared.isSupported else { return nil }

        do {
            let keyId = try await appAttestKeyId()
            let assertion = try await generateAssertion(keyId: keyId, clientDataHash: clientDataHash)
            return (keyId, assertion.base64EncodedString())
        } catch {
            return nil
        }
    }

    private func appAttestKeyId() async throws -> String {
        if let existing = userDefaults.string(forKey: appAttestKeyIdKey), !existing.isEmpty {
            return existing
        }

        let keyId = try await withCheckedThrowingContinuation { continuation in
            DCAppAttestService.shared.generateKey { keyId, error in
                if let keyId {
                    continuation.resume(returning: keyId)
                } else {
                    continuation.resume(throwing: error ?? DeviceIntegrityError.keyGenerationFailed)
                }
            }
        }

        userDefaults.set(keyId, forKey: appAttestKeyIdKey)
        return keyId
    }

    private func generateAssertion(keyId: String, clientDataHash: Data) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            DCAppAttestService.shared.generateAssertion(keyId, clientDataHash: clientDataHash) { assertion, error in
                if let assertion {
                    continuation.resume(returning: assertion)
                } else {
                    continuation.resume(throwing: error ?? DeviceIntegrityError.assertionFailed)
                }
            }
        }
    }

    private func deviceCheckToken() async -> String? {
        guard DCDevice.current.isSupported else { return nil }

        do {
            let token = try await withCheckedThrowingContinuation { continuation in
                DCDevice.current.generateToken { data, error in
                    if let data {
                        continuation.resume(returning: data)
                    } else {
                        continuation.resume(throwing: error ?? DeviceIntegrityError.deviceCheckFailed)
                    }
                }
            }

            return token.base64EncodedString()
        } catch {
            return nil
        }
    }
}

enum DeviceIntegrityError: Error {
    case keyGenerationFailed
    case assertionFailed
    case deviceCheckFailed
}
