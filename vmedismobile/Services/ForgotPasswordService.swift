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
        // IMPORTANT: Use same endpoint as login - https://gqlmobile.vmedis.com/ailawa-aed
        let graphqlEndpoint = "https://gqlmobile.vmedis.com/ailawa-aed"
        
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
        
        // Debug: Print HTTP status
        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP Status Code: \(httpResponse.statusCode)")
        }
        
        // Debug: Print raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw GraphQL Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("❌ Bad server response")
            throw URLError(.badServerResponse)
        }
        
        // Parse GraphQL response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let dataObj = json["data"] as? [String: Any],
           let vmedresetuser = dataObj["vmedresetuser"] as? [String: Any] {
            
            let gak = vmedresetuser["gak"] as? Bool ?? true
              if !gak {
                // Success - gak = false berarti berhasil (sama seperti Android)
                let user = vmedresetuser["user"] as? [String: Any]
                let aptnama = vmedresetuser["aptnama"] as? [String: Any]
                let errors = vmedresetuser["errors"] as? [[String: Any]]
                
                // Ambil pesan dari errors[0].message (sama seperti Android)
                // Default message sama seperti backend GraphQL
                let message = errors?.first?["message"] as? String ?? "Permintaan reset password berhasil. Silakan cek email Anda untuk melanjutkan proses reset password."
                
                let userData = ResetPasswordResponse.ResetPasswordData(
                    user_id: user?["user_id"] as? Int,
                    email: user?["email"] as? String,
                    nama_lengkap: user?["nama_lengkap"] as? String,
                    kl_nama: aptnama?["kl_nama"] as? String
                )
                
                print("✅ Reset password berhasil")
                print("   Message: \(message)")
                return ResetPasswordResponse(
                    status: "success",
                    message: message,
                    data: userData
                )
            } else {
                // Error - gak = true berarti gagal (sama seperti Android)
                let errors = vmedresetuser["errors"] as? [[String: Any]]
                
                // Ambil pesan error dari errors[0].message (sama seperti Android)
                // Possible messages dari backend:
                // - "Domain tidak tersedia"
                // - "Email {email} tidak terdaftar dalam domain {domain}"
                // - "Silahkan mengisi domain terlebih dahulu!"
                // - "Silahkan mengisi email terlebih dahulu!"
                let errorMessage = errors?.first?["message"] as? String ?? "Gagal melakukan reset"
                  print("❌ Reset password gagal: \(errorMessage)")
                return ResetPasswordResponse(
                    status: "error",
                    message: errorMessage,
                    data: nil
                )
            }
        }
        
        // Jika sampai sini, berarti response tidak bisa di-parse
        print("❌ Failed to parse GraphQL response")
        print("   Response data: \(String(data: data, encoding: .utf8) ?? "N/A")")
        
        // Return error dengan pesan yang jelas
        return ResetPasswordResponse(
            status: "error",
            message: "Gagal memproses response dari server",
            data: nil
        )
    }
      // MARK: - Validate Domain
    /// Validasi domain sebelum reset password - SAMA SEPERTI LOGIN
    /// Menggunakan endpoint: https://api3penjualan.vmedis.com/klinik/validate-domain
    private func validateDomain(_ domain: String) async throws -> (status: String, message: String?) {
        print("=== VALIDATING DOMAIN (FORGOT PASSWORD) ===")
        print("Domain: \(domain)")
        
        // SAMA dengan LoginService - gunakan endpoint yang sama
        guard let url = URL(string: "https://api3penjualan.vmedis.com/klinik/validate-domain") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Buat form data parameters - SAMA dengan LoginService
        let parameters = ["domain": domain]
        
        // Convert to form data string
        var formDataString = ""
        for (key, value) in parameters {
            if !formDataString.isEmpty {
                formDataString += "&"
            }
            if let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                formDataString += "\(encodedKey)=\(encodedValue)"
            }
        }
        
        request.httpBody = formDataString.data(using: .utf8)
        
        print("Request URL: \(url)")
        print("Form Data: \(formDataString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check HTTP response
        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP Status Code: \(httpResponse.statusCode)")
        }
        
        // Debug: Print raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw Response: \(responseString)")
        }
        
        // Parse JSON response - SAMA dengan LoginService
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let status = json["status"] as? String {
            print("Domain validation status: \(status)")
            
            // Check if status is "failed" or "error"
            if status == "failed" || status == "error" {
                let message = json["message"] as? String ?? "Domain tidak tersedia"
                print("❌ Domain tidak valid: \(message)")
                return (status: "error", message: message)
            }
            
            // Success
            print("✅ Domain valid")
            return (status: "success", message: json["message"] as? String)
        }
        
        print("❌ Failed to parse domain validation response")
        return (status: "error", message: "Domain validation failed")
    }
}
