//
//  VoiceRecorder.swift
//  Frontend
//
//  Created by Luke Thompson on 3/7/2024.
//

import Foundation
import AVFoundation
import Speech
import SwiftUI

class VoiceRecorder: NSObject, ObservableObject, AVAudioPlayerDelegate {
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    private var recordingsDirectory: URL?

    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var lastRecordingURL: URL?
    @Published var lastRecordingDuration: TimeInterval?

    // Sets the path for the new recording and starts recording
    func startRecording() {
        let recordingName = "\(UUID().uuidString).m4a"
          let filePath = getDocumentsDirectory().appendingPathComponent(recordingName)

          let settings = [
              AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
              AVSampleRateKey: 44100,
              AVNumberOfChannelsKey: 1,
              AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
          ] as [String: Any]

          do {
              let audioSession = AVAudioSession.sharedInstance()
              try audioSession.setCategory(.playAndRecord, mode: .default)
              try audioSession.setActive(true)

              audioRecorder = try AVAudioRecorder(url: filePath, settings: settings)
              audioRecorder?.prepareToRecord()
              audioRecorder?.record()
              isRecording = true
          } catch {
              print("Simplified recording failed: \(error)")
          }
      }

    // Returns the documents directory
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    // Stops recording
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        lastRecordingURL = audioRecorder?.url
        
        if let url = lastRecordingURL {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = attributes[.size] as? UInt64
                let duration = getAudioDuration(url: url)
                
                // Make sure recording isn't too short or too long
                if duration < 1 || duration > 60 {
                    lastRecordingURL = nil
                } else {
                    lastRecordingDuration = duration
                }
            } catch {
                print("Error getting file size: \(error)")
            }
        }
    }
        
    // Used to play the recording that was just recorded back to the user
    func playRecording() {
        guard let url = lastRecordingURL else {
            print("No recording URL found")
            return
        }

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? UInt64
            print("File size: \(fileSize ?? 0) bytes")
        } catch {
            print("Error getting file size: \(error)")
        }

        let duration = getAudioDuration(url: url)
        print("Audio Duration: \(duration) seconds")

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback)
            try session.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Playback failed: \(error)")
        }
    }
    
    // Stops playing the recording
    func stopPlaying() {
        audioPlayer?.stop()
        isPlaying = false
    }

    // Takes the local URL of the audio file and returns its duration
    func getAudioDuration(url: URL) -> TimeInterval {
        let asset = AVAsset(url: url)
        return CMTimeGetSeconds(asset.duration)
    }
}
