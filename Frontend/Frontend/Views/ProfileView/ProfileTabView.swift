//
//  ProfileTabView.swift
//  Frontend
//
//  Created by Luke Thompson on 24/6/2024.
//

import SwiftUI

struct ProfileTabView: View {
    @State var user: User
    @State var newConversationId: String?
    @State var navigateToChat = false
    @EnvironmentObject var messagesManager: MessagesManager
    @EnvironmentObject var contactManager: ContactManager
    @EnvironmentObject var conversationsManager: ConversationsManager
    
    var body: some View {
            HStack {
                Spacer()
                NavigationLink(destination: EmptyView()) {
                    VStack (spacing: 10) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 30))
                        Text(LocalizedStringKey("Video"))
                            .font(.caption)
                    }
                }
                Spacer()
                NavigationLink(destination: EmptyView()) {
                    VStack (spacing: 10) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 30))
                        Text(LocalizedStringKey("Call"))
                            .font(.caption)
                    }
                }
                Spacer()
                if let clientId = UserDefaults.standard.string(forKey: "_id"), let index = conversationsManager.conversations.firstIndex(where: {$0.participants.contains(clientId) && $0.participants.contains(user._id) && $0.participants.count <= 2}) {
                    NavigationLink(destination: ChatView(conversationId: conversationsManager.conversations[index]._id)) {
                        VStack (spacing: 10) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 30))
                            Text(LocalizedStringKey("Message"))
                                .font(.caption)
                        }
                    }
                } else {
                    Button (action: {
                        conversationsManager.createNewConversation(userId: user._id) { conversationId in
                            if let conversationId = conversationId {
                                DispatchQueue.main.async {
                                    self.newConversationId = conversationId
                                    self.conversationsManager.refreshConversations {
                                        self.contactManager.fetchUsers() {
                                            self.contactManager.updateLastOnline()
                                            self.navigateToChat = true
                                        }
                                    }
                                }
                            }
                        }
                    }) {
                        VStack (spacing: 10) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 30))
                            Text(LocalizedStringKey("Message"))
                                .font(.caption)
                        }
                    }
                }
                Spacer()
            }
            .padding(.top)
            .padding(.horizontal)
            .background(.ultraThinMaterial)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .navigationDestination(isPresented: $navigateToChat) {
                 if let conversationId = newConversationId {
                     ChatView(conversationId: conversationId)
                 }
             }
        }
}

struct ProfileTabView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileTabView(user: User(
            _id: "1",
            username: "Luke",
            email: "example@example.com",
            profilePictureUrl: "https://firebasestorage.googleapis.com/v0/b/mylanguageapp-b7504.appspot.com/o/profileImages%2Fimage0.jpeg?alt=media&token=4dae410d-d28c-4172-8ac0-a166ab62cada",
            targetLanguages: [User.Language(language: "Mandarin", proficiency: 4)],
            nativeLanguages: ["English"],
            bio: "This is a sample bio.",
            createdAt: "2024-06-23T11:11:55.001Z"
        ))
            .previewLayout(.sizeThatFits)
            .frame(maxWidth: .infinity)
    }
}
