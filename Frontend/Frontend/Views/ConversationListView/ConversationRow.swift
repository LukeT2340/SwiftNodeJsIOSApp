//
//  ConversationRow.swift
//  Frontend
//
//  Created by Luke Thompson on 24/6/2024.
//

import SwiftUI
import Kingfisher

struct ConversationRow: View {
    var user: User?
    var chatName: String?
    var lastMessage: Message?
    var unreadCount: Int
    
    var body: some View {
        HStack {
            if let profilePictureUrl = user?.profilePictureUrl, let url = URL(string: profilePictureUrl) {
                ZStack {
                     Group {
                         KFImage(url)
                             .resizable()
                             .aspectRatio(contentMode: .fill)
                             .frame(width: 60, height: 60)
                             .clipped()
                             .clipShape(RoundedRectangle(cornerRadius: 5))
                     
                     }
                     if unreadCount > 0 {
                         Text("\(unreadCount)")
                             .font(.caption)
                             .foregroundColor(.white)
                             .padding(5)
                             .background(Color.red)
                             .clipShape(Circle())
                             .offset(x: 25, y: -25)
                     }
                     
                 }
            }
            VStack(alignment: .leading) {
                if let chatName = chatName {
                    Text(chatName)
                        .font(.headline)
                } else if let username = user?.username {
                    Text(username)
                        .font(.headline)
                }
                
                if let lastMessage = lastMessage {
                    if let lastMessageText = lastMessage.text {
                        Text(lastMessageText)
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    } else if lastMessage.image != nil || lastMessage.localImage != nil {
                        Text(LocalizedStringKey("[Image]"))
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else if lastMessage.video != nil {
                        Text(LocalizedStringKey("[Video]"))
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else if lastMessage.voiceMessage != nil {
                        Text(LocalizedStringKey("[Voice Message]"))
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
            }
            .padding(.leading, 8)
            Spacer()
            if let lastMessage = lastMessage, let timestamp = lastMessage.createdAt {
                Text(formatDate(date: timestamp) ?? "")
                    .lineLimit(1)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .swipeActions {
            Button(action: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation {
                        
                    }
                }
            }) {
                Image(systemName: "star.fill")
            }
            .tint(.green)
            
            Button(action: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation {
                        
                    }
                }
            }) {
                Image(systemName: "bell.slash.fill")
            }
            .tint(.gray)
            
            Button(role: .destructive, action: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation {
                        
                    }
                }
            }) {
                Image(systemName: "eye.slash.fill")
            }
            .tint(.orange)
        }
    }
    
    private func formatDate(date: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let providedDate = dateFormatter.date(from: date) else {
            return nil // Return nil if the provided date string is invalid
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
