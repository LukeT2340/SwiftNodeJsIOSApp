//
//  ChatManager.swift
//  Frontend
//
//  Created by Luke Thompson on 24/6/2024.
//

import Foundation
import Alamofire
import SocketIO
import AudioToolbox
import UIKit
import TLPhotoPicker
import Photos
import SQLite

class MessagesManager: ObservableObject {
    @Published var messages: [Message] = []
    @Published var messagesPage: [String : Int] = [:]
    @Published var isFetching = false
    @Published var hasInitialized = false
    @Published var currentConversationId: String?
    private var manager: SocketManager!
    private var socket: SocketIOClient!
    @Published var socketConnected = false
    private var db: Connection!

    let messagesTable = Table("messages")
    let _id = Expression<String?>("_id")
    let text = Expression<String?>("text")
    let video = Expression<String?>("video")
    let image = Expression<String?>("image")
    let sender = Expression<String?>("sender")
    let voiceMessage = Expression<String?>("voiceMessage")
    let duration = Expression<Int?>("duration")
    let createdAt = Expression<String?>("createdAt")
    let conversationId = Expression<String>("conversationId")
    let readBy = Expression<String>("readBy")
    let status = Expression<String?>("status")
    let isSystemMessage = Expression<Bool?>("isSystemMessage")
    
    init() {
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileUrl = documentDirectory.appendingPathComponent("messages").appendingPathExtension("sqlite3")
            db = try Connection(fileUrl.path)
            try createTable()
        } catch {
            print("Error creating database: \(error)")
        }
    }
    
    func initialize() {
        DispatchQueue.main.async {            
            self.loadFirstBatchOfMessages()
            self.setupSocket() { [weak self] in
                self?.hasInitialized = true
            }
        }
    }
    
    
    
    private func createTable() throws {
           let messagesTable = Table("messages")
           let _id = Expression<String>("_id")
           let text = Expression<String?>("text")
           let sender = Expression<String?>("sender")
           let video = Expression<String?>("video")
           let image = Expression<String?>("image")
           let voiceMessage = Expression<String?>("voiceMessage")
           let duration = Expression<Int?>("duration")
           let createdAt = Expression<String?>("createdAt")
           let conversationId = Expression<String>("conversationId")
           let readBy = Expression<String>("readBy")
           let status = Expression<String?>("status")
           let isSystemMessage = Expression<Bool?>("isSystemMessage")

           //try db.run(messagesTable.drop(ifExists: true))
        
           try db.run(messagesTable.create(ifNotExists: true) { table in
               table.column(_id, primaryKey: true)
               table.column(text)
               table.column(sender)
               table.column(video)
               table.column(image)
               table.column(voiceMessage)
               table.column(duration)
               table.column(createdAt)
               table.column(conversationId)
               table.column(readBy)
               table.column(status)
               table.column(isSystemMessage)
           })
       }
    
    var totalUnreadMessages: Int {
        guard let clientId = UserDefaults.standard.string(forKey: "_id") else {
            return 0
        }
        
        return messages.filter {
            $0.sender != clientId && !$0.readBy.contains(clientId)
        }.count
    }
    
    private func loadFirstBatchOfMessages() {
         var cachedMessages: [Message] = []
         var conversationIds = self.retrieveConversationIds()
         for conversationId in conversationIds {
             self.messagesPage[conversationId] = 1
             cachedMessages.append(contentsOf: self.loadMessagesFromStorage(batchSize: 30, conversationId: conversationId))
         }
         self.messages = cachedMessages
     }
    
    private func retrieveConversationIds() -> [String] {
        var conversationIds: Set<String> = []

    do {
         let messagesTable = Table("messages")
         let _id = Expression<String>("_id")
         let text = Expression<String?>("text")
         let sender = Expression<String?>("sender")
         let video = Expression<String?>("video")
         let image = Expression<String?>("image")
         let voiceMessage = Expression<String?>("voiceMessage")
         let duration = Expression<Int?>("duration")
         let createdAt = Expression<String?>("createdAt")
         let conversationIdExpression = Expression<String>("conversationId")
         let readBy = Expression<String>("readBy")
         let status = Expression<String?>("status")
         let isSystemMessage = Expression<Bool?>("isSystemMessage")

         let query = messagesTable

         for row in try db.prepare(query) {
             let statusString = row[status] ?? "sent"
             if let readByData = row[readBy].data(using: .utf8),
                let readByArray = try? JSONDecoder().decode([String].self, from: readByData) {
                    let messageStatus = Status(rawValue: statusString)
                    let message = Message(
                        conversationId: row[conversationIdExpression],
                        sender: row[sender],
                        text: row[text],
                        readBy: readByArray,
                        _id: row[_id],
                        voiceMessage: row[voiceMessage],
                        duration: row[duration],
                        video: row[video],
                        image: row[image],
                        createdAt: row[createdAt],
                        status: messageStatus,
                        isSystemMessage: row[isSystemMessage]
                    )
                 conversationIds.insert(message.conversationId)
                    
                }
            }
        } catch {
            print("Error fetching messages from SQLite: \(error)")
            self.isFetching = false
        }

        return Array(conversationIds)
    }
    
    private func updateMessagesArray(_ message: Message) {
        DispatchQueue.main.async {
            if let index = self.messages.firstIndex(where: { $0._id == message._id}) {
                self.messages[index] = message
            } else if let index = self.messages.firstIndex(where: { $0._id == message.tempId }) {
                if self.messages[index].localImage != nil {
                    var newMessage = message
                    newMessage.localImage = self.messages[index].localImage
                    self.messages[index] = newMessage
                } else {
                    self.messages[index] = message
                }
            } else {
                
                self.messages.append(message)
            }
        }
    }
    
    private func saveMessages(messages: [Message], completion: @escaping () -> Void) {
        for message in messages {
            saveMessage(message: message) {
                completion()
            }
        }
    }
    
    private func saveMessage(message: Message, completion: @escaping () ->  Void) {
        self.updateMessagesArray(message)
        guard message.status != .sending else {
            completion()
            return
        }

        do {
            let readByJson = try JSONEncoder().encode(message.readBy)
            let readByString = String(data: readByJson, encoding: .utf8) ?? "[]"

            if let existingMessage = try db.pluck(messagesTable.filter(_id == message._id)) {
                try db.run(messagesTable.filter(_id == message._id).update(
                    text <- message.text,
                    video <- message.video,
                    image <- message.image,
                    sender <- message.sender,
                    voiceMessage <- message.voiceMessage,
                    duration <- message.duration,
                    createdAt <- message.createdAt,
                    conversationId <- message.conversationId,
                    readBy <- readByString,
                    status <- message.status?.rawValue,
                    isSystemMessage <- message.isSystemMessage
                ))
            } else if let existingTempMessage = try db.pluck(messagesTable.filter(_id == message.tempId)) {
                try db.run(messagesTable.filter(_id == message.tempId).update(
                    text <- message.text,
                    video <- message.video,
                    image <- message.image,
                    sender <- message.sender,
                    voiceMessage <- message.voiceMessage,
                    duration <- message.duration,
                    createdAt <- message.createdAt,
                    conversationId <- message.conversationId,
                    readBy <- readByString,
                    status <- message.status?.rawValue,
                    _id <- message._id,  // Update the tempId to actual _id
                    isSystemMessage <- message.isSystemMessage
                ))
            } else {
                try db.run(messagesTable.insert(
                    _id <- message._id,
                    text <- message.text,
                    video <- message.video,
                    image <- message.image,
                    sender <- message.sender,
                    voiceMessage <- message.voiceMessage,
                    duration <- message.duration,
                    createdAt <- message.createdAt,
                    conversationId <- message.conversationId,
                    readBy <- readByString,
                    status <- message.status?.rawValue,
                    isSystemMessage <- message.isSystemMessage
                ))
            }
        } catch {
            print("Error saving message to SQLite: \(error)")
        }
        completion()
    }

    func loadMoreMessages(_ conversationId: String) {
        guard let page = messagesPage[conversationId], page != -1, !isFetching else {
            return
        }
        
        let newMessages = self.loadMessagesFromStorage(batchSize: 30, conversationId: conversationId)
        
        let filteredNewMessages = newMessages.filter { newMessage in
            !self.messages.contains(where: { $0._id == newMessage._id })
        }
        
        self.messages.insert(contentsOf: filteredNewMessages, at: 0)
    }
    
    func loadMessagesFromStorage(batchSize: Int, conversationId: String) -> [Message] {
            guard let page = messagesPage[conversationId], page != -1, !isFetching else {
                return []
            }

            isFetching = true
            let skip = (page - 1) * batchSize

            var messages: [Message] = []

        do {
             let messagesTable = Table("messages")
             let _id = Expression<String>("_id")
             let text = Expression<String?>("text")
             let sender = Expression<String?>("sender")
             let video = Expression<String?>("video")
             let image = Expression<String?>("image")
             let voiceMessage = Expression<String?>("voiceMessage")
             let duration = Expression<Int?>("duration")
             let createdAt = Expression<String?>("createdAt")
             let conversationIdExpression = Expression<String>("conversationId")
             let readBy = Expression<String>("readBy")
             let status = Expression<String?>("status")
             let isSystemMessage = Expression<Bool?>("isSystemMessage")
            
             let query = messagesTable
                 .filter(conversationIdExpression == conversationId)
                 .order(createdAt.desc)
                 .limit(batchSize, offset: skip)

             for row in try db.prepare(query) {
                 let statusString = row[status] ?? "sent"
                 if let readByData = row[readBy].data(using: .utf8),
                    let readByArray = try? JSONDecoder().decode([String].self, from: readByData),
                    let messageStatus = Status(rawValue: statusString) {
                        let message = Message(
                            conversationId: row[conversationIdExpression],
                            sender: row[sender],
                            text: row[text],
                            readBy: readByArray,
                            _id: row[_id],
                            voiceMessage: row[voiceMessage],
                            duration: row[duration],
                            video: row[video],
                            image: row[image],
                            createdAt: row[createdAt],
                            status: messageStatus,
                            isSystemMessage: row[isSystemMessage]
                        )
                        messages.append(message)
                        
                    }
                }

                updatePaginationState(messages.count, conversationId: conversationId, batchSize: batchSize)

                self.isFetching = false
            } catch {
                print("Error fetching messages from SQLite: \(error)")
                self.isFetching = false
            }

        return messages.reversed()
        }

    private func updatePaginationState(_ fetchedCount: Int, conversationId: String, batchSize: Int) {
        if fetchedCount < batchSize {
            self.messagesPage[conversationId] = -1
        } else if self.messagesPage.keys.contains(where: { $0 == conversationId }) {
            self.messagesPage[conversationId]! += 1
        } else {
            self.messagesPage[conversationId] = 1
        }
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
            DispatchQueue.main.async {
                self.socketConnected = true
            }
            self.fetchUnreadMessages {
                completion()
            }
        }
        
        socket.on("Message") { data, ack in
            if let messageData = data.first as? [String: Any],
               var message = Message(dictionary: messageData) {
                DispatchQueue.main.async {
                    message.status = .sent
                    self.saveMessage(message: message) {
                        if message.sender != _id {
                            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                        }
                        if let currentConversationId = self.currentConversationId, currentConversationId == message.conversationId {
                            self.markAsRead()
                        }
                    }
                }
            }
        }
        
        socket.on(clientEvent: .disconnect) { data, ack in
            print("Socket disconnected")
            DispatchQueue.main.async {
                self.socketConnected = false
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
    
    private func fetchUnreadMessages(completion: @escaping () -> Void) {
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
        
        let url = "\(backendURL)/message/fetchUnread/"
        AF.request(url, method: .get, headers: headers)
            .validate()
            .responseDecodable(of: [Message].self) { response in
                DispatchQueue.main.async {
                    switch response.result {
                    case .success(let newMessages):
                        DispatchQueue.main.async {
                            newMessages.forEach { message in
                                var newMessage = message
                                newMessage.status = .sent
                                self.saveMessage(message: newMessage) {
                                    completion()
                                }
                            }
                        }
                    case .failure(let error):
                        print("Failed to fetch new messages: \(error.localizedDescription)")
                        completion()
                    }
                }
            }
    }
    
    func sendTextMessage(text: String) {
        guard text.trimmingCharacters(in: .whitespacesAndNewlines) != "" else {
            return
        }
        
        guard let conversationId = currentConversationId else {
            return
        }
        
        guard let senderId = UserDefaults.standard.string(forKey: "_id") else {
            print("User Id not set")
            return
        }
        
        let uuid = UUID()
        let tempId = uuid.uuidString
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let currentDateString = dateFormatter.string(from: Date())
        
        var message = Message(
            conversationId: conversationId,
            sender: senderId,
            text: text,
            readBy: [senderId],
            _id: tempId,
            createdAt: currentDateString,
            status: .sending,
            tempId: tempId
        )
        let messageData: [String: Any] = [
            "conversationId": conversationId,
            "sender": senderId,
            "text": text,
            "tempId": tempId
        ]
        
        if !socketConnected {
            DispatchQueue.main.async {
                message.status = .failed
                self.saveMessage(message: message) {
                    return
                }
            }
        }
        
        self.saveMessage(message: message) {
            self.socket.emitWithAck("Message", messageData).timingOut(after: 5) { data in
                DispatchQueue.main.async {
                    if let response = data.first as? [String: Any] {
                        if let status = response["status"] as? String, status == "success" {
                        } else {
                            message.status = .failed
                            self.saveMessage(message: message) {}
                        }
                    } else {
                        message.status = .failed
                        self.saveMessage(message: message)  {}
                    }
                }
            }
        }
    }
    
    func unreadMessageCount(conversationId: String) -> Int  {
        guard let clientUserId = UserDefaults.standard.string(forKey: "_id") else {
            print("User Id not set")
            return 0
        }
        
        let unreadMessages = messages.filter {
            $0.conversationId == conversationId &&
            !$0.readBy.contains(clientUserId) &&
            $0.sender != clientUserId
        }
        
        // Return the count of unread messages
        return unreadMessages.count
    }
    
    func lastMessage(conversationId: String) -> Message? {
        return messages.filter{ $0.conversationId == conversationId }.last
    }
    
    func markAsRead() {
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            print("Backend URL not set")
            return
        }
        
        guard let conversationId = currentConversationId else {
            print("Current conversation id not set")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not set")
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        let parameters: [String: Any] = ["conversationId": conversationId]
        
        let url = "\(backendURL)/message/markRead/"
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers )
            .validate()
            .responseDecodable(of: String.self) { response in
                switch response.result {
                case .success:
                    DispatchQueue.main.async {
                        self.markCachedMessagesAsRead(conversationId: conversationId)
                    }
                case .failure(let error):
                    print("Failed to mark messages as read: \(error.localizedDescription)")
                }
            }
    }
    
    func markCachedMessagesAsRead(conversationId: String) {
        guard let clientUserId = UserDefaults.standard.string(forKey: "_id") else {
            print("User Id not set")
            return
        }
        
        for (index, message) in messages.enumerated() {
            if message.conversationId == conversationId && !message.readBy.contains(clientUserId) && message.sender != clientUserId {
                DispatchQueue.main.async {
                    var updatedMessage = message
                    updatedMessage.readBy.append(clientUserId)
                    self.messages[index] = updatedMessage
                    self.saveMessage(message: updatedMessage) {}
                }
            }
        }
    }
    
    func sendMediaMultiple(assets: [TLPHAsset]) {
        for asset in assets {
             sendMedia(asset: asset)
         }
    }
    
    func sendMedia(asset: TLPHAsset) {
        guard let conversationId = currentConversationId else {
            return
        }
        
        guard let senderId = UserDefaults.standard.string(forKey: "_id") else {
            print("User Id not set")
            return
        }
        
        let uuid = UUID()
        let tempId = uuid.uuidString
        
        var message = Message(
            conversationId: conversationId,
            sender: senderId,
            readBy: [senderId],
            _id: tempId,
            createdAt: String(Date().timeIntervalSince1970),
            status: .sending,
            tempId: tempId
        )
        
        if asset.type == .video {
            
        } else if asset.type == .photo {
            message.localImage = asset
        }
        
        if !self.socketConnected {
            DispatchQueue.main.async {
                message.status = .failed
                self.saveMessage(message: message) {
                    return
                }
            }
        }
        
        DispatchQueue.main.async {
            self.saveMessage(message: message) {}
        }
        
        self.uploadMedia(asset: asset) { mediaURL in
            if let mediaURL = mediaURL, mediaURL != "" {
                var messageData: [String: Any] = [
                    "conversationId": conversationId,
                    "sender": senderId,
                    "tempId": tempId,
                ]
                
                if asset.type == .video {
                    messageData["video"] = mediaURL
                } else if asset.type == .photo {
                    messageData["image"] = mediaURL
                }
                
                if !self.socketConnected {
                    DispatchQueue.main.async {
                        message.status = .failed
                        self.saveMessage(message: message) {
                            return
                        }
                    }
                }
                
                self.socket.emitWithAck("Message", messageData).timingOut(after: 5) { data in
                    DispatchQueue.main.async {
                        if let response = data.first as? [String: Any] {
                            // Process response if needed
                            if let status = response["status"] as? String, status == "success" {
                                // Handle success if needed
                            } else {
                                // Handle failure if needed
                                message.status = .failed
                                self.saveMessage(message: message) {}
                            }
                        } else {
                            message.status = .failed
                            self.saveMessage(message: message) {}
                        }
                    }
                }
            }
        }
    }
    
    func uploadMedia(asset: TLPHAsset, completion: @escaping (String?) -> Void) {
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            completion(nil)
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not set")
            return
        }
        
         guard let phAsset = asset.phAsset else {
             completion(nil)
             return
         }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        // Use PHImageManager to fetch data of the asset
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        
        let mediaType = phAsset.mediaType
        let url = "\(backendURL)/media/upload"
        
        if mediaType == .image {
            // For images, fetch image data
            imageManager.requestImageData(for: phAsset, options: requestOptions) { (data, _, _, _) in
                guard let imageData = data else {
                    completion(nil)
                    return
                }
                
                // Use Alamofire to upload media
                AF.upload(multipartFormData: { multipartFormData in
                    multipartFormData.append(imageData, withName: "file", fileName: asset.originalFileName, mimeType: "image/jpeg")
                    // Add other fields if needed (e.g., parameters)
                }, to: url, headers: headers)
                .responseDecodable(of: String.self) { response in
                    switch response.result {
                    case .success (let mediaURL):
                        completion(mediaURL)
                    case .failure(let error):
                        print("Failed to mark messages as read: \(error.localizedDescription)")
                    }
                }
            }
        } else if mediaType == .video {
            // For videos, fetch AVAsset asynchronously
            imageManager.requestAVAsset(forVideo: phAsset, options: nil) { (avAsset, _, _) in
                guard let avAsset = avAsset else {
                    completion(nil)
                    return
                }
                
                // Export AVAsset to a temporary file URL
                let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetMediumQuality)
                exportSession?.outputFileType = AVFileType.mp4
                exportSession?.shouldOptimizeForNetworkUse = true
                
                let tempFileUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tempVideo.mp4")
                
                exportSession?.outputURL = tempFileUrl
                
                exportSession?.exportAsynchronously(completionHandler: {
                    switch exportSession?.status {
                        case .completed:
                            do {
                                let videoData = try Data(contentsOf: tempFileUrl)
                                
                                // Use Alamofire to upload video
                                AF.upload(multipartFormData: { multipartFormData in
                                    multipartFormData.append(videoData, withName: "file", fileName: asset.originalFileName, mimeType: "video/mp4")
                                    // Add other fields if needed (e.g., parameters)
                                }, to: url, headers: headers)
                                .responseDecodable(of: String.self) { response in
                                    switch response.result {
                                    case .success (let mediaURL):
                                        completion(mediaURL)
                                    case .failure(let error):
                                        print("Failed to mark messages as read: \(error.localizedDescription)")
                                    }
                                }
                            } catch {
                                print("Error converting AVAsset to Data: \(error)")
                                completion(nil)
                            }
                            
                        case .failed, .cancelled, .unknown, .waiting:
                            completion(nil)
                        @unknown default:
                            completion(nil)
                        }
                })
            }
        } else {
            completion(nil)
        }
    }
    
    func downloadChatHistory(_ conversationId: String, completion: @escaping () -> Void) {
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
        
        let parameters: [String: Any] = ["conversationId": conversationId]
        
        let url = "\(backendURL)/message/downloadChatHistory/\(conversationId)"
        AF.request(url, method: .get, encoding: JSONEncoding.default, headers: headers )
            .validate()
            .responseDecodable(of: [Message].self) { response in
               switch response.result {
               case .success(let messages):
                   DispatchQueue.main.async {
                       self.saveMessages(messages: messages) {
                           DispatchQueue.main.async {
                               self.loadFirstBatchOfMessages()
                               completion()
                           }
                       }
                   }
               case .failure(let error):
                   print("Failed to download chat history: \(error.localizedDescription)")
                   completion()
               }
           }
    }
    
    func deleteChatHistoryFromCache(_ conversationId: String, completion: @escaping () -> Void) {
        let messagesTable = Table("messages")
        let createdAt = Expression<String?>("createdAt")
        let conversationIdExpr = Expression<String>("conversationId")
   

        do {
            // Delete rows where conversationId matches
            let query = messagesTable.filter(conversationIdExpr == conversationId)
            try db.run(query.delete())
            print("Chat history deleted successfully")
            loadFirstBatchOfMessages()
            completion()
        } catch {
            print("Failed to delete chat history: \(error.localizedDescription)")
            completion()
        }
    }
    
    func sendAudioMessage(_ recordingURL: URL, duration: Int, completion: @escaping () -> Void) {
        guard let conversationId = currentConversationId else {
            return
        }
        
        guard let senderId = UserDefaults.standard.string(forKey: "_id") else {
            print("User Id not set")
            return
        }
        
        let uuid = UUID()
        let tempId = uuid.uuidString
        
        var message = Message(
            conversationId: conversationId,
            sender: senderId,
            readBy: [senderId],
            _id: tempId,
            localVoiceMessage: recordingURL,
            duration: duration,
            createdAt: String(Date().timeIntervalSince1970),
            status: .sending,
            tempId: tempId
        )
    
        if !self.socketConnected {
            DispatchQueue.main.async {
                message.status = .failed
                self.saveMessage(message: message) {
                    return
                }
            }
        }
        
        DispatchQueue.main.async {
            self.saveMessage(message: message) {}
        }
        
        uploadAudioFile(recordingURL: recordingURL) { mediaURL in
            if let mediaURL = mediaURL, mediaURL != "" {
                let messageData: [String: Any] = [
                    "conversationId": conversationId,
                    "sender": senderId,
                    "tempId": tempId,
                    "voiceMessage": mediaURL,
                    "duration": duration
                ]
                
                if !self.socketConnected {
                    DispatchQueue.main.async {
                        message.status = .failed
                        self.saveMessage(message: message) {
                            return
                        }
                    }
                }
                
                self.socket.emitWithAck("Message", messageData).timingOut(after: 5) { data in
                    DispatchQueue.main.async {
                        if let response = data.first as? [String: Any] {
                            // Process response if needed
                            if let status = response["status"] as? String, status == "success" {
                                // Handle success if needed
                            } else {
                                // Handle failure if needed
                                message.status = .failed
                                self.saveMessage(message: message) {}
                            }
                        } else {
                            message.status = .failed
                            self.saveMessage(message: message) {}
                        }
                    }
                }
            }
        }
    }
    
    private func uploadAudioFile(recordingURL: URL, completion: @escaping (String?) -> Void) {
            guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
                completion(nil)
                return
            }
            
            guard let token = UserDefaults.standard.string(forKey: "authToken") else {
                print("Auth token not set")
                return
            }
            
            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(token)"
            ]
        
            let url = "\(backendURL)/media/upload"
                    
        do {
            let fileData = try Data(contentsOf: recordingURL)
            
            // You can customize the body of your request based on your backend's API requirements
            let fileDataEncoded = fileData.base64EncodedString()
            let fileName = recordingURL.lastPathComponent
        
            // Use Alamofire to upload media
            AF.upload(multipartFormData: { multipartFormData in
                multipartFormData.append(fileData, withName: "file", fileName: fileName, mimeType: "audio/mpeg")
                // Add other fields if needed (e.g., parameters)
            }, to: url, headers: headers)
            .responseDecodable(of: String.self) { response in
                switch response.result {
                case .success (let mediaURL):
                    completion(mediaURL)
                case .failure(let error):
                    print("Failed to mark messages as read: \(error.localizedDescription)")
                }
            }
        }
        catch {
            print("Error loading file data: \(error.localizedDescription)")
            completion(nil)
        }
    }
}


