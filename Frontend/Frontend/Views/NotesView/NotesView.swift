//
//  NotesView.swift
//  Frontend
//
//  Created by Luke Thompson on 3/7/2024.
//

import SwiftUI

struct NotesView: View {
    @EnvironmentObject var notesManager: NotesManager
    @State private var showSearchSheet = false
    @State private var showFilterSheet = false
    @State private var height = CGFloat(0)
    var body: some View {
        VStack {
            navigationBar
            GeometryReader { outerGeometry in
                ScrollView {
                    ScrollViewReader { proxy in
                        ForEach(notesManager.recommendedNotes, id: \.self.note._id) { notePackage in
                            NotePreview(notePackage: notePackage)
                        }
                        Spacer().id("scroll")
                    }
                    .background(GeometryReader { geometry in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).origin)
                            .onChange(of: geometry.size) { value in
                                height = value.height
                            }
                    })
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        if value.y + height < 900 {
                            notesManager.fetchMoreRecommendedNotes {
                                
                            }
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showSearchSheet) {
            EmptyView()
        }
        .fullScreenCover(isPresented: $showFilterSheet) {
            EmptyView()
        }
        .onAppear {
            if notesManager.recommendedNotes.count == 0 {
                notesManager.initialize()
            }
        }
        .background(Color.gray.opacity(0.1))
    }
    
    private var navigationBar: some View {
        HStack {
            NavigationLink(destination: EmptyView()) {
                Image(systemName: "bell")
                    .foregroundColor(Color.accentColor)
                    .font(.system(size: 20))
            }
            Button(action: {
                showSearchSheet.toggle()
            }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.gray)
                    Text(LocalizedStringKey("Search"))
                        .foregroundColor(Color.gray)
                    Spacer()
                }
            }
            .padding(.vertical,6)
            .padding(.horizontal, 10)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(15)
            .padding(.vertical)
            .font(.system(size: 18))
            
            
            Button(action: {
                showFilterSheet.toggle()
            }) {
                Image(systemName: "slider.horizontal.3")
            }
            .foregroundColor(Color.accentColor)
            .font(.system(size: 20))
            
            NavigationLink(destination: CreateNewNote()) {
                Image(systemName: "square.and.pencil")
                    .foregroundColor(Color.accentColor)
                    .font(.system(size: 20))
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    NotesView()
}
