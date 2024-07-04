//
//  CreateNewNote.swift
//  Frontend
//
//  Created by Luke Thompson on 3/7/2024.
//

import SwiftUI
import TLPhotoPicker

struct CreateNewNote: View {
    @EnvironmentObject var notesManager: NotesManager
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject private var keyboardResponder = KeyboardResponder()
    @State private var selectedAssets: [TLPHAsset] = []
    @State private var textContent = ""
    @State private var newNote: Note?
    @State private var navigateToNote = false
    @State private var isShowingMediaPicker = false
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        VStack {
            navigationBar
            ScrollView {
                textEdit
            }
            Spacer()
            mediaPreview
            addToPost
            
        }
        .padding()
        .navigationBarBackButtonHidden()
        .navigationDestination(isPresented: $navigateToNote) {
             if let newNote = newNote {
                 let clientUser = authManager.user
                 if let user = clientUser {
                     let notePackage = NotePackage(note: newNote, author: user, commentsAndAuthors: [])
                     NoteDetailedView(notePackage: notePackage)
                 }
             }
         }
        .fullScreenCover(isPresented: $isShowingMediaPicker) {
            CustomTLPhotoPicker(isPresented: $isShowingMediaPicker, selectedAssets: $selectedAssets)
        }
    }
    
    private var navigationBar: some View {
        ZStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(LocalizedStringKey("Note"))
            Button(action: {
                notesManager.createNote(textContent: textContent, media: selectedAssets) { note in
                    if let note = note {
                        newNote = note
                        navigateToNote = true
                    }
                }
            }) {
                Text(LocalizedStringKey("Post"))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.system(size: 20))
    }
    
    private var textEdit: some View {
        TextField(LocalizedStringKey("Enter your post content"), text: $textContent, axis: .vertical)
            .onTapGesture {
                keyboardResponder.hideKeyboard()
            }
    }
    
    private var mediaPreview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(selectedAssets.indices, id: \.self) { index in
                    let asset = selectedAssets[index]
                    if let uiImage = asset.fullResolutionImage {
                        if asset.type == .video {
                            ZStack {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 160, height: 160)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                Image(systemName: "video.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: 150, maxHeight: 150, alignment: .bottomLeading)
                            }
                        } else if asset.type == .photo {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 160, height: 160)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                    }
                }
                Spacer()
            }
        }
    }
    
    private var addToPost: some View {
        HStack {
            Button(action: {
                
            }) {
                Image(systemName: "mic")
            }
            .padding(.horizontal, 10)
            Button(action: {
                isShowingMediaPicker.toggle()
            }) {
                Image(systemName: "photo")
            }
            .padding(.horizontal, 10)
            Button(action: {
                
            }) {
                Image(systemName: "location")
            }
            .padding(.horizontal, 10)
            Spacer()
            Button(action: {
                
            }) {
                Image(systemName: "tag")
            }
            .padding(.horizontal, 10)
        }
        .font(.system(size: 20))
    }
}

#Preview {
    CreateNewNote()
}
