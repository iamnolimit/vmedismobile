// File: Services/BypassLoginService.swift
import Foundation

struct TokenRequest: Codable {
    let user: TokenUserData
    let identity: TokenIdentityData
    let accessToken: String
    let expiredToken: Int
}

struct TokenUserData: Codable {
    let user_id: Int
    let username: String
    let gr_id: Int?
    let app_id: String?
    let status: Int?
    let keterangan: String?
    let logo: String?
    let lvl: Int?
    let domain: String
    let nama_lengkap: String?
    let app_jenis: Int?
    let app_reg: String?
    let gr_akses: String?
}

struct TokenIdentityData: Codable {
    let kl_id: Int?
    let kl_logo: String?
    let kl_nama: String?
    let kl_alamat: String?
    let kl_tlp: String?
    let kl_no_reg: String?
    let apt_logo: String?
    let apt_alamat: String?
    let apt_nama: String?
    let apt_no_reg: String?
    let apt_tlp: String?
}

struct TokenResponse: Codable {
    let status: String
    let message: String?
    let data: String?
}

class BypassLoginService: ObservableObject {
    static let shared = BypassLoginService()
    
    private let baseUrlReact = "https://v3.vmedismart.com/"
    
    private init() {}
    
    func generateTokenUrl(userData: UserData, destinationUrl: String = "mobile") async throws -> URL {
        // Generate access token similar to PHP implementation
        let currentTimeMillis = Int64(Date().timeIntervalSince1970 * 1000)
        let userId = userData.id ?? 0
        let accessToken = Data("\(userId)--SED--\(currentTimeMillis)".utf8).base64EncodedString()
          // Prepare token request data
        let tokenRequest = TokenRequest(
            user: TokenUserData(
                user_id: userId,
                username: userData.username ?? "",
                gr_id: userData.gr_id,
                app_id: userData.app_id,
                status: userData.status,
                keterangan: userData.keterangan,
                logo: userData.logo,
                lvl: userData.lvl,
                domain: userData.domain ?? "",
                nama_lengkap: userData.nama_lengkap,
                app_jenis: userData.app_jenis,
                app_reg: userData.app_reg,
                gr_akses: nil // This might need to be stored separately or fetched
            ),
            identity: TokenIdentityData(
                kl_id: userData.kl_id,
                kl_logo: userData.kl_logo,
                kl_nama: userData.kl_nama,
                kl_alamat: nil, // These properties might need to be added to UserData model
                kl_tlp: nil,
                kl_no_reg: nil,
                apt_logo: nil,
                apt_alamat: nil,
                apt_nama: nil,
                apt_no_reg: nil,
                apt_tlp: nil
            ),
            accessToken: accessToken,
            expiredToken: Int(Date().timeIntervalSince1970) + 3600 // 1 hour expiration
        )
        
        // Make API request to get token
        let token = try await requestToken(tokenRequest: tokenRequest)
        
        // Build final URL with token
        let domain = userData.domain ?? ""
        let finalUrl = "\(baseUrlReact)\(domain)/auth?token=\(token)&menu=\(destinationUrl)"
        
        guard let url = URL(string: finalUrl) else {
            throw URLError(.badURL)
        }
        
        return url
    }
    
    private func requestToken(tokenRequest: TokenRequest) async throws -> String {
        let url = URL(string: "\(baseUrlReact)api/auth/get-token")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let jsonData = try JSONEncoder().encode(tokenRequest)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        guard tokenResponse.status == "success",
              let token = tokenResponse.data else {
            throw URLError(.userAuthenticationRequired)
        }
        
        return token
    }
}
