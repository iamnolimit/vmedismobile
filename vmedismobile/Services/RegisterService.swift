// File: Services/RegisterService.swift
import Foundation

class RegisterService: ObservableObject {
    
    // MARK: - Response Models
    struct RegisterResponse: Codable {
        let status: String
        let message: String?
        let data: RegisterData?
        
        struct RegisterData: Codable {
            let user_id: Int?
            let username: String?
            let email: String?
            let nama_lengkap: String?
            let app_id: String?
        }
    }
    
    // MARK: - Register New Account
    func register(
        domain: String,
        namaLengkap: String,
        username: String,
        email: String,
        noWhatsApp: String,
        password: String
    ) async throws -> RegisterResponse {
        print("=== REGISTER REQUEST ===")
        print("Domain: \(domain)")
        print("Username: \(username)")
        print("Email: \(email)")
        
        // Step 1: Validate domain first
        let domainValidation = try await validateDomain(domain)
        
        guard domainValidation.status == "success" else {
            print("❌ Domain tidak tersedia")
            return RegisterResponse(
                status: "error",
                message: "Domain tidak tersedia atau sudah digunakan",
                data: nil
            )
        }
        
        print("✅ Domain tersedia, proceed to registration...")
        
        // Step 2: Register via API
        // Note: Sesuaikan endpoint ini dengan API backend Anda
        let registerEndpoint = "https://api.vmedis.com/api/v1/register" // Sesuaikan URL
        
        guard let url = URL(string: registerEndpoint) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "domain": domain,
            "nama_lengkap": namaLengkap,
            "username": username,
            "email": email,
            "user_wa": noWhatsApp,
            "password": password,
            "device": "mobile_ios"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("Response Status Code: \(httpResponse.statusCode)")
        
        // Parse response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let status = json["status"] as? String ?? "error"
            let message = json["message"] as? String
            
            if status == "success" || (200...299).contains(httpResponse.statusCode) {
                print("✅ Registrasi berhasil")
                
                let userData: RegisterResponse.RegisterData?
                if let dataDict = json["data"] as? [String: Any] {
                    userData = RegisterResponse.RegisterData(
                        user_id: dataDict["user_id"] as? Int,
                        username: dataDict["username"] as? String,
                        email: dataDict["email"] as? String,
                        nama_lengkap: dataDict["nama_lengkap"] as? String,
                        app_id: dataDict["app_id"] as? String
                    )
                } else {
                    userData = nil
                }
                
                return RegisterResponse(
                    status: "success",
                    message: message ?? "Registrasi berhasil! Silakan login dengan akun Anda.",
                    data: userData
                )
            } else {
                print("❌ Registrasi gagal: \(message ?? "Unknown error")")
                return RegisterResponse(
                    status: "error",
                    message: message ?? "Registrasi gagal. Silakan coba lagi.",
                    data: nil
                )
            }
        }
        
        throw URLError(.cannotParseResponse)
    }
    
    // MARK: - Validate Domain Availability
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
            
            // status == "success" means domain is available
            // status == "error" means domain is already taken
            return (status: status, message: json["message"] as? String)
        }
        
        return (status: "error", message: "Domain validation failed")
    }
    
    // MARK: - Validate Email Availability
    func validateEmail(_ email: String, domain: String) async throws -> Bool {
        // Optional: Add email validation endpoint if available
        // For now, just basic email format check
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Validate Username Availability
    func validateUsername(_ username: String, domain: String) async throws -> Bool {
        // Optional: Add username validation endpoint if available
        // For now, just basic username format check
        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        let usernamePredicate = NSPredicate(format:"SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: username)
    }
}
