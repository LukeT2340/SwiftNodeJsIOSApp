//
//  ChatView.swift
//  Frontend
//
//  Created by Luke Thompson on 24/6/2024.
//

import SwiftUI

struct ChatView: View {
    @StateObject var voicePlayer = VoicePlayer()
    @State var conversationId: String
    @State var chatHasInitialized = false
    @EnvironmentObject var messagesManager: MessagesManager
    @EnvironmentObject var contactManager: ContactManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var conversationsManager: ConversationsManager
    @ObservedObject private var keyboardResponder = KeyboardResponder()
    @Environment(\.presentationMode) var presentationMode

    init (conversationId: String) {
        self.conversationId = conversationId
    }
    
    var body: some View {
        VStack (spacing: 0) {
            customNavBar
            messagesView
            ChatInput()
        }
        .navigationBarBackButtonHidden(true)
        .animation(.easeInOut, value: messagesManager.messages)
        .onAppear {
            messagesManager.currentConversationId = conversationsManager.conversations.first(where: { $0._id == conversationId })?._id
            messagesManager.markAsRead()
        }
        .onDisappear {
            messagesManager.currentConversationId = nil
        }
    }
    
    private var customNavBar: some View {
        let clientUserId = authManager.user?._id
        let currentConversation = conversationsManager.conversations.first(where: { $0._id == conversationId })
        let otherUserId = currentConversation?.participants.first(where: { $0 != clientUserId })
        let otherUser = contactManager.users.first(where: { $0._id == otherUserId })
        
        return HStack (spacing: 20) {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24))
                    .fontWeight(.medium)
            }
            if let currentConversation = currentConversation, currentConversation.participants.count <= 2 {
                VStack(alignment: .leading) {
                    if let otherUser = otherUser, let lastOnline = otherUser.lastOnline, let username = otherUser.username {
                        Text(username)
                            .font(.headline)
                        HStack(spacing: 3) {
                            let lastOnlineText = formatLastOnline(date: lastOnline)
                            if lastOnlineText == "Online" {
                                Image(systemName: "circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 10))
                            }
                            Text(lastOnlineText)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            } else {
                if let chatName = currentConversation?.chatName {
                    Text(chatName)
                        .font(.headline)
                } else {
                    Text(LocalizedStringKey("Group chat"))
                        .font(.headline)
                }
            }
            Spacer()
            NavigationLink(destination: ChatOptions(conversationId: conversationId)) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 24))
                    .fontWeight(.medium)
            }
        }
        .padding()
    }
    
    private var messagesView: some View {
        let messages = Array(messagesManager.messages.filter { $0.conversationId == conversationId }.reversed())
        let clientUser = authManager.user
        let clientUserId = clientUser?._id
        let currentConversation = conversationsManager.conversations.first(where: { $0._id == conversationId })
        
        return  ScrollView {
            ScrollViewReader { proxy in
                Spacer().frame(height: 5)
                ForEach(Array(messages.enumerated()), id: \.element._id) { index, message in
                    let previousMessage = (index < messages.count - 1) ? messages[index + 1] : nil
                    let showTimestamp = shouldShowTimestamp(currentMessage: message, previousMessage: previousMessage)
                    let user = message.sender == clientUserId ? clientUser : contactManager.users.first(where: {$0._id == message.sender})
                    MessageView(voicePlayer: voicePlayer, message: message, user: user, showTimestamp: showTimestamp)
                        .rotationEffect(.degrees(180))
                        .scaleEffect(x: -1, y: 1, anchor: .center)
                    
                }
                let messageCount = messages.count
                if messageCount % 30 != 0 || messageCount == 0 {
                    Text(LocalizedStringKey("This is the beginning of the chat history"))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical)
                        .rotationEffect(.degrees(180))
                        .scaleEffect(x: -1, y: 1, anchor: .center)
                }
            }
            .background(GeometryReader { geometry in
                  Color.clear
                  .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).origin)
                  })
              .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                  if value.y >= -300 {
                      messagesManager.loadMoreMessages(conversationId)
                  }
              }
        }
        .rotationEffect(.degrees(180))
        .scaleEffect(x: -1, y: 1, anchor: .center)
        .onTapGesture {
            keyboardResponder.hideKeyboard()
        }
    }
    
    private func formatLastOnline(date: String) -> LocalizedStringKey {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let providedDate = dateFormatter.date(from: date) else {
            return LocalizedStringKey("Unknown") // Return a default value for an invalid date string
        }
        
        let currentDate = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: providedDate, to: currentDate)
        
        if let year = components.year, year != 0 {
            return LocalizedStringKey(dateFormatter.string(from: providedDate))
        } else if let month = components.month, month != 0 {
            return LocalizedStringKey(dateFormatter.string(from: providedDate))
        } else if let day = components.day, day != 0 {
            return LocalizedStringKey(dateFormatter.string(from: providedDate))
        } else if let hour = components.hour, hour != 0 {
            return LocalizedStringKey(hour == 1 ? "\(hour) hour ago" : "\(hour) hours ago")
        } else if let minute = components.minute, minute != 0 {
            return LocalizedStringKey(minute == 1 ? "\(minute) minute ago" : "\(minute) minutes ago")
        } else {
            return LocalizedStringKey("Online")
        }
    }
    
    // Timestamps should only be shown when the current message and previous message are 5 or more minutes apart
    private func shouldShowTimestamp(currentMessage: Message, previousMessage: Message?) -> Bool {
        guard let previousTimestamp = previousMessage?.createdAt, let currentTimestamp = currentMessage.createdAt else {
            return true // Always show for the first message
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let currentMessageDate = dateFormatter.date(from: currentTimestamp), let previousMessageDate = dateFormatter.date(from: previousTimestamp) else {
            return true
        }
        let timeDifference = currentMessageDate.timeIntervalSince(previousMessageDate)
        return timeDifference > 5 * 60
    }

}
