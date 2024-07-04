//
//  AuthManager.swift
//  Frontend
//
//  Created by Luke Thompson on 22/6/2024.
//

import Foundation
import Alamofire

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isSignedIn: Bool = false
    @Published var accountIsSetup: Bool = false
    @Published var user: User?
    @Published var errorMessage: String?
    @Published var isFetching = false

    init() {
        self.isSignedIn = UserDefaults.standard.bool(forKey: "isSignedIn")
        self.accountIsSetup = UserDefaults.standard.bool(forKey: "accountIsSetup")
        self.user = self.loadClientUserFromStorage()
        self.isFetching = true
        self.fetchUser() {
            self.isFetching = false

        }
    }

    func login(email: String, password: String) {
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            print("Backend URL not set")
            return
        }

        let loginURL = "\(backendURL)/auth/login"
        let parameters: [String: Any] = ["email": email, "password": password]

        AF.request(loginURL, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseData { response in
                switch response.result {
                case .success(let data):
                    print("Raw response data: \(String(data: data, encoding: .utf8) ?? "No data")")
                    do {
                        let userAndToken = try JSONDecoder().decode(UserAndToken.self, from: data)
                        DispatchQueue.main.async {
                            self.user = userAndToken.user
                            self.isSignedIn = true
                            self.accountIsSetup = true

                            UserDefaults.standard.set(true, forKey: "isSignedIn")
                            UserDefaults.standard.set(true, forKey: "accountIsSetup")
                            UserDefaults.standard.set(userAndToken.token, forKey: "authToken")
                            UserDefaults.standard.set(self.user?._id, forKey: "_id")
                            
                        }
                    } catch {
                        print("Failed to decode user and token: \(error.localizedDescription)")
                    }
                case .failure(_):
                    if let data = response.data {
                        print("Raw error response: \(String(data: data, encoding: .utf8) ?? "No data")")
                        do {
                            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                            DispatchQueue.main.async {
                                self.errorMessage = errorResponse.message
                            }
                        } catch {
                            print("Failed to decode error message: \(error.localizedDescription)")
                        }
                    } else {
                        print("Login failed: \(response.error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
    }
    
    func fetchUser(completion: @escaping () -> Void) {
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            print("Backend URL not set")
            completion()
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not set")
            completion()
            return
        }

        let URL = "\(backendURL)/user/fetchClient"

        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        AF.request(URL, method: .get, headers: headers)
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let user = try JSONDecoder().decode(User.self, from: data)
                        DispatchQueue.main.async {
                            self.user = user
                            self.isSignedIn = true
                            self.accountIsSetup = true

                            UserDefaults.standard.set(true, forKey: "isSignedIn")
                            UserDefaults.standard.set(true, forKey: "accountIsSetup")
                            completion()
                        }
                    } catch {
                        self.isSignedIn = false
                        self.accountIsSetup = false
                        UserDefaults.standard.set(false, forKey: "isSignedIn")
                        UserDefaults.standard.set(false, forKey: "accountIsSetup")
                        print("Failed to decode user: \(error.localizedDescription)")
                        completion()
                    }
                case .failure(_):
                    if let data = response.data {
                        print("Raw error response: \(String(data: data, encoding: .utf8) ?? "No data")")
                        do {
                            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                            DispatchQueue.main.async {
                                self.errorMessage = errorResponse.message
                            }
                        } catch {
                            print("Failed to decode error message: \(error.localizedDescription)")
                        }
                    } else {
                        print("Client user fetch failed: \(response.error?.localizedDescription ?? "Unknown error")")
                    }
                    completion()
                }
            }
    }
    
    private func loadClientUserFromStorage() -> User? {
        guard let encodedUsers = UserDefaults.standard.data(forKey: "users") else {
            return nil
        }
        let clientUserId = UserDefaults.standard.string(forKey: "_id")
        let decoder = JSONDecoder()
        if let cachedUsers = try? decoder.decode([User].self, from: encodedUsers) {
            return cachedUsers.first(where: {$0._id == clientUserId})
        }
        return nil
    }
}

