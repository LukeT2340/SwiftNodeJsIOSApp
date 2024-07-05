//
//  NotePreview.swift
//  Frontend
//
//  Created by Luke Thompson on 3/7/2024.
//

import SwiftUI
import Kingfisher

struct NotePreview: View {
    @EnvironmentObject var notesManager: NotesManager
    @State var showTextField = false
    var notePackage: NotePackage
    
    var body: some View {
        NavigationLink(destination: NoteDetailedView(notePackage: notePackage)) {
            VStack (alignment: .leading, spacing: 15) {
                UserPreview(user: notePackage.author)
                Text(notePackage.note.textContent ?? "")
                    .frame(maxWidth: .infinity, alignment: .leading)
                mediaPreview
                feedBack
                comments
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .foregroundColor(.primary)
        }
    }
    
    @ViewBuilder
    private var mediaPreview: some View {
        if let firstMediaObject = notePackage.note.mediaContent?.first, let url = URL(string: firstMediaObject.url) {
            if firstMediaObject.mediaType == "image" {
                KFImage(url)
                    .resizable()
                    .clipped()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .frame(maxHeight: 250)
            }
        }
    }
    
    private var feedBack: some View {
        HStack {
            Spacer()
            Button(action: {
                if let hasLiked = notePackage.note.hasLiked {
                    if hasLiked {
                        notesManager.unlikeNote(noteId: notePackage.note._id) {
                            
                        }
                    } else {
                        notesManager.likeNote(noteId: notePackage.note._id) {
                            
                        }
                    }
                }
            }) {
                HStack (spacing: 3) {
                    if let hasLiked = notePackage.note.hasLiked {
                        Image(systemName: hasLiked ? "heart.fill" : "heart")
                            .foregroundColor(hasLiked ? Color.red : Color.gray)
                    } else {
                        Image(systemName: "heart")
                            .foregroundColor(Color.gray)
                    }
                    Text("\(notePackage.note.likeCount)")
                        .foregroundColor(Color.gray)
                }
            }
            Button(action: {
                showTextField.toggle()
            }) {
                HStack (spacing: 3) {
                    Image(systemName: "bubble.left")
                        .foregroundColor(Color.gray)
                    Text("\(notePackage.note.commentCount)")
                        .foregroundColor(Color.gray)
                }
            }
        }
    }
    
    @ViewBuilder
    private var comments: some View {
        if notePackage.commentsAndAuthors.count > 0 {
            VStack {
                let commentsAndAuthors = Array(notePackage.commentsAndAuthors.prefix(3))
                ForEach(commentsAndAuthors, id: \.self.comment._id) { commentAndAuthor in
                    CommentView(commentAndAuthor: commentAndAuthor)
                }
                if notePackage.commentsAndAuthors.count > 3 {
                    NavigationLink(destination: NoteDetailedView(notePackage: notePackage)) {
                        Text(LocalizedStringKey("View all \(notePackage.note.commentCount) comments"))
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
        }
    }
}

struct NotePreview_Previews: PreviewProvider {
    static var previews: some View {
        let note = Note(_id: "test", author: "eafgraga", textContent: "Beautiful", mediaContent: [Media(_id: "te", url: "https://firebasestorage.googleapis.com/v0/b/mylanguageapp-b7504.appspot.com/o/images%2F2D7385d78-AEC5-4C55-9830-A06C03924732.jpg?alt=media&token=97c1d977-05cb-4fff-b9d1-8178590bdfbd", duration: nil,  mediaType: "image")], commentCount: 0, likeCount: 0, editedAt: "feaf", createdAt: "feaf", hasLiked: false)
        let user = User(_id: "", username: "Luke", profilePictureUrl: "https://firebasestorage.googleapis.com/v0/b/mylanguageapp-b7504.appspot.com/o/compressedProfileImages%2Fvh6oZg0lBtSveV9kR7GO8zHugam1.jpg?alt=media&token=b6f7844f-e928-4f96-91b2-755ee2f49be4")
        let notePackage = NotePackage(note: note, author: user, commentsAndAuthors: [])
        
        return NotePreview(notePackage: notePackage)
    }
}
