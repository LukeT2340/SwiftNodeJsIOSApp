//
//  ProfileInfoManager.swift
//  Frontend
//
//  Created by Luke Thompson on 5/7/2024.
//

import Foundation
import Alamofire

class ProfileInfoManager: ObservableObject {
    @Published var notes: [NotePackage] = []
    @Published var notesInitialized = false
    @Published var mediaInitialized = false
    
    func addNewNotes(notePackages: [NotePackage], completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            let existingNoteIds = self.notes.map{$0.note._id}
            let filteredNotePackages = notePackages.filter({!existingNoteIds.contains($0.note._id)})
            self.notes.append(contentsOf: filteredNotePackages)
            completion()
        }
    }
    
    func updateNote(_ note: Note) {
        DispatchQueue.main.async {
            if let index = self.notes.firstIndex(where: {$0.note._id == note._id}) {
                let user = self.notes[index].author
                let commentsAndAuthors = self.notes[index].commentsAndAuthors
                self.notes[index] = NotePackage(note: note, author: user, commentsAndAuthors: commentsAndAuthors)
            }
        }
    }
    
    func addCommentToArray(_ commentAndAuthor: CommentAndAuthor) {
        DispatchQueue.main.async {
            if let index = self.notes.firstIndex(where: { $0.note._id == commentAndAuthor.comment.noteId }) {
                self.notes[index].note.commentCount += 1
                self.notes[index].commentsAndAuthors.append(commentAndAuthor)
            }
        }
    }
    
    func addCommentsToArray(_ commentsAndAuthors: [CommentAndAuthor]) {
        DispatchQueue.main.async {
            let existingCommentIds = self.notes.flatMap { $0.commentsAndAuthors.map { $0.comment._id } }
            let filteredCommentsAndAuthors = commentsAndAuthors.filter{!existingCommentIds.contains($0.comment._id)}

            for commentAndAuthor in filteredCommentsAndAuthors {
                if let noteIndex = self.notes.firstIndex(where: { $0.note._id == commentAndAuthor.comment.noteId }) {
                    self.notes[noteIndex].commentsAndAuthors.append(commentAndAuthor)
                 }
             }
        }
    }
    
    func updateComment(_ comment: Comment) {
        DispatchQueue.main.async {
            if let index = self.notes.firstIndex(where: {$0.note._id == comment.noteId}) {
                var commentsAndAuthors = self.notes[index].commentsAndAuthors
                if let index2 = commentsAndAuthors.firstIndex(where: {$0.comment._id == comment._id}) {
                    commentsAndAuthors[index2].comment = comment
                    self.notes[index].commentsAndAuthors = commentsAndAuthors
                }
                
            }
        }
    }
    
    func emptyVariables() {
        self.notes = []
        self.mediaInitialized = false
        self.notesInitialized = false
    }
    
    
}
