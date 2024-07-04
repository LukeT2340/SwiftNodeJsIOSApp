//
//  PeopleView.swift
//  Frontend
//
//  Created by Luke Thompson on 23/6/2024.
//

import SwiftUI

struct PeopleView: View {
    @ObservedObject var peopleManager: PeopleManager

    var body: some View {
        VStack {
            List {
                ForEach(peopleManager.users, id: \.self._id) { user in
                    NavigationLink(destination: ProfileView(user: user)) {
                        PersonRow(user: user)
                    }
                }
            }.listStyle(.inset)
        }
        .onAppear {
            if peopleManager.users.isEmpty {
                peopleManager.fetchUsers()
            }
        }
    }
}

