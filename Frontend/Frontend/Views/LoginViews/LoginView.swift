//
//  LoginView.swift
//  Frontend
//
//  Created by Luke Thompson on 22/6/2024.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack {
            TextField(LocalizedStringKey("Email"), text: $email)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            SecureField(LocalizedStringKey("Password"), text: $password)
                .textFieldStyle(.roundedBorder)
            Button(action: {authManager.login(email: email, password: password)}) {
                Text(LocalizedStringKey("Login"))
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    LoginView()
}
