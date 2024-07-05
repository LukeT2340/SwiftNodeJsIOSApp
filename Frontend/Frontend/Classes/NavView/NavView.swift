import SwiftUI

struct NavView: View {
    @StateObject var peopleManager = PeopleManager()
    @EnvironmentObject var contactManager: ContactManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var messagesManager: MessagesManager
    @EnvironmentObject var conversationsManager: ConversationsManager
    @State private var selectedTab = 0
 
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                ConversationListView()
                    .tabItem {
                        Image(systemName: "message")
                        Text(LocalizedStringKey("Messages"))
                    }
                    .tag(0)
                    .badge(messagesManager.totalUnreadMessages)
                
                PeopleView(peopleManager: peopleManager)
                    .tabItem {
                        Image(systemName: "person.3")
                        Text(LocalizedStringKey("People"))
                    }
                    .tag(1)
                
                NotesView()
                    .tabItem {
                        Image(systemName: "book")
                        Text(LocalizedStringKey("Notes"))
                    }
                    .tag(2)
                
                Text("Profile")
                    .tabItem {
                        Image(systemName: "person.crop.circle")
                        Text(LocalizedStringKey("Profile"))
                    }
                    .tag(3)
            }
        }
        
        .onAppear {
            if !contactManager.hasInitialized {
                contactManager.initialize()
            }
            if !conversationsManager.hasInitialized {
                conversationsManager.initialize()
            }
            if !messagesManager.hasInitialized {
                messagesManager.initialize()
            }
            if !authManager.isInitialized {
                authManager.initialize()
            }
        }
        .onChange(of: contactManager.users) { _ in
            conversationsManager.refreshConversations {
                
            }
        }
        .onChange(of: conversationsManager.conversations) { _ in
            contactManager.fetchUsers {
                
            }
        }
        .onChange(of: messagesManager.messages) { messages in
            let lastMessage = messages.last
            let conversationId = lastMessage?.conversationId
            if !conversationsManager.conversations.map({$0._id}).contains(conversationId) {
                conversationsManager.refreshConversations() {

                }
            }
        }
    }
}

#Preview {
    NavView()
}
