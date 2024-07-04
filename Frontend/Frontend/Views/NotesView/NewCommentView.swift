//
//  NewCommentView.swift
//  Frontend
//
//  Created by Luke Thompson on 4/7/2024.
//

import SwiftUI

struct NewCommentView: View {
    @State private var newCommentText = ""
    @State private var sendingComment = false
    @EnvironmentObject var notesManager: NotesManager
    var notePackage: NotePackage
    
    var body: some View {
        HStack {
            TextField(LocalizedStringKey("New comment"), text: $newCommentText, axis: .vertical)
                .lineLimit(4)
            Button(action: {
                sendingComment = true
                notesManager.comment(noteId: notePackage.note._id, textContent: newCommentText) {
                    newCommentText = ""
                    sendingComment = false
                }
            }) {
                if sendingComment {
                    LoadingView()
                } else {
                    Image(systemName: "arrow.forward.circle.fill")
                        .disabled(newCommentText.isEmpty)
                        .opacity(newCommentText.isEmpty ? 0.8 : 1.0)
                }
            }
        }
        .font(.system(size: 16))
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.accentColor, lineWidth: 1)
        )
        .padding(.horizontal)
    }
}
