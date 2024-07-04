//
//  Message.swift
//  Frontend
//
//  Created by Luke Thompson on 24/6/2024.
//

import Foundation
import SwiftUI
import TLPhotoPicker

enum Status: String, Codable {
    case sent
    case sending
    case failed
}

struct Message: Codable, Equatable {
    var _id: String
    var conversationId: String
    var sender: String?
    var receiver: String?
    var text: String?
    var voiceMessage: String?
    var localVoiceMessage: URL?
    var duration: Int?
    var readBy: [String]
    var video: String?
    var image: String?
    var createdAt: String?
    var status: Status?
    var tempId: String?
    var localImage: TLPHAsset?
    var isSystemMessage: Bool?
    
    init(conversationId: String, sender: String? = nil, text: String? = nil, readBy: [String], _id: String, receiver: String? = nil, voiceMessage: String? = nil, localVoiceMessage: URL? = nil, duration: Int? = nil, video: String? = nil, image: String? = nil, createdAt: String? = nil, status: Status? = nil, tempId: String? = nil, localImage: TLPHAsset? = nil, isSystemMessage: Bool? = nil) {
        self._id = _id
        self.conversationId = conversationId
        self.sender = sender
        self.receiver = receiver
        self.text = text
        self.voiceMessage = voiceMessage
        self.localVoiceMessage = localVoiceMessage
        self.duration = duration
        self.readBy = readBy
        self.video = video
        self.image = image
        self.createdAt = createdAt
        self.status = status
        self.localImage = localImage
        self.isSystemMessage = isSystemMessage
    }

    init?(dictionary: [String: Any]) {
        guard
            let _id = dictionary["_id"] as? String,
            let conversationId = dictionary["conversationId"] as? String,
            let readBy = dictionary["readBy"] as? [String],
            let createdAt = dictionary["createdAt"] as? String
        else {
            return nil
        }

        self._id = _id
        self.sender = dictionary["sender"] as? String
        self.conversationId = conversationId
        self.receiver = dictionary["receiver"] as? String
        self.text = dictionary["text"] as? String
        self.voiceMessage = dictionary["voiceMessage"] as? String
        self.localVoiceMessage = dictionary["localVoiceMessage"] as? URL
        self.duration = dictionary["duration"] as? Int
        self.readBy = readBy
        self.video = dictionary["video"] as? String
        self.image = dictionary["image"] as? String
        // Handle isSystemMessage as Bool or Int
           if let isSystemMessage = dictionary["isSystemMessage"] as? Bool {
               self.isSystemMessage = isSystemMessage
           } else if let isSystemMessage = dictionary["isSystemMessage"] as? Int {
               self.isSystemMessage = isSystemMessage == 1
           } else if let isSystemMessageString = dictionary["isSystemMessage"] as? String {
               self.isSystemMessage = (isSystemMessageString == "true" || isSystemMessageString == "1")
           } else {
               self.isSystemMessage = nil
           }
        self.createdAt = createdAt
        
        if let statusString = dictionary["status"] as? String {
            self.status = Status(rawValue: statusString) ?? .sent
        } else {
            self.status = .sent
        }
        self.tempId = dictionary["tempId"] as? String
        self.localImage = nil
    }
    
       enum CodingKeys: String, CodingKey {
           case _id
           case conversationId
           case sender
           case receiver
           case text
           case voiceMessage
           case duration
           case readBy
           case video
           case image
           case createdAt
           case status
           case tempId
           case isSystemMessage
       }
}
