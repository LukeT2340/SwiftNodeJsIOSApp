//
//  User.swift
//  Frontend
//
//  Created by Luke Thompson on 24/6/2024.
//

import Foundation

struct UserAndToken: Codable {
    var user: User
    var token: String
}

struct User: Codable{
    var _id: String
    var username: String?
    var email: String?
    var profilePictureUrl: String?
    var targetLanguages: [Language]?
    var nativeLanguages: [String]?
    var country: String?
    var bio: String?
    var createdAt: String?
    var lastOnline: String?
    var sex: String?
    var idealLanguagePartner: String?
    var hobbies: [String]?
    var languageGoals: String?
    
    struct Language: Codable {
        var language: String
        var proficiency: Int
    }
}

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs._id == rhs._id
    }
}
