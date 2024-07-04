//
//  VoicePlayer.swift
//  Frontend
//
//  Created by Luke Thompson on 3/7/2024.
//

import Foundation
import AVFoundation
import Speech
import SwiftUI

// Used to download audio files from firebase storage and play them
class VoicePlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var playingMessageId: String? // Important to keep track of so we can show the user which voice message is playing
    private var audioPlayer: AVAudioPlayer?
    
    // Plays audio file and sets the the playingMessageId
    func playAudio(from url: URL, messageId: String) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback)
            try session.setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()

            DispatchQueue.main.async {
                self.playingMessageId = messageId
            }

            audioPlayer?.play()
        } catch {
            print("Failed to initialize the audio player: \(error.localizedDescription)")
        }
    }

    func stopAudio() {
        audioPlayer?.stop()
        DispatchQueue.main.async {
            self.playingMessageId = nil
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.playingMessageId = nil
        }
    }
    
    // Downloads the audio file and stores it on the user's device
    func downloadAudioFile(from url: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let downloadTask = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])))
                return
            }

            guard let localURL = localURL else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Local file URL is nil"])))
                return
            }

            // Move the file to a permanent location in the app's sandbox container
            do {
                let fileManager = FileManager.default
                let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let savedURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)
                try? fileManager.removeItem(at: savedURL)
                try fileManager.moveItem(at: localURL, to: savedURL)
                completion(.success(savedURL))
            } catch {
                completion(.failure(error))
            }
        }

        downloadTask.resume()
    }
    

}
