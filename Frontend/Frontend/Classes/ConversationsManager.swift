//
//  ConversationsManager.swift
//  Frontend
//
//  Created by Luke Thompson on 1/7/2024.
//

import Foundation
import SQLite
import Alamofire

class ConversationsManager: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var hasInitialized = false
    @Published var isFetching = false
    private var db: Connection!
    
    // On class declaration
    init() {
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileUrl = documentDirectory.appendingPathComponent("conversations").appendingPathExtension("sqlite3")
            db = try Connection(fileUrl.path)
            try createConversationsTable()
        } catch {
            print("Error creating database: \(error)")
        }
    }
    
    // Initialize class (likely activated using onAppear)
    func initialize() {
        DispatchQueue.main.async {
            self.conversations = self.loadConversationsFromStorage()
            self.refreshConversations { [weak self] in
                self?.hasInitialized = true
            }
        }
    }
    
    // Fetch conversations from storage
    func loadConversationsFromStorage() -> [Conversation] {
            guard !isFetching else {
                return []
            }

            isFetching = true

            var conversations: [Conversation] = []

        do {
            let conversationsTable = Table("conversations")
            let _id = Expression<String>("_id")
            let creator = Expression<String>("creator")
            let participants = Expression<String>("participants")
            let chatName = Expression<String?>("chatName")
            let createdAt = Expression<String>("createdAt")
            
            
            let query = conversationsTable
                .order(createdAt.desc)
            
            for row in try db.prepare(query) {
                if let participantsData = row[participants].data(using: .utf8),
                   let participantsArray = try? JSONDecoder().decode([String].self, from: participantsData) {
                    let conversation = Conversation(
                        _id: row[_id],
                        creator: row[creator],
                        participants: participantsArray,
                        chatName: row[chatName],
                        createdAt: row[createdAt]
                    )
                    conversations.append(conversation)
                }
            }
            self.isFetching = false
            } catch {
                print("Error fetching conversations from SQLite: \(error)")
                self.isFetching = false
            }

        return conversations
        }
    
    // Retrieve conversations from api backend and update cached conversations
    func refreshConversations(completion: @escaping () -> Void) {
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            print("Backend URL not set")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not set")
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        let url = "\(backendURL)/conversation/fetchAll/"
        AF.request(url, method: .get, headers: headers)
            .validate()
            .responseDecodable(of: [Conversation].self) { response in
                DispatchQueue.main.async {
                    switch response.result {
                    case .success(let conversations):
                        DispatchQueue.main.async {
                            self.conversations = conversations
                            self.saveConversationsToStorage(conversations)
                        }
                    case .failure(let error):
                        print("Failed to fetch conversations: \(error.localizedDescription)")
                    }
                    completion()
                }
            }
    }
    
    // Create conversations table (if it doesn't exist)
    private func createConversationsTable() throws {
           let conversationsTable = Table("conversations")
           let _id = Expression<String>("_id")
           let creator = Expression<String>("creator")
           let partipants = Expression<String>("participants")
           let chatName = Expression<String?>("chatName")
           let createdAt = Expression<String?>("createdAt")

           //try db.run(conversationsTable.drop(ifExists: true))
        
           try db.run(conversationsTable.create(ifNotExists: true) { table in
               table.column(_id, primaryKey: true)
               table.column(creator)
               table.column(partipants)
               table.column(chatName)
               table.column(createdAt)
           })
       }
    
    private func saveConversationsToStorage(_ conversations: [Conversation]) {
        guard conversations.count != 0 else {
            return
        }
        
        let conversationsTable = Table("conversations")
        let _id = Expression<String>("_id")
        let creator = Expression<String>("creator")
        let participants = Expression<String>("participants")
        let chatName = Expression<String?>("chatName")
        let createdAt = Expression<String>("createdAt")

        do {
            // Delete existing conversations
            try db.run(conversationsTable.delete())

            // Insert new conversations
            for conversation in conversations {
                let participantsData = try JSONEncoder().encode(conversation.participants)
                let participantsString = String(data: participantsData, encoding: .utf8) ?? "[]"

                let insert = conversationsTable.insert(
                    _id <- conversation._id,
                    creator <- conversation.creator,
                    participants <- participantsString,
                    chatName <- conversation.chatName,
                    createdAt <- conversation.createdAt
                )
                try db.run(insert)
            }
        } catch {
            print("Error saving conversations to SQLite: \(error)")
        }
    }
    
    func createNewConversation(userId: String,  completion: @escaping (String?) -> Void) {
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            print("Backend URL not set")
            return
        }
        
        guard let clientUserId = UserDefaults.standard.string(forKey: "_id") else {
            print("User Id not set")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not set")
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        let parameters: [String: Any] = ["participants": [userId, clientUserId]]
        
        let url = "\(backendURL)/conversation/fetchId"
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers )
            .validate()
            .responseDecodable(of: Conversation.self) { response in
               switch response.result {
               case .success(let conversation):
                   DispatchQueue.main.async {
                       if let index = self.conversations.firstIndex(where: {$0._id == conversation._id}) {
                           self.conversations[index] = conversation
                       } else {
                           self.conversations.append(conversation)
                       }
                       self.refreshConversations {
                           completion(conversation._id)
                       }
                   }
               case .failure(let error):
                   print("Failed to create conversation: \(error.localizedDescription)")
                   completion(nil)
               }
           }
    }
    
    func addUserToConversation(userIds: [String], conversationId: String, completion: @escaping () -> Void) {
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            print("Backend URL not set")
            return
        }
        
        guard let clientUserId = UserDefaults.standard.string(forKey: "_id") else {
            print("User Id not set")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not set")
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        let parameters: [String: Any] = ["conversationId": conversationId, "userIds": userIds]
        
        let url = "\(backendURL)/conversation/addUsers"
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers )
            .validate()
            .responseDecodable(of: Conversation.self) { response in
               switch response.result {
               case .success(let conversation):
                   DispatchQueue.main.async {
                       if let index = self.conversations.firstIndex(where: {$0._id == conversation._id}) {
                           self.conversations[index] = conversation
                       } else {
                           self.conversations.append(conversation)
                       }
                       self.refreshConversations {                        
                           completion()
                       }
                   }
               case .failure(let error):
                   print("Failed to add user to conversation conversation: \(error.localizedDescription)")
                   completion()
               }
           }
    }
    
    func changeGroupChatName(_ conversationId: String, name: String, completion: @escaping () -> Void) {
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            print("Backend URL not set")
            return
        }
        
        guard let clientUserId = UserDefaults.standard.string(forKey: "_id") else {
            print("User Id not set")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not set")
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        let parameters: [String: Any] = ["newName": name, "conversationId": conversationId]
            
        let url = "\(backendURL)/conversation/changeGroupChatName"
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    if let json = value as? [String: Any] {
                        // Handle the JSON response here
                        DispatchQueue.main.async {
                            self.refreshConversations {
                                completion()
                            }
                        }
                    } else {
                        print("Failed to parse JSON response")
                        completion()
                    }
                case .failure(let error):
                    print("Failed to change group chat name: \(error.localizedDescription)")
                    completion()
                }
            }
    }
}
