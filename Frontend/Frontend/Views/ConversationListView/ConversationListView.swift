//
//  ConversationListView.swift
//  Frontend
//
//  Created by Luke Thompson on 24/6/2024.
//

import SwiftUI

struct ConversationListView: View {
    @EnvironmentObject var messagesManager: MessagesManager
    @EnvironmentObject var contactManager: ContactManager
    @EnvironmentObject var conversationsManager: ConversationsManager
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack {
            topBar
            List {
                // Get the conversations from the manager
                let conversations = conversationsManager.conversations
                
                let sortedConversations = conversations.sorted { (conv1, conv2) in
                    func mostRecentCreatedAt(for conversationId: String) -> String? {
                        let messagesForConversation = messagesManager.messages.filter { $0.conversationId == conversationId }
                        guard let mostRecentMessage = messagesForConversation.max(by: { message1, message2 in
                            if let createdAt1 = message1.createdAt, let createdAt2 = message2.createdAt {
                                return createdAt1 < createdAt2
                            } else if message1.createdAt != nil {
                                return true
                            } else {
                                return false
                            }
                        }) else {
                            return nil
                        }
                        return mostRecentMessage.createdAt
                    }

                    
                    guard let timestamp1 = mostRecentCreatedAt(for: conv1._id),
                          let timestamp2 = mostRecentCreatedAt(for: conv2._id) else {
                        return false
                    }
                    
                    return timestamp1 > timestamp2
                }
                                
                ForEach(sortedConversations, id: \.self) { conversation in
                    let clientUserId = UserDefaults.standard.string(forKey: "_id")
                    let participants = conversation.participants
                    // Handle chats between two users
                    if participants.count <= 2 {
                        if let user = contactManager.users.first(where: { $0._id != clientUserId && participants.contains($0._id) }) {
                            let unreadCount = messagesManager.unreadMessageCount(conversationId: conversation._id)
                            
                            NavigationLink(destination: ChatView(conversationId: conversation._id)) {
                                ConversationRow(user: user, lastMessage: messagesManager.lastMessage(conversationId: conversation._id), unreadCount: unreadCount)        
                            }
                        }
                    // Handle group chats
                    } else {
                        let users = contactManager.users.filter {participants.contains($0._id)}
                        let unreadCount = messagesManager.unreadMessageCount(conversationId: conversation._id)
                        let chatName = conversation.chatName
                        NavigationLink(destination: ChatView(conversationId: conversation._id)) {
                            GroupChatRow(users: users, chatName: chatName, lastMessage: messagesManager.lastMessage(conversationId: conversation._id), unreadCount: unreadCount)
                        }
                    }
                }
            }
            .listStyle(.inset)
        }
    }
    
    private var topBar: some View {
        HStack {
            let isFetching = contactManager.isFetching || messagesManager.isFetching || authManager.isFetching || !messagesManager.socketConnected || !contactManager.socketConnected
            if isFetching {
                LoadingView()
            }
            Text(isFetching ? LocalizedStringKey("Fetching") : LocalizedStringKey("Messages"))
        }
    }
    
    
}
