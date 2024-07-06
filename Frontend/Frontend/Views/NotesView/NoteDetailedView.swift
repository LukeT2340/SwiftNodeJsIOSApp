//
//  NoteDetailedView.swift
//  Frontend
//
//  Created by Luke Thompson on 3/7/2024.
//

import SwiftUI
import Kingfisher

struct NoteDetailedView: View {
    @ObservedObject var keyboardResponder = KeyboardResponder()
    @EnvironmentObject var notesManager: NotesManager
    @EnvironmentObject var profileInfoManager: ProfileInfoManager
    var notePackage: NotePackage
    var isViewingFromProfileView: Bool
    
    @State private var noteLoaded = false
    @State private var height = CGFloat(0)
    @State private var page = 1
    var body: some View {
        ZStack {
            ScrollView {
                ScrollViewReader { proxy in
                    VStack (alignment: .leading, spacing: 15) {
                        UserPreview(user: notePackage.author)
                        Text(notePackage.note.textContent ?? "")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        mediaPreview
                        feedBack
                        comments
                        Color.clear
                            .frame(height: 50)
                            .id("ScrollViewEnd")
                        Spacer()
                    }
                    .padding(.horizontal)
                    .onChange(of: keyboardResponder.isKeyboardVisible) { boolean in
                        if boolean {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation {
                                    proxy.scrollTo("ScrollViewEnd")
                                }
                            }
                        }
                    }
                }
                .background(GeometryReader { geometry in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).origin)
                        .onChange(of: geometry.size) { value in
                            if page != -1 {
                                height = value.height
                            }
                        }
                })
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    if page != -1 && value.y + height < 900 && noteLoaded {
                        notesManager.fetchMoreComments(page: page, batchSize: 8, noteId: notePackage.note._id) { commentsAndAuthors, reachedEnd in
                            if reachedEnd {
                                page = -1
                            } else {
                                page += 1
                            }
                            if isViewingFromProfileView {
                                profileInfoManager.addCommentsToArray(commentsAndAuthors)
                            } else {
                                notesManager.addCommentsToArray(commentsAndAuthors)
                            }
                        }
                    }
                }
            }
            .background(Color.white)
            .foregroundColor(.primary)
            .cornerRadius(10)
            .onAppear {
                notesManager.reloadNote(noteId: notePackage.note._id) {
                    noteLoaded = true
                }
            }
            .onTapGesture {
                keyboardResponder.hideKeyboard()
            }
            NewCommentView(notePackage: notePackage, isViewingFromProfileView: isViewingFromProfileView)
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
                        notesManager.unlikeNote(noteId: notePackage.note._id) { note in
                            if let note = note {
                                if isViewingFromProfileView {
                                    profileInfoManager.updateNote(note)
                                } else {
                                    notesManager.updateNote(note)
                                }
                            }
                        }
                    } else {
                        notesManager.likeNote(noteId: notePackage.note._id) { note in
                            if let note = note {
                                if isViewingFromProfileView {
                                    profileInfoManager.updateNote(note)
                                } else {
                                    notesManager.updateNote(note)
                                }
                            }
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
                }
            }
            HStack (spacing: 3) {
                Image(systemName: "bubble.left")
                Text("\(notePackage.note.commentCount)")
            }
        }
    }
    
    @ViewBuilder
    private var comments: some View {
        if notePackage.commentsAndAuthors.count > 0 {
            VStack {
                ForEach(notePackage.commentsAndAuthors, id: \.self.comment._id) { commentAndAuthor in
                    CommentView(commentAndAuthor: commentAndAuthor, isViewingFromProfileView: isViewingFromProfileView)
                }
            }
        }
    }
}

struct NoteDetailedView_Previews: PreviewProvider {
    static var previews: some View {
        let note = Note(_id: "faefa", author: "eafgraga", textContent: "Beautiful", mediaContent: [Media(_id: "test", url: "https://firebasestorage.googleapis.com/v0/b/mylanguageapp-b7504.appspot.com/o/images%2F2D738578-AEC5-4C55-9830-A06C03924732.jpg?alt=media&token=97c1d977-05cb-4fff-b9d1-8178590bdfbd", duration: nil, mediaType: "image")], commentCount: 0, likeCount: 0, editedAt: "feaf", createdAt: "feaf", hasLiked: false)
        let user = User(_id: "", username: "Luke")
        let noteAndUser = NotePackage(note: note, author: user, commentsAndAuthors: [])
        
        return NoteDetailedView(notePackage: noteAndUser, isViewingFromProfileView: false)
    }
}
