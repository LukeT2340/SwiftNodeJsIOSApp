//
//  NotesManager.swift
//  Frontend
//
//  Created by Luke Thompson on 3/7/2024.
//

import Foundation
import TLPhotoPicker
import Alamofire
import UIKit
import TLPhotoPicker
import Photos

class NotesManager: ObservableObject {
    @Published var recommendedNotes: [NotePackage] = []
    @Published var page = 1
    @Published var isFetching = false
    @Published var hasInitialized = false
    
    func initialize() {
        fetchFirstBatchOfNotes() {
            self.hasInitialized = true
        }
    }
    
    private func fetchFirstBatchOfNotes(completion: @escaping () -> Void) {
        fetchRecommendedNotes(batchSize: 10) { newNotesAndUsers in
            if let notesAndUsers = newNotesAndUsers {
                self.recommendedNotes.append(contentsOf: notesAndUsers)
            }
        }
    }
    
    func fetchMoreRecommendedNotes(completion: @escaping () -> Void) {
        fetchRecommendedNotes(batchSize: 10) { newNotesAndUsers in
            if let notesAndUsers = newNotesAndUsers {
                let existingNoteIDs = Set(self.recommendedNotes.map { $0.note._id })
                let filteredNotesAndUsers = notesAndUsers.filter { !existingNoteIDs.contains($0.note._id) }
                self.recommendedNotes.append(contentsOf: filteredNotesAndUsers)
            }
            completion()
        }
    }
    
    private func fetchRecommendedNotes(batchSize: Int, completion: @escaping ([NotePackage]?) -> Void) {
        guard !self.isFetching else {
            completion(nil)
            return
        }
        self.isFetching = true
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            print("Backend URL not set")
            self.isFetching = false
            completion(nil)
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not set")
            self.isFetching = false
            completion(nil)
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        let url = "\(backendURL)/note/fetch/?page=\(page)?&limit=\(batchSize)"
        AF.request(url, method: .get, headers: headers)
            .validate()
            .responseDecodable(of: [NotePackage].self) { response in
                DispatchQueue.main.async {
                    switch response.result {
                    case .success(let newNotesAndUsers):
                        self.page += 1
                        self.isFetching = false
                        completion(newNotesAndUsers)
                    case .failure(let error):
                        print("Failed to fetch new notes: \(error.localizedDescription)")
                        self.isFetching = false
                        completion(nil)
                    }
                }
            }
    }
    
    func createNote(textContent: String, media: [TLPHAsset], completion: @escaping (Note?) -> Void) {
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            print("Backend URL not set")
            return
        }
        
        guard let clientUserId = UserDefaults.standard.string(forKey: "_id") else {
            print("User Id not set")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not set")
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        
        let url = "\(backendURL)/note/create"
        self.uploadMediaMultiple(media: media) { mediaObjects in
            var parameters: [String: Any] = [
                "textContent": textContent
            ]
            if let mediaObjects = mediaObjects {
                let mediaRequests = mediaObjects.map { media in
                    return [
                        "url": media.url,
                        "duration": media.duration as Any,
                        "mediaType": media.mediaType
                    ]
                }
                parameters["mediaContent"] = mediaRequests
            }
            
            AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers )
                .validate()
                .responseDecodable(of: Note.self) { response in
                    switch response.result {
                    case .success(let note):
                        DispatchQueue.main.async {
                            completion(note)
                        }
                    case .failure(let error):
                        print("Failed to post new note: \(error.localizedDescription)")
                        completion(nil)
                    }
                }
        }
    }
    
    private func uploadMediaMultiple(media: [TLPHAsset], completion: @escaping ([CreateNoteMediaRequest]?) -> Void) {
        var mediaArray: [CreateNoteMediaRequest] = []
        let dispatchGroup = DispatchGroup()
        for asset in media {
            dispatchGroup.enter()
            uploadMediaSingle(asset: asset) { mediaObject in
                if let mediaObject = mediaObject {
                    mediaArray.append(mediaObject)
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(mediaArray)
        }
    }
    
    private func uploadMediaSingle(asset: TLPHAsset, completion: @escaping (CreateNoteMediaRequest?) -> Void) {
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            completion(nil)
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not set")
            return
        }
        
        guard let phAsset = asset.phAsset else {
            completion(nil)
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        // Use PHImageManager to fetch data of the asset
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        
        let mediaType = phAsset.mediaType
        let url = "\(backendURL)/media/upload"
        if mediaType == .image {
            // For images, fetch image data
            imageManager.requestImageData(for: phAsset, options: requestOptions) { (data, _, _, _) in
                guard let imageData = data else {
                    completion(nil)
                    return
                }
                
                // Use Alamofire to upload media
                AF.upload(multipartFormData: { multipartFormData in
                    multipartFormData.append(imageData, withName: "file", fileName: asset.originalFileName, mimeType: "image/jpeg")
                    // Add other fields if needed (e.g., parameters)
                }, to: url, headers: headers)
                .responseDecodable(of: String.self) { response in
                    switch response.result {
                    case .success (let mediaURL):
                        let media = CreateNoteMediaRequest(url: mediaURL, mediaType: "image")
                        
                        completion(media)
                    case .failure(let error):
                        print("Failed to get image data: \(error.localizedDescription)")
                    }
                }
            }
        } else if mediaType == .video {
            // For videos, fetch AVAsset asynchronously
            imageManager.requestAVAsset(forVideo: phAsset, options: nil) { (avAsset, _, _) in
                guard let avAsset = avAsset else {
                    completion(nil)
                    return
                }
                
                // Export AVAsset to a temporary file URL
                let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetMediumQuality)
                exportSession?.outputFileType = AVFileType.mp4
                exportSession?.shouldOptimizeForNetworkUse = true
                
                let tempFileUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tempVideo.mp4")
                
                exportSession?.outputURL = tempFileUrl
                
                exportSession?.exportAsynchronously(completionHandler: {
                    switch exportSession?.status {
                    case .completed:
                        do {
                            let videoData = try Data(contentsOf: tempFileUrl)
                            
                            // Use Alamofire to upload video
                            AF.upload(multipartFormData: { multipartFormData in
                                multipartFormData.append(videoData, withName: "file", fileName: asset.originalFileName, mimeType: "video/mp4")
                                // Add other fields if needed (e.g., parameters)
                            }, to: url, headers: headers)
                            .responseDecodable(of: String.self) { response in
                                switch response.result {
                                case .success (let mediaURL):
                                    if let duration = asset.phAsset?.duration {
                                        let media = CreateNoteMediaRequest(url: mediaURL, duration: Int(duration), mediaType: "video")
                                        completion(media)
                                    }
                                case .failure(let error):
                                    print("Failed to mark messages as read: \(error.localizedDescription)")
                                }
                            }
                        } catch {
                            print("Error converting AVAsset to Data: \(error)")
                            completion(nil)
                        }
                        
                    case .failed, .cancelled, .unknown, .waiting:
                        completion(nil)
                    @unknown default:
                        completion(nil)
                    }
                })
            }
        } else {
            completion(nil)
        }
    }
    
    func likeNote(noteId: String, completion: @escaping () -> Void) {
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            completion()
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not set")
            return
        }
        
        guard noteId != "" else {
            print("No note Id")
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        let url = "\(backendURL)/note/like"
        let parameters = ["noteId": noteId]
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers )
            .validate()
            .responseDecodable(of: Note.self) { response in
                switch response.result {
                case .success(let note):
                    DispatchQueue.main.async {
                        if let index = self.recommendedNotes.firstIndex(where: {$0.note._id == noteId}) {
                            let user = self.recommendedNotes[index].author
                            let commentsAndAuthors = self.recommendedNotes[index].commentsAndAuthors
                            self.recommendedNotes[index] = NotePackage(note: note, author: user, commentsAndAuthors: commentsAndAuthors)
                        }
                        completion()
                    }
                case .failure(let error):
                    print("Failed to like note: \(error.localizedDescription)")
                    completion()
                }
            }
    }
    
    func unlikeNote(noteId: String, completion: @escaping () -> Void) {
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            completion()
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not set")
            return
        }
        
        guard noteId != "" else {
            print("No note Id")
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        let url = "\(backendURL)/note/unlike"
        let parameters = ["noteId": noteId]
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers )
            .validate()
            .responseDecodable(of: Note.self) { response in
                switch response.result {
                case .success(let note):
                    DispatchQueue.main.async {
                        if let index = self.recommendedNotes.firstIndex(where: {$0.note._id == noteId}) {
                            let user = self.recommendedNotes[index].author
                            let commentsAndAuthors = self.recommendedNotes[index].commentsAndAuthors
                            self.recommendedNotes[index] = NotePackage(note: note, author: user, commentsAndAuthors: commentsAndAuthors)
                        }
                        completion()
                    }
                case .failure(let error):
                    print("Failed to unlike note: \(error.localizedDescription)")
                    completion()
                }
            }
    }
    
    
    func comment(noteId: String, textContent: String, completion: @escaping () -> Void) {
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            completion()
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not set")
            return
        }
        
        guard noteId != "" else {
            print("No note Id")
            return
        }
        
        guard textContent != "" else {
            print("No text content")
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        let url = "\(backendURL)/comment/add"
        let parameters = ["noteId": noteId, "textContent": textContent]
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers )
            .validate()
            .responseDecodable(of: CommentAndAuthor.self) { response in
                switch response.result {
                case .success(let commentAndAuthor):
                    DispatchQueue.main.async {
                        if let index = self.recommendedNotes.firstIndex(where: { $0.note._id == noteId }) {
                            self.recommendedNotes[index].note.commentCount += 1
                            self.recommendedNotes[index].commentsAndAuthors.append(commentAndAuthor)
                        }
                        completion()
                    }
                case .failure(let error):
                    print("Failed to comment on note: \(error.localizedDescription)")
                    completion()
                }
            }
    }
    
    func likeCommet(commentId: String, completion: @escaping () -> Void) {
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            completion()
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not set")
            return
        }
        
        guard commentId != "" else {
            print("No comment Id")
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        let url = "\(backendURL)/comment/like"
        let parameters = ["commentId": commentId]
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers )
            .validate()
            .responseDecodable(of: Comment.self) { response in
                switch response.result {
                case .success(let comment):
                    DispatchQueue.main.async {
                        if let index = self.recommendedNotes.firstIndex(where: {$0.note._id == comment.noteId}) {
                            var commentsAndAuthors = self.recommendedNotes[index].commentsAndAuthors
                            if let index2 = commentsAndAuthors.firstIndex(where: {$0.comment._id == comment._id}) {
                                commentsAndAuthors[index2].comment = comment
                                self.recommendedNotes[index].commentsAndAuthors = commentsAndAuthors
                            }
                            
                        }
                        completion()
                    }
                case .failure(let error):
                    print("Failed to like comment: \(error.localizedDescription)")
                    completion()
                }
            }
    }
    
    func unlikeCommet(commentId: String, completion: @escaping () -> Void) {
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            completion()
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not set")
            return
        }
        
        guard commentId != "" else {
            print("No comment Id")
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        let url = "\(backendURL)/comment/unlike"
        let parameters = ["commentId": commentId]
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers )
            .validate()
            .responseDecodable(of: Comment.self) { response in
                switch response.result {
                case .success(let comment):
                    DispatchQueue.main.async {
                        if let index = self.recommendedNotes.firstIndex(where: {$0.note._id == comment.noteId}) {
                            var commentsAndAuthors = self.recommendedNotes[index].commentsAndAuthors
                            if let index2 = commentsAndAuthors.firstIndex(where: {$0.comment._id == comment._id}) {
                                commentsAndAuthors[index2].comment = comment
                                self.recommendedNotes[index].commentsAndAuthors = commentsAndAuthors
                            }
                            
                        }
                        completion()
                    }
                case .failure(let error):
                    print("Failed to like comment: \(error.localizedDescription)")
                    completion()
                }
            }
    }
    
    func reloadNote(noteId: String, completion: @escaping () -> Void) {
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            completion()
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not set")
            return
        }
        
        guard noteId != "" else {
            print("No note Id")
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        let url = "\(backendURL)/note/fetchOne/\(noteId)"
        
        AF.request(url, method: .get, encoding: JSONEncoding.default, headers: headers )
            .validate()
            .responseDecodable(of: NotePackage.self) { response in
                switch response.result {
                case .success(let notePackage):
                    DispatchQueue.main.async {
                        if let index = self.recommendedNotes.firstIndex(where: {$0.note._id == noteId}) {
                            self.recommendedNotes[index] = notePackage
                        }
                        completion()
                    }
                case .failure(let error):
                    print("Failed to refresh note: \(error.localizedDescription)")
                    completion()
                }
            }
    }
    
    func fetchMoreComments(page: Int, batchSize: Int, noteId: String, completion: @escaping (Bool) -> Void) {
        self.fetchComments(page: page, batchSize: batchSize, noteId: noteId) {commentsAndAuthors, reachedEnd in
            if let index = self.recommendedNotes.firstIndex(where: {$0.note._id == noteId}), let commentsAndAuthors = commentsAndAuthors {
                DispatchQueue.main.async {
                    self.recommendedNotes[index].commentsAndAuthors.append(contentsOf: commentsAndAuthors)
                    self.isFetching = false
                    completion(reachedEnd)
                }
            }
        }
    }
    
    private func fetchComments(page: Int, batchSize: Int, noteId: String,completion: @escaping ([CommentAndAuthor]?, Bool) -> Void) {
        guard !self.isFetching else {
            completion(nil, false)
            return
        }
        
        self.isFetching = true
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            print("Backend URL not set")
            self.isFetching = false
            completion(nil, false)
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not set")
            self.isFetching = false
            completion(nil, false)
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        let url = "\(backendURL)/comment/fetch/?page=\(page)?&limit=\(batchSize)"
        AF.request(url, method: .get, headers: headers)
            .validate()
            .responseDecodable(of: [CommentAndAuthor].self) { response in
                DispatchQueue.main.async {
                    switch response.result {
                        case .success(let commentsAndAuthors):
                            if commentsAndAuthors.count % batchSize != 0 || commentsAndAuthors.count == 0 {
                                completion(commentsAndAuthors, true)
                            } else {
                                completion(commentsAndAuthors, false)
                            }
                        case .failure(let error):
                            print("Failed to fetch new comments: \(error.localizedDescription)")
                            self.isFetching = false
                            completion(nil, false)
                    }
                }
            }
    }
}
