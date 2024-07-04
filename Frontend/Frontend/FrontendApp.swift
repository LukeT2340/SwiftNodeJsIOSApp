//
//  FrontendApp.swift
//  Frontend
//
//  Created by Luke Thompson on 22/6/2024.
//

import SwiftUI

@main
struct FrontendApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var messagesManager = MessagesManager()
    @StateObject var conversationsManager = ConversationsManager()
    @StateObject var authManager = AuthManager()
    @StateObject var contactManager = ContactManager()
    @StateObject var notesManager = NotesManager()

    init () {
        UserDefaults.standard.set("http://192.168.1.145:3001", forKey: "backend_url")
    }
    
    var body: some Scene {
        WindowGroup {
            mainView
                .environmentObject(authManager)
                .environmentObject(messagesManager)
                .environmentObject(contactManager)
                .environmentObject(conversationsManager)
                .environmentObject(notesManager)
        }
    }

    private var mainView: some View {
        NavigationStack {
            switch (authManager.isSignedIn, authManager.accountIsSetup) {
                case (false, _):
                    LoginView()
                case (true, false):
                    EmptyView()
                case (true, true):
                    NavView()
            }
        }
    }
}

