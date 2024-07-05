//
//  MessageView.swift
//  Frontend
//
//  Created by Luke Thompson on 27/6/2024.
//

import Foundation
import SwiftUI
import Kingfisher

struct MessageView: View {
    @ObservedObject var voicePlayer: VoicePlayer
    @State var message: Message
    @State var user: User?
    @State var showTimestamp: Bool
    @State var downloadingAudio = false
    @State var downloadedLocalAudioURL: URL?
    @EnvironmentObject var authManager: AuthManager

    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        VStack {
            if let clientUserId = UserDefaults.standard.string(forKey: "_id") {
                if let timestamp = message.createdAt, showTimestamp {
                    Text(formatDate(timestamp))
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                if let isSystemMessage = message.isSystemMessage, let messageText = message.text, isSystemMessage {
                    Text(LocalizedStringKey(messageText))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom)
                } else {
                    HStack (alignment: .top) {
                        if user?._id != clientUserId {
                            if let urlString = user?.profilePictureUrl, let url = URL(string: urlString) {
                                KFImage(url)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 41, height: 41)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                            }
                        } else {
                            Spacer()
                            if message.status == .sending || downloadingAudio {
                                LoadingView()
                                    .frame(height: 35)
                            }
                            if message.status == .failed {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 20))
                                    .frame(height: 35)
                            }
                        }
                        if let messageText = message.text {
                            Text(messageText)
                                .padding(10)
                                .background(clientUserId == user?._id ? Color.accentColor : Color.gray.opacity(0.25))
                                .cornerRadius(12)
                                .foregroundColor(colorScheme == .dark ? .white : (clientUserId == user?._id ? .white :.black))
                        }
                        else if let videoUrl = message.video, let url = URL(string: videoUrl)   {
                            KFImage(url)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 160, height: 160)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        else if let duration = message.duration {
                            VStack {
                                HStack {
                                    Image(systemName: voicePlayer.playingMessageId == message._id ? "speaker.wave.2.fill" : "speaker.fill")
                                    Text(String(duration) + " " + NSLocalizedString("seconds", comment: "seconds"))
                                }
                            }
                            .padding(10)
                            .background(clientUserId == user?._id ? Color.accentColor : Color.gray.opacity(0.25))
                            .cornerRadius(12)
                            .foregroundColor(colorScheme == .dark ? .white : (clientUserId == user?._id ? .white :.black))
                            .onTapGesture {
                                if voicePlayer.playingMessageId == message._id {
                                    voicePlayer.stopAudio()
                                } else {
                                    if let localURL = message.localVoiceMessage ?? downloadedLocalAudioURL {
                                        voicePlayer.playAudio(from: localURL, messageId: message._id)
                                    } else if let url = message.voiceMessage, let url = URL(string: url) {
                                        downloadingAudio = true
                                        voicePlayer.downloadAudioFile(from: url) { result in
                                            downloadingAudio = false
                                            switch result {
                                            case .success(let localURL):
                                                downloadedLocalAudioURL = localURL
                                                voicePlayer.playAudio(from: localURL, messageId: message._id)
                                            case .failure(let error):
                                                print("Error occurred: \(error.localizedDescription)")
                                            }
                                        }
                                    }
                                }
                            }
                            .animation(.easeInOut, value: downloadingAudio)
                            .animation(.easeInOut, value: downloadedLocalAudioURL)
                        }
                        else if let uiImage = message.localImage?.fullResolutionImage {
                            ZStack {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 160, height: 160)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                if message.status == .sending {
                                    Image(systemName: "arrow.up.circle")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                            }
                        } else if let imageUrl = message.image, let url = URL(string: imageUrl)  {
                            KFImage(url)
                                .resizable()
                                .placeholder {
                                    ZStack {
                                        Rectangle()
                                            .foregroundColor(Color.gray.opacity(0.1))
                                            .frame(width: 160, height: 160)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 5))
                                    }
                                }
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 160, height: 160)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        if user?._id == clientUserId {
                            if let urlString = user?.profilePictureUrl, let url = URL(string: urlString) {
                                KFImage(url)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 41, height: 41)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                            }
                        } else {
                            if message.status == .sending || downloadingAudio  {
                                LoadingView()
                                    .frame(height: 35)
                            }
                            if message.status == .failed {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 20))
                                    .frame(height: 35)
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 5)
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let date = dateFormatter.date(from: dateString) else {
            return ""
        }
        
        let calendar = Calendar.current
        let now = Date()
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        
        if calendar.isDateInToday(date) {
            let minutesAgo = calendar.dateComponents([.minute], from: date, to: now).minute ?? 0
            let hoursAgo = calendar.dateComponents([.hour], from: date, to: now).hour ?? 0

            if minutesAgo < 2 {
                return NSLocalizedString("Just now", comment: "Just now")
            } else if minutesAgo < 60 {
                return "\(minutesAgo) " + NSLocalizedString("Minutes ago", comment: "Minutes ago")
            } else if hoursAgo < 12 {
                return "\(hoursAgo) " + NSLocalizedString("Hours ago", comment: "Hours ago")
            } else {
                dateFormatter.dateFormat = NSLocalizedString("h:mm a", comment: "Time format: 3:45 PM")
                return dateFormatter.string(from: date)
            }
        } else {
            if calendar.isDateInYesterday(date) {
                dateFormatter.dateFormat = NSLocalizedString("'Yesterday at' h:mm a", comment: "Time format: Yesterday at 3:45 PM")
            } else {
                dateFormatter.dateFormat = NSLocalizedString("MMM d, yyyy 'at' h:mm a", comment: "Date format: Jan 5, 2021 at 3:45 PM")
            }
            return dateFormatter.string(from: date)
        }
    }
    
}
