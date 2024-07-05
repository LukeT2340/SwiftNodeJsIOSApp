//
//  ProfileInfoManager.swift
//  Frontend
//
//  Created by Luke Thompson on 5/7/2024.
//

import Foundation
import Alamofire

class ProfileInfoManager: ObservableObject {
    @Published var notes: [NotePackage] = []
    @Published var notesInitialized = false
    @Published var isFetching = false
    @Published var page = 1
    
    func fetchInitialBatchOfNotes(userId: String, completion: @escaping () -> Void) {
        self.page = 1
        self.fetchNotes(batchSize: 10, userId: userId) { notePackages in
            if let notePackages {
                print(notePackages)
                self.notes = notePackages
            }
        }
    }
    
    private func fetchNotes(batchSize: Int, userId: String, completion: @escaping ([NotePackage]?) -> Void) {
        guard !self.isFetching else {
            completion(nil)
            return
        }
        self.isFetching = true
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            print("Backend URL not set")
            self.isFetching = false
            completion(nil)
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not set")
            self.isFetching = false
            completion(nil)
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        let url = "\(backendURL)/note/fetch/?page=\(page)&limit=\(batchSize)&userId=\(userId)"
        AF.request(url, method: .get, headers: headers)
            .validate()
            .responseDecodable(of: [NotePackage].self) { response in
                DispatchQueue.main.async {
                    switch response.result {
                    case .success(let newNotesAndUsers):
                        self.page += 1
                        self.isFetching = false
                        completion(newNotesAndUsers)
                    case .failure(let error):
                        print("Failed to fetch new notes: \(error.localizedDescription)")
                        self.isFetching = false
                        completion(nil)
                    }
                }
            }
    }
}
