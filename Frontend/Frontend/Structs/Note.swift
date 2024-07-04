//
//  File.swift
//  Frontend
//
//  Created by Luke Thompson on 3/7/2024.
//

import Foundation

struct Note: Decodable {
    let _id: String
    let author: String
    let textContent: String?
    let mediaContent: [Media]?
    var commentCount: Int
    var likeCount: Int
    let editedAt: String?
    let createdAt: String
    let hasLiked: Bool?
}

struct Media: Decodable {
    let _id: String?
    let url: String
    let duration: Int?
    let mediaType: String
}


struct NotePackage: Decodable {
    var note: Note
    var author: User
    var commentsAndAuthors: [CommentAndAuthor]
}

struct CommentAndAuthor: Decodable {
    var author: User
    var comment: Comment
}

struct Comment: Decodable {
    var _id: String
    var userId: String
    var noteId: String
    var textContent: String
    var createdAt: String
    var likeCount: Int
    var hasLiked: Bool
}


struct CreateNoteMediaRequest: Decodable {
    var url: String
    var duration: Int?
    var mediaType: String
}
