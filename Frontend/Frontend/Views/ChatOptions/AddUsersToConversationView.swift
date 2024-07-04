//
//  AddUsersToConversationView.swift
//  Frontend
//
//  Created by Luke Thompson on 30/6/2024.
//

import SwiftUI

struct AddUsersToConversationView: View {
    @EnvironmentObject var messagesManager: MessagesManager
    @EnvironmentObject var contactManager: ContactManager
    @EnvironmentObject var conversationsManager: ConversationsManager
    var conversationId: String
    @State var selectedUsers: [User] = []
    @State var adding: Bool = false
    
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        VStack {
            let currentConversation = conversationsManager.conversations.first(where: {$0._id == conversationId})
            let participants = currentConversation?.participants
            ForEach(contactManager.users, id: \.self._id) { user in
                let isSelected = selectedUsers.contains(user)
                if let participants = participants, !participants.contains(user._id) {
                    Button(action: {
                        if let index = selectedUsers.firstIndex(where: {$0 == user}) {
                            selectedUsers.remove(at: index)
                        } else {
                            selectedUsers.append(user)
                        }
                    }) {
                        HStack {
                            PersonRow(user: user)
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(Color.accentColor)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            Spacer()
            Button(action: {
                adding = true
                let userIds = selectedUsers.map { $0._id }
                conversationsManager.addUserToConversation(userIds: userIds, conversationId: conversationId) {
                    self.adding = false
                    presentationMode.wrappedValue.dismiss()
                }
            }) {
                Text(adding ? LocalizedStringKey("Adding user(s) to conversation") : LocalizedStringKey("Add Selected (\(selectedUsers.count))"))
            }.disabled(selectedUsers.count == 0 || adding)
        }
    }
}
