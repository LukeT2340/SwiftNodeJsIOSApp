//
//  ChangeGroupChatNameSheet.swift
//  Frontend
//
//  Created by Luke Thompson on 1/7/2024.
//

import SwiftUI

struct ChangeGroupChatNameSheet: View {
    @State private var newGroupChatName = ""
    var conversationId: String
    @EnvironmentObject var conversationManager: ConversationsManager
    @FocusState var isFocused: Bool
    
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        VStack {
            Text(LocalizedStringKey("Enter your new group chat name"))
            HStack {
                TextField(LocalizedStringKey("New group chat name"), text: $newGroupChatName)
                    .focused($isFocused)
                    .textFieldStyle(.roundedBorder)
                Button(action: {
                    conversationManager.changeGroupChatName(conversationId, name: newGroupChatName) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text(LocalizedStringKey("Change"))
                }
                .padding(8)
                .background(Color.accentColor)
                .cornerRadius(5)
                .foregroundColor(.white)
            }
            Spacer()
        }
        .padding()
        .onAppear {
            isFocused = true
        }
    }
    
    private func isValid() -> Bool {
        return newGroupChatName.count < 15
    }
}
