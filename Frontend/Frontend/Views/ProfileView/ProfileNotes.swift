//
//  ProfileNotes.swift
//  Frontend
//
//  Created by Luke Thompson on 5/7/2024.
//

import SwiftUI

struct ProfileNotes: View {
    @EnvironmentObject var profileInfoManager: ProfileInfoManager
    
    var user: User

    var body: some View {
        VStack {
            ForEach(profileInfoManager.notes, id: \.self.note._id) { notePackage in
                NotePreview(notePackage: notePackage)
            }
        }
        .onAppear {
            if !profileInfoManager.notesInitialized {
                profileInfoManager.fetchInitialBatchOfNotes(userId: user._id) {
                    
                }
            }
        }
    }
}
