//
//  GroupChatRow.swift
//  Frontend
//
//  Created by Luke Thompson on 30/6/2024.
//

import SwiftUI
import Kingfisher

struct GroupChatRow: View {
    var users: [User]
    var chatName: String?
    var lastMessage: Message?
    var unreadCount: Int
    
    var body: some View {
        HStack {
            picture
            titleAndLastMessage
            Spacer()
            timestamp
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
    
    private var picture: some View {
        ZStack {
            VStack {
                let lastMessageProfilePicture = users.first(where: { $0._id == lastMessage?.sender })?.profilePictureUrl
                var otherProfilePictures = users
                    .filter { $0.profilePictureUrl != lastMessageProfilePicture }
                    .map { $0.profilePictureUrl }
                
                HStack(spacing: 0) {
                    Spacer()
                    
                    // Display last message profile picture
                    if let lastMessageProfilePicture = lastMessageProfilePicture, let url = URL(string: lastMessageProfilePicture) {
                        KFImage(url)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 40)
                    }
                    
                    // Display other profile pictures
                    ForEach(otherProfilePictures, id: \.self) { profilePictureUrl in
                        if let profilePictureUrl = profilePictureUrl, let url = URL(string: profilePictureUrl) {
                            KFImage(url)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 20, height: 20) // Adjusted height for consistency
                        }
                    }
                    
                    Spacer()
                }
            }
            .frame(width: 60, height: 60)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 5))
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
    
    private var titleAndLastMessage: some View {
        VStack(alignment: .leading) {
            if let chatName = chatName {
                Text(chatName)
                    .font(.headline)
            } else {
                let usersCount = users.count
                let lastMessageUser = users.first(where: {$0._id == lastMessage?.sender})
                if let username = lastMessageUser?.username {
                    HStack (spacing: 5) {
                        Text(LocalizedStringKey("\(username)"))
                            .font(.headline)
                            .lineLimit(1)

                        Text(LocalizedStringKey("+\(usersCount-1) others"))
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if users.count > 0, let username = users[0].username {
                    HStack (spacing: 5) {
                        Text(LocalizedStringKey("\(username)"))
                            .font(.headline)
                            .lineLimit(1)

                        Text(LocalizedStringKey("+\(usersCount-1) others"))
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
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
    }

    @ViewBuilder
    private var timestamp: some View {
        if let lastMessage = lastMessage, let timestamp = lastMessage.createdAt {
            Text(formatDate(date: timestamp) ?? "")
                .lineLimit(1)
                .font(.subheadline)
                .foregroundColor(.secondary)
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
