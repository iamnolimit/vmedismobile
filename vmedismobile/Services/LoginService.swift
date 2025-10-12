// File: Services/LoginService.swift - Final Clean Version
import Foundation

struct LoginResponse: Codable {
    let status: String
    let message: String?
    var data: UserData?
}

struct UserData: Codable {
    let id: Int?
    let username: String?
    let password: String?
    let token: String?
    let gr_id: Int?
    let app_id: String?
    let status: Int?
    let keterangan: String?
    let logo: String?
    let lvl: Int?
    let domain: String?
    let nama_lengkap: String?
    let kl_id: Int?
    let app_jenis: Int?
    let dokid: Int?
    let kl_nama: String?
    let kl_logo: String?
    let kl_lat: String?
    let kl_lng: String?
    let countdown: String?
    let langganan: String?
    let created_at: Int?
    let wizard: Int?
    let app_reg: String?
    
    // MARK: - Menu Access Properties (Added for leveling system)
    /// Menyimpan akses menu untuk user (dari MenuGroupUser.Items1)
    var aksesMenu: [String]?  // Array of mn_url yang user punya akses
    
    /// Menyimpan header menu (dari MenuGroupUser.Items)
    var aksesMenuHead: [String]?  // Array of mn_nama header
}

struct DomainValidationResponse: Codable {
    let status: String
    let message: String?    // Tambahkan untuk handle error message
    let data: DomainData?   // Optional karena bisa null saat error
}

struct DomainData: Codable {
    let app_id: String?
    let kl_id: String?
    let kl_nama: String?
    let kl_logo: String?    
    let apt_nama: String?
    let apt_logo: String?
    // ... other fields dapat ditambahkan sesuai kebutuhan
}

// MARK: - GraphQL Response Models (for menu access)
/// Wrapper untuk GraphQL response
private struct GraphQLMenuResponse: Codable {
    let data: GraphQLMenuData?
}

private struct GraphQLMenuData: Codable {
    let MenuGroupUser: GraphQLMenuGroupUser?
}

private struct GraphQLMenuGroupUser: Codable {
    let Items1: [GraphQLMenuItem]?
}

private struct GraphQLMenuItem: Codable {
    let mn_url: String?
    let mn_kode: String?
    let mn_nama: String?
}

@MainActor
class LoginService: ObservableObject {
    private let baseURL = "https://api3.vmedis.com"
    private let domainValidationURL = "https://api3penjualan.vmedis.com"
    
    // MARK: - Domain Validation
    
    /// Validasi domain sebelum login
    /// - Parameter domain: Subdomain yang akan divalidasi
    /// - Returns: DomainValidationResponse berisi status dan data klinik/apotek
    /// - Throws: LoginError jika terjadi kesalahan
    func validateDomain(_ domain: String) async throws -> DomainValidationResponse {
        // Buat URL
        guard let url = URL(string: "\(domainValidationURL)/klinik/validate-domain") else {
            throw LoginError.invalidURL
        }
        
        // Setup request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Buat form data parameters
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
        
        // Set request body
        request.httpBody = formDataString.data(using: .utf8)
        
        // Debug: Print request
        print("=== DOMAIN VALIDATION ===")
        print("Request URL: \(url)")
        print("Form Data: \(formDataString)")
        
        // Kirim request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }
              // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw Response: \(responseString)")
            }
            
            // Try to decode as generic JSON first to check structure
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("JSON Structure: \(jsonObject)")
                
                // Check if status is "failed" or "error"
                if let status = jsonObject["status"] as? String {
                    print("Response Status: \(status)")
                    
                    if status == "failed" || status == "error" {
                        print("Domain validation failed - domain not found")
                        throw LoginError.domainNotFound
                    }
                }
            }
            
            // Decode response
            do {
                let domainResponse = try JSONDecoder().decode(DomainValidationResponse.self, from: data)
                print("Domain Validation Status: \(domainResponse.status)")
                
                // Double check status after decoding
                if domainResponse.status == "failed" || domainResponse.status == "error" {
                    throw LoginError.domainNotFound
                }
                
                return domainResponse
            } catch let decodingError as DecodingError {
                print("Decoding Error: \(decodingError)")
                // If decoding fails, likely domain not found (different response structure)
                throw LoginError.domainNotFound            } catch {
                print("Other Error: \(error)")
                throw error
            }
            
        } catch let error as LoginError {
            // Jika sudah LoginError (misal domainNotFound), langsung throw tanpa wrap
            print("LoginError caught: \(error)")
            throw error
        } catch {
            // Jika error lain (network, dll), wrap sebagai networkError
            print("Network Error: \(error)")
            throw LoginError.networkError(error)
        }
    }
    
    // MARK: - Login
    
    func login(username: String, password: String, domain: String) async throws -> LoginResponse {
        // Format tanggal sesuai dengan format yang digunakan
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDate = dateFormatter.string(from: Date())
        
        // Buat URL
        guard let url = URL(string: "\(baseURL)/sys/login") else {
            throw LoginError.invalidURL
        }
        
        // Setup request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Buat form data parameters
        let parameters = [
            "u": username,
            "p": password,
            "t": domain,
            "device": "ios",
            "ip": "",
            "date": currentDate
        ]
        
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
        
        // Set request body
        request.httpBody = formDataString.data(using: .utf8)
        
        // Debug: Print request
        print("Request URL: \(url)")
        print("Request Method: POST")
        print("Content-Type: application/x-www-form-urlencoded")
        print("Form Data: \(formDataString)")
        
        // Kirim request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                print("Response Headers: \(httpResponse.allHeaderFields)")
            }
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw Response: \(responseString)")
            }
            
            // Try to decode as generic JSON first
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                print("JSON Structure: \(jsonObject)")
            }
            
            // Decode response
            do {
                var loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                
                // Jika login sukses, fetch menu access
                if loginResponse.status == "success", var userData = loginResponse.data {
                    print("✅ Login successful, fetching menu access...")
                    
                    // Fetch menu access dari server
                    do {
                        let menuAccess = try await fetchMenuAccess(
                            grId: userData.gr_id ?? 0,
                            level: userData.lvl ?? 999,
                            token: userData.token ?? ""
                        )
                        
                        // Update userData dengan menu access
                        userData.aksesMenu = menuAccess.aksesMenu
                        userData.aksesMenuHead = menuAccess.aksesMenuHead
                        
                        // Update response dengan userData yang sudah ada menu access
                        loginResponse = LoginResponse(
                            status: loginResponse.status,
                            message: loginResponse.message,
                            data: userData
                        )
                        
                        print("✅ Menu access fetched and stored: \(menuAccess.aksesMenu.count) items")
                    } catch {
                        print("⚠️ Failed to fetch menu access: \(error)")
                        // Tidak throw error, login tetap berhasil walau menu access gagal
                        // User akan dapat full access sebagai fallback
                    }
                }
                
                return loginResponse
            } catch {
                print("Detailed Decoding Error: \(error)")
                
                // Create fallback response for decoding errors
                if let responseString = String(data: data, encoding: .utf8) {
                    if responseString.contains("error") || responseString.contains("fail") {
                        let fallbackResponse = LoginResponse(
                            status: "error",
                            message: responseString,
                            data: nil
                        )
                        return fallbackResponse
                    }
                }
                
                throw LoginError.decodingError("Failed to decode response: \(error.localizedDescription)")
            }
            
        } catch {
            print("Network Error: \(error)")
            throw LoginError.networkError(error)
        }
    }
    
    // MARK: - Fetch Menu Access
    
    /// Fetch menu access dari server berdasarkan gr_id dan level user
    private func fetchMenuAccess(grId: Int, level: Int, token: String) async throws -> (aksesMenu: [String], aksesMenuHead: [String]) {
        print("🔐 Fetching menu access for gr_id: \(grId), level: \(level)")
        
        // Jika superadmin (level 1), tidak perlu fetch - return empty (akan dapat full access)
        if level == 1 {
            print("👑 Superadmin detected - skipping menu fetch")
            return ([], [])
        }
        
        // GraphQL endpoint
        guard let url = URL(string: "\(baseURL)/graphql") else {
            throw LoginError.invalidURL
        }
        
        // GraphQL query
        let query = """
        query {
          MenuGroupUser(gr_id: \(grId)) {
            Items1 {
              mn_url
              mn_kode
              mn_nama
            }
          }
        }
        """
        
        // Setup request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Buat request body
        let requestBody: [String: Any] = ["query": query]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        print("📡 GraphQL Query: \(query)")
        
        // Kirim request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }
              // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("GraphQL Response: \(responseString)")
            }
            
            // Decode response
            let menuResponse = try JSONDecoder().decode(GraphQLMenuResponse.self, from: data)
            
            // Extract menu access
            var aksesMenu: [String] = []
            var aksesMenuHead: [String] = []
            
            if let items = menuResponse.data?.MenuGroupUser?.Items1 {
                for item in items {
                    if let mnUrl = item.mn_url, !mnUrl.isEmpty {
                        aksesMenu.append(mnUrl)
                    }
                    if let mnNama = item.mn_nama, !mnNama.isEmpty {
                        aksesMenuHead.append(mnNama)
                    }
                }
            }
            
            print("✅ Menu access parsed: \(aksesMenu.count) URLs, \(aksesMenuHead.count) headers")
            
            // Simpan ke MenuAccessManager
            let menuAccessItems = (menuResponse.data?.MenuGroupUser?.Items1 ?? []).compactMap { item -> MenuAccess? in
                guard let mnUrl = item.mn_url else { return nil }
                return MenuAccess(
                    mn_url: mnUrl,
                    mn_kode: item.mn_kode ?? "",
                    mn_nama: item.mn_nama ?? ""
                )
            }
            
            MenuAccessManager.shared.saveMenuAccess(menuAccessItems)
            print("💾 Menu access saved to local storage")
            
            return (aksesMenu, aksesMenuHead)
            
        } catch {
            print("❌ Failed to fetch menu access: \(error)")
            throw error
        }
    }
}

enum LoginError: LocalizedError {
    case invalidURL
    case encodingError
    case decodingError(String)
    case networkError(Error)
    case invalidCredentials
    case serverError(String)
    case domainNotFound
    case usernameNotFound
    case wrongPassword
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .encodingError:
            return "Failed to encode request"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidCredentials:
            return "Invalid username or password"
        case .serverError(let message):
            return message
        case .domainNotFound:
            return "Domain tidak tersedia"
        case .usernameNotFound:
            return "Username salah"
        case .wrongPassword:
            return "Password salah"
        }
    }
}
