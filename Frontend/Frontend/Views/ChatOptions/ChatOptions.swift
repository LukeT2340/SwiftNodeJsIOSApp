//
//  ChatOptions.swift
//  Frontend
//
//  Created by Luke Thompson on 29/6/2024.
//

import SwiftUI
import Kingfisher

struct ChatOptions: View {
    @State private var showEditGroupNameSheet = false
    var conversationId: String
    @EnvironmentObject var messagesManager: MessagesManager
    @EnvironmentObject var contactManager: ContactManager
    @EnvironmentObject var conversationsManager: ConversationsManager
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        VStack {
            navigationBar
            VStack {
                ScrollView {
                    chatName
                    participants
                    searchChatHistory
                    downloadEntireChatHistory
                    deleteChatHistory
                }
                Spacer()
            }
            .padding()
            Spacer()
        }
        .navigationBarBackButtonHidden()
        .sheet(isPresented: $showEditGroupNameSheet) {
            ChangeGroupChatNameSheet(conversationId: conversationId)
        }
    }
    
    private var navigationBar: some View {
        ZStack {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24))
                    .fontWeight(.medium)
            }.frame(maxWidth: .infinity, alignment: .leading)
            Text(LocalizedStringKey("Chat details")).frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal)
        
    }
    
    @ViewBuilder
    private var chatName: some View {
        let conversation = conversationsManager.conversations.first(where: {$0._id == conversationId})
        let clientId = UserDefaults.standard.string(forKey: "_id")
        let isCreator = conversation?.creator == clientId
        if let chatName = conversation?.chatName, isCreator {
            Button(action: {
                showEditGroupNameSheet = true
            }) {
                HStack {
                    Text(LocalizedStringKey("Group chat name: "))
                    Text(chatName)
                    Spacer()
                    Image(systemName: "rectangle.3.group.bubble")
                }
                .foregroundColor(.primary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(8)
        } else if let chatName = conversation?.chatName {
            HStack {
                Text(LocalizedStringKey("Group chat name: "))
                Text(chatName)
            }
            .foregroundColor(.primary)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(8)
        } else if isCreator {
            Button(action: {
                showEditGroupNameSheet = true
            }) {
                HStack {
                    Text(LocalizedStringKey("Change group chat name"))
                    Spacer()
                    Image(systemName: "rectangle.3.group.bubble")
                }
                .foregroundColor(.primary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(8)
        }
    }
    
    private var participants: some View {
        HStack {
            profilePicture
            addMorePeopleButton
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        
    }
    
    @ViewBuilder
    private var addMorePeopleButton: some View {
        NavigationLink(destination: AddUsersToConversationView(conversationId: conversationId)) {
            ZStack {
                Rectangle()
                    .frame(width: 60, height: 60)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .foregroundColor(Color.gray.opacity(0.4))
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
    }
    
    @ViewBuilder
    private var profilePicture: some View {
        let currentConversation = conversationsManager.conversations.first(where: { $0._id == conversationId })
        let userIds = currentConversation?.participants
        
        if let userIds = userIds {
            let users = contactManager.users.filter { userIds.contains($0._id) }
            
            // Sort users by lastOnline date
            let sortedUsers = users.sorted { user1, user2 in
                guard let date1 = dateFromString(user1.lastOnline), let date2 = dateFromString(user2.lastOnline) else {
                    return false
                }
                return date1 > date2
            }
            
            ForEach(sortedUsers, id: \._id) { user in
                if let urlString = user.profilePictureUrl, let url = URL(string: urlString) {
                    NavigationLink(destination: ProfileView(user: user)) {
                        ZStack {
                            KFImage(url)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                            
                            if isOnline(lastOnline: user.lastOnline) {
                                Circle()
                                    .foregroundColor(.green)
                                    .offset(x: 26, y: 26)
                                    .frame(width: 12, height: 12)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var searchChatHistory: some View {
        NavigationLink(destination: EmptyView()) {
            HStack {
                Text(LocalizedStringKey("Search chat history"))
                Spacer()
                Image(systemName: "magnifyingglass")
            }
            .foregroundColor(.primary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
    
    private var downloadEntireChatHistory: some View {
        Button(action: {
            messagesManager.downloadChatHistory(conversationId) {
                presentationMode.wrappedValue.dismiss()
            }
        }){
            HStack {
                Text(LocalizedStringKey("Download chat history"))
                Spacer()
                Image(systemName: "arrow.down.circle")
            }
            .foregroundColor(.primary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }

    @ViewBuilder
    private var deleteChatHistory: some View {
        if messagesManager.messages.filter({$0.conversationId == conversationId}).count != 0 {
            Button(action: {
                messagesManager.deleteChatHistoryFromCache(conversationId) {
                    presentationMode.wrappedValue.dismiss()
                }
            }){
                HStack {
                    Text(LocalizedStringKey("Delete chat history"))
                    Spacer()
                    Image(systemName: "delete.left")
                }
                .foregroundColor(.primary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(8)
        }
    }
    
    private func dateFromString(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = dateFormatter.date(from: dateString) {
            return date
        } else {
            if let dotIndex = dateString.firstIndex(of: ".") {
                let substringWithoutMilliseconds = String(dateString.prefix(upTo: dotIndex)) + "Z"
                return dateFormatter.date(from: substringWithoutMilliseconds)
            }
        }
        
        return nil
    }


    private func isOnline(lastOnline: String?) -> Bool {
        guard let lastOnline = lastOnline, let lastOnlineDate = dateFromString(lastOnline) else {
            return false
        }
        
        let currentDate = Date()
        let difference = currentDate.timeIntervalSince(lastOnlineDate)
        
        // Check if the difference is within 3 minutes (180 seconds)
        return difference <= 180
    }}

struct ChatOptions_Previews: PreviewProvider {
    static var previews: some View {
        // Create mock data
        let messagesManager = MessagesManager()
        let contactManager = ContactManager()
        let conversationsManager = ConversationsManager()
        
        // Provide mock data to the preview
        ChatOptions(conversationId: "test")
            .environmentObject(messagesManager)
            .environmentObject(contactManager)
            .environmentObject(conversationsManager)
    }
}
