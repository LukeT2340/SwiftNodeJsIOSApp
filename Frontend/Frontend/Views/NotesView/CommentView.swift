//
//  CommentView.swift
//  Frontend
//
//  Created by Luke Thompson on 4/7/2024.
//

import SwiftUI

struct CommentView: View {
    @EnvironmentObject var notesManager: NotesManager
    @EnvironmentObject var profileInfoManager: ProfileInfoManager
    
    var commentAndAuthor: CommentAndAuthor
    var isViewingFromProfileView: Bool
    var body: some View {
        VStack (alignment: .leading, spacing: 15) {
            Divider()
            UserPreview(user: commentAndAuthor.author)
            comment
            feedBack
        }
    }
    
    @ViewBuilder
    private var comment: some View {
        Text(commentAndAuthor.comment.textContent)
        
    }
    
    @ViewBuilder
    private var feedBack: some View {
        HStack {
            Text(formatDate(date: commentAndAuthor.comment.createdAt))
            Spacer()
            Button(action: {
                if commentAndAuthor.comment.hasLiked {
                    notesManager.unlikeCommet(commentId: commentAndAuthor.comment._id) { comment in
                        if let comment = comment {
                            if isViewingFromProfileView {
                                profileInfoManager.updateComment(comment)
                            } else {
                                notesManager.updateComment(comment)
                            }
                        }
                    }
                } else {
                    notesManager.likeCommet(commentId: commentAndAuthor.comment._id) { comment in
                        if let comment = comment {
                            if isViewingFromProfileView {
                                profileInfoManager.updateComment(comment)
                            } else {
                                notesManager.updateComment(comment)
                            }
                        }
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
        .foregroundColor(Color.gray)
    }
    
    private func formatDate(date: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let providedDate = dateFormatter.date(from: date) else {
            return ""
        }
        
        let currentDate = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: providedDate, to: currentDate)
        
        if let year = components.year, year != 0 {
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            return dateFormatter.string(from: providedDate)
        } else if let month = components.month, month != 0 {
            dateFormatter.dateFormat = "MMM dd HH:mm:ss.SSS"
            return dateFormatter.string(from: providedDate)
        } else if let day = components.day, day != 0 {
            dateFormatter.dateFormat = "MMM dd HH:mm:ss.SSS"
            return dateFormatter.string(from: providedDate)
        } else if let hour = components.hour, hour != 0 {
            if hour == 1 {
                return "\(hour) hour ago"
            } else {
                return "\(hour) hours ago"
            }
        } else if let minute = components.minute, minute != 0 {
            if minute == 1 {
                return "\(minute) minute ago"
            } else {
                return "\(minute) minutes ago"
            }
        } else {
            return "Just now"
        }
    }
}
