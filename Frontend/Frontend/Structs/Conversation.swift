//
//  Conversation.swift
//  Frontend
//
//  Created by Luke Thompson on 24/6/2024.
//

import Foundation

struct Conversation: Codable, Hashable {
    var _id: String
    var creator: String
    var participants: [String]
    var chatName: String?
    var createdAt: String
    
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
         return lhs._id == rhs._id
     }
}
