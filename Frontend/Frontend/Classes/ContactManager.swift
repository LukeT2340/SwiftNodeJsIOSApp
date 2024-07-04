//
//  ContactManager.swift
//  Frontend
//
//  Created by Luke Thompson on 26/6/2024.
//

import Foundation
import SocketIO
import Alamofire
import UIKit
import SwiftUI
import SQLite

class ContactManager: ObservableObject {
    private var timer: Timer?
    
    @Published var users: [User] = []
    @Published var isFetching = false
    @Published var hasInitialized = false
    private var manager: SocketManager!
    private var socket: SocketIOClient!
    private var db: Connection!

    @Published var socketConnected = false
    
    let usersTable = Table("users")
    let _id = Expression<String>("_id")
    let username = Expression<String?>("username")
    let email = Expression<String?>("email")
    let profilePictureUrl = Expression<String?>("profilePictureUrl")
    let targetLanguages = Expression<String?>("targetLanguages")
    let nativeLanguages = Expression<String?>("nativeLanguages")
    let country = Expression<String?>("country")
    let bio = Expression<String?>("bio")
    let createdAt = Expression<String?>("createdAt")
    let lastOnline = Expression<String?>("lastOnline")
    
    
    // On class declaration
    init() {
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileUrl = documentDirectory.appendingPathComponent("users").appendingPathExtension("sqlite3")
            db = try Connection(fileUrl.path)
            try createUsersTable()
        } catch {
            print("Error creating database: \(error)")
        }
    }
    
    func initialize() {
        self.users = self.loadUsersFromStorage()
        self.isFetching = true
        self.fetchUsers {
            self.setupSocket() {
                self.startTimer()
                self.updateLastOnline()
                self.isFetching = false
                self.hasInitialized = true
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    // Create users table (if it doesn't exist)
    private func createUsersTable() throws {
           //try db.run(conversationsTable.drop(ifExists: true))
        
           try db.run(usersTable.create(ifNotExists: true) { table in
               table.column(_id, primaryKey: true)
               table.column(username)
               table.column(email)
               table.column(profilePictureUrl)
               table.column(targetLanguages)
               table.column(nativeLanguages)
               table.column(country)
               table.column(bio)
               table.column(lastOnline)
               table.column(createdAt)
           })
    }
    
    private func setupSocket(completion: @escaping () -> Void) {
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            print("Backend URL not set")
            completion()
            return
        }
        
        guard let _id = UserDefaults.standard.string(forKey: "_id") else {
            print("User Id not set")
            completion()
            return
        }
        
        manager = SocketManager(socketURL: URL(string: backendURL)!, config: [
            .connectParams(["clientUserId": _id])
        ])
        socket = manager.defaultSocket
        
        socket.on(clientEvent: .connect) { data, ack in
            print("Socket connected")
            DispatchQueue.main.async {
                self.socketConnected = true
            }
            self.fetchUsers {
                completion()
            }
        }
        
        socket.on("lastOnlineUpdate") {data, ack in
            guard let update = data[0] as? [String: Any],
                  let userId = update["userId"] as? String,
                  let lastOnline = update["lastOnline"] as? String else {
                return
            }
            DispatchQueue.main.async {
                if let index = self.users.firstIndex(where: { $0._id == userId }) {
                    self.users[index].lastOnline = lastOnline
                    self.saveUserToStorage(self.users[index])
                } else {
                    self.fetchUsers {}
                }
            }
        }
        
        
        socket.on(clientEvent: .disconnect) { data, ack in
               DispatchQueue.main.async {
                   self.socketConnected = false
               }
               print("Socket disconnected")
           }
           
           socket.on(clientEvent: .reconnect) { data, ack in
               DispatchQueue.main.async {
                   self.socketConnected = false
               }
               print("Socket reconnecting")
           }
           
           socket.on(clientEvent: .reconnectAttempt) { data, ack in
               DispatchQueue.main.async {
                   self.socketConnected = false
               }
               print("Socket reconnect attempt")
           }
           
           socket.on(clientEvent: .error) { data, ack in
               DispatchQueue.main.async {
                   self.socketConnected = false
               }
               print("Socket error: \(data)")
           }
        
        socket.connect()
    }
    
    func fetchUsers(completion: @escaping () -> Void) {
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            print("Backend URL not set")
            completion() // Call completion immediately if backend URL is not set
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not set")
            completion() // Call completion immediately if auth token is not set
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
    
        let URL = "\(backendURL)/user/fetchContacts"
        AF.request(URL, method: .get, headers: headers)
            .validate()
            .responseDecodable(of: [User].self) { response in
                DispatchQueue.main.async {
                    switch response.result {
                    case .success(let users):
                        DispatchQueue.main.async {
                            // Update users dictionary with fetched users
                            self.users = users
                            self.saveUsersToStorage(users)
                        }
                    case .failure(let error):
                        print("Failed to fetch users: \(error.localizedDescription)")
                    }
                    completion()
                }
            }
        }
    
    func loadUsersFromStorage() -> [User] {
        guard !isFetching else {
            return []
        }

        isFetching = true

        var users: [User] = []

        do {
            let query = usersTable

            for row in try db.prepare(query) {
                let nativeLanguagesArray: [String] = {
                    if let nativeLanguagesData = row[nativeLanguages]?.data(using: .utf8),
                       let decodedArray = try? JSONDecoder().decode([String].self, from: nativeLanguagesData) {
                        return decodedArray
                    } else {
                        return []
                    }
                }()
                
                let targetLanguagesArray: [User.Language] = {
                    if let targetLanguagesData = row[targetLanguages]?.data(using: .utf8),
                       let decodedArray = try? JSONDecoder().decode([User.Language].self, from: targetLanguagesData) {
                        return decodedArray
                    } else {
                        return []
                    }
                }()
                
                let user = User(
                    _id: row[_id],
                    username: row[username],
                    email: row[email],
                    profilePictureUrl: row[profilePictureUrl],
                    targetLanguages: targetLanguagesArray,
                    nativeLanguages: nativeLanguagesArray,
                    country: row[country],
                    bio: row[bio],
                    createdAt: row[createdAt],
                    lastOnline: row[lastOnline]
                )
                
                users.append(user)
            }
        } catch {
            print("Error loading users: \(error)")
        }

        isFetching = false
        print(users)
        return users
    }
    
    private func saveUserToStorage(_ user: User) {
        do {
            let targetLanguagesData = try JSONEncoder().encode(user.targetLanguages)
            let targetLanguagesJsonString = String(data: targetLanguagesData, encoding: .utf8)
            
            let nativeLanguagesData = try JSONEncoder().encode(user.nativeLanguages)
            let nativeLanguagesJsonString = String(data: nativeLanguagesData, encoding: .utf8)
            
            let insert = usersTable.insert(or: .replace,
                _id <- user._id,
                username <- user.username,
                email <- user.email,
                profilePictureUrl <- user.profilePictureUrl,
                targetLanguages <- targetLanguagesJsonString,
                nativeLanguages <- nativeLanguagesJsonString,
                country <- user.country,
                bio <- user.bio,
                createdAt <- user.createdAt,
                lastOnline <- user.lastOnline
            )
            
            try db.run(insert)
        } catch {
            print("Error fetching users from SQLite: \(error)")
        }
    }
    
    private func saveUsersToStorage(_ users: [User]) {
        do {
            try db.run(usersTable.delete())
            for user in users {
                self.saveUserToStorage(user)
            }
        } catch {
            print("Error saving users to SQLite \(error)")
        }
    }
    
    private func startTimer() {
        // Ensure timer is nil before starting to prevent multiple timers running simultaneously
        timer?.invalidate()
        
        // Create a new timer that fires every 30 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] timer in
            DispatchQueue.main.async {
                self?.updateLastOnline()
            }
        }
    }
    
    func updateLastOnline() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDate = dateFormatter.string(from: Date())
        
        let data: [String: Any] = [
            "lastOnline": currentDate
        ]
        
        // Check if socket is not nil
        guard let socket = socket else {
            print("Socket is not initialized")
            return
        }
        
        socket.emit("LastOnline", data)
    }

    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        stopTimer()
    }
    
    // This function is called when the user re-opens the app.
    @objc private func appMovedToForeground() {
        updateLastOnline()
    }
}
