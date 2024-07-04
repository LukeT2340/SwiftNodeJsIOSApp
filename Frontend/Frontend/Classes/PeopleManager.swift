//
//  PeopleModel.swift
//  Frontend
//
//  Created by Luke Thompson on 23/6/2024.
//

import SwiftUI
import Alamofire

class PeopleManager: ObservableObject {
    @Published var users: [User] = []
    @Published var isFetching = false
    
    func fetchUsers() {
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            print("Backend URL not set")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not set")
            return
        }
        
        let usersURL = "\(backendURL)/user/fetchRecommended"
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        isFetching = true
        
        AF.request(usersURL, method: .get, headers: headers)
            .validate()
            .responseDecodable(of: [User].self) { response in
                DispatchQueue.main.async {
                    self.isFetching = false
                    switch response.result {
                    case .success(let users):
                        self.users = users
                    case .failure(let error):
                        print("Failed to fetch users: \(error.localizedDescription)")
                        self.users = []
                    }
                }
            }

    }
}
