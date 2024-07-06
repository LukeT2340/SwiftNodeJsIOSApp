//
//  ProfileNotes.swift
//  Frontend
//
//  Created by Luke Thompson on 5/7/2024.
//

import SwiftUI

struct ProfileNotes: View {
    @EnvironmentObject var profileInfoManager: ProfileInfoManager
    @EnvironmentObject var notesManager: NotesManager
    var user: User

    var body: some View {
        VStack {
            ForEach(profileInfoManager.notes, id: \.self.note._id) { notePackage in
                NotePreview(notePackage: notePackage, isViewingFromProfileView: true)
            }
            Color.clear
                .frame(height: 70)
        }
        .onAppear {
            if !profileInfoManager.notesInitialized {
                loadFirstBatchOfNotes()
            }
        }
    }
    
    private func loadFirstBatchOfNotes() {
        notesManager.fetchNotes(page: 1, batchSize: 5,userId: user._id) { notePackages, _ in
            if let notePackages = notePackages {
                profileInfoManager.addNewNotes(notePackages: notePackages) {
                    profileInfoManager.notesInitialized = true
                }
            }
        }
    }
}
