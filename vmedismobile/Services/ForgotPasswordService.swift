// File: Services/ForgotPasswordService.swift
import Foundation

class ForgotPasswordService: ObservableObject {
    
    // MARK: - Response Models
    struct ResetPasswordResponse: Codable {
        let status: String
        let message: String?
        let data: ResetPasswordData?
        
        struct ResetPasswordData: Codable {
            let user_id: Int?
            let email: String?
            let nama_lengkap: String?
            let kl_nama: String?
        }
    }
    
    // MARK: - Request Reset Password
    func requestResetPassword(domain: String, email: String) async throws -> ResetPasswordResponse {
        print("=== FORGOT PASSWORD REQUEST ===")
        print("Domain: \(domain)")
        print("Email: \(email)")
        
        // Step 1: Validate domain first
        let domainValidation = try await validateDomain(domain)
        
        guard domainValidation.status == "success" else {
            print("❌ Domain tidak valid")
            return ResetPasswordResponse(
                status: "error",
                message: "Domain tidak tersedia",
                data: nil
            )
        }
        
        print("✅ Domain valid, proceed to reset password...")
        
        // Step 2: Request reset password via GraphQL
        let graphqlEndpoint = "https://apollo.vmedis.com/graphql"
        
        let query = """
        mutation {
            vmedresetuser(domain: "\(domain)", email: "\(email)") {
                gak
                user {
                    user_id
                    email
                    nama_lengkap
                }
                aptnama {
                    kl_nama
                }
                errors {
                    path
                    message
                    title
                }
            }
        }
        """
        
        guard let url = URL(string: graphqlEndpoint) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["query": query]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // Parse GraphQL response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let dataObj = json["data"] as? [String: Any],
           let vmedresetuser = dataObj["vmedresetuser"] as? [String: Any] {
            
            let gak = vmedresetuser["gak"] as? Bool ?? true
            
            if !gak {
                // Success
                let user = vmedresetuser["user"] as? [String: Any]
                let aptnama = vmedresetuser["aptnama"] as? [String: Any]
                let errors = vmedresetuser["errors"] as? [[String: Any]]
                
                let message = errors?.first?["message"] as? String ?? "Link reset password telah dikirim ke email Anda."
                
                let userData = ResetPasswordResponse.ResetPasswordData(
                    user_id: user?["user_id"] as? Int,
                    email: user?["email"] as? String,
                    nama_lengkap: user?["nama_lengkap"] as? String,
                    kl_nama: aptnama?["kl_nama"] as? String
                )
                
                print("✅ Reset password berhasil")
                return ResetPasswordResponse(
                    status: "success",
                    message: message,
                    data: userData
                )
            } else {
                // Error
                let errors = vmedresetuser["errors"] as? [[String: Any]]
                let errorMessage = errors?.first?["message"] as? String ?? "Email tidak terdaftar"
                
                print("❌ Reset password gagal: \(errorMessage)")
                return ResetPasswordResponse(
                    status: "error",
                    message: errorMessage,
                    data: nil
                )
            }
        }
        
        throw URLError(.cannotParseResponse)
    }
    
    // MARK: - Validate Domain
    private func validateDomain(_ domain: String) async throws -> (status: String, message: String?) {
        let url = URL(string: "https://vmedis.com/site/cek-domain-tersedia")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "domain=\(domain)"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let status = json["status"] as? String {
            return (status: status, message: json["message"] as? String)
        }
        
        return (status: "error", message: "Domain validation failed")
    }
}
