//
//  CommentView.swift
//  Frontend
//
//  Created by Luke Thompson on 4/7/2024.
//

import SwiftUI

struct CommentView: View {
    @EnvironmentObject var notesManager: NotesManager
    var commentAndAuthor: CommentAndAuthor
    var body: some View {
        VStack {
            user
            comment
            feedBack
        }
    }
    
    @ViewBuilder
    private var user: some View {
        HStack {
            UserPreview(user: commentAndAuthor.author)
        }
    }
    
    @ViewBuilder
    private var comment: some View {
        VStack {
            Text(commentAndAuthor.comment.textContent)
            Text(commentAndAuthor.comment.createdAt)
        }
    }
    
    @ViewBuilder
    private var feedBack: some View {
        HStack {
            Spacer()
            Button(action: {
                if commentAndAuthor.comment.hasLiked {
                    notesManager.unlikeCommet(commentId: commentAndAuthor.comment._id) {
                        
                    }
                } else {
                    notesManager.likeCommet(commentId: commentAndAuthor.comment._id) {
                        
                    }
                }
            }) {
                HStack (spacing: 3) {
                    Image(systemName: commentAndAuthor.comment.hasLiked ? "heart.fill" : "heart")
                        .foregroundColor(commentAndAuthor.comment.hasLiked ? Color.red : Color.gray)
                    Text("\(commentAndAuthor.comment.likeCount)")
                }
            }
        }
    }
}
