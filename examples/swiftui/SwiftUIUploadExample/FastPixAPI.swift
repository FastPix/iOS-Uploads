import Foundation

// Mints a signed upload URL from FastPix's Direct Upload API.
// POST https://api.fastpix.com/v1/on-demand/upload  (Basic auth: base64(token:secretKey))
// Response: data.url is the signed PUT URL the SDK uploads chunks to.
enum FastPixAPI {

    struct SignedUpload {
        let url: String
        let uploadId: String
    }

    enum APIError: LocalizedError {
        case missingCredentials
        case badResponse(Int)
        case malformed

        var errorDescription: String? {
            switch self {
            case .missingCredentials: return "Set your token/secret in Secrets.swift."
            case .badResponse(let code): return "create-upload failed (HTTP \(code))."
            case .malformed: return "create-upload returned an unexpected response."
            }
        }
    }

    static func createUpload() async throws -> SignedUpload {
        guard Secrets.token != "YOUR_FASTPIX_TOKEN", !Secrets.token.isEmpty, !Secrets.secretKey.isEmpty else {
            throw APIError.missingCredentials
        }

        var request = URLRequest(url: URL(string: "https://api.fastpix.com/v1/on-demand/upload")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let basic = Data("\(Secrets.token):\(Secrets.secretKey)".utf8).base64EncodedString()
        request.setValue("Basic \(basic)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "corsOrigin": "*",
            "pushMediaSettings": ["accessPolicy": "public", "maxResolution": "2160p"]
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.malformed }
        guard (200..<300).contains(http.statusCode) else { throw APIError.badResponse(http.statusCode) }

        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let payload = root["data"] as? [String: Any],
              let url = payload["url"] as? String else {
            throw APIError.malformed
        }
        return SignedUpload(url: url, uploadId: payload["uploadId"] as? String ?? "")
    }
}
