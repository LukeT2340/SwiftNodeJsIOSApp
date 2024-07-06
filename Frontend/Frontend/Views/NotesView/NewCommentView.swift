//
//  NewCommentView.swift
//  Frontend
//
//  Created by Luke Thompson on 4/7/2024.
//

import SwiftUI

struct NewCommentView: View {
    @ObservedObject var keyboardResponder = KeyboardResponder()
    @State private var newCommentText = ""
    @State private var sendingComment = false
    @EnvironmentObject var notesManager: NotesManager
    @EnvironmentObject var profileInfoManager: ProfileInfoManager
    var notePackage: NotePackage
    var isViewingFromProfileView: Bool
    
    var body: some View {
        HStack {
            TextField(LocalizedStringKey("New comment"), text: $newCommentText, axis: .vertical)
                .lineLimit(4)
            Button(action: {
                sendingComment = true
                keyboardResponder.hideKeyboard()
                notesManager.comment(noteId: notePackage.note._id, textContent: newCommentText) { commentAndAuthor in
                    if let commentAndAuthor = commentAndAuthor {
                        if isViewingFromProfileView {
                            profileInfoManager.addCommentToArray(commentAndAuthor)
                        } else {
                            notesManager.addCommentToArray(commentAndAuthor)
                        }
                    }
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
        .padding()
        .textFieldStyle(.roundedBorder)
        .font(.system(size: 16))
        .background(
            Color.white
        )
        .padding(.horizontal)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}
