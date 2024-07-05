//
//  UserPrevview.swift
//  Frontend
//
//  Created by Luke Thompson on 3/7/2024.
//

import SwiftUI
import Kingfisher

struct UserPreview: View {
    var user: User
    
    var body: some View {
        NavigationLink(destination: ProfileView(user: user)) {
            HStack {
                if let urlString = user.profilePictureUrl, let url = URL(string: urlString) {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 41, height: 41)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                VStack (alignment: .leading, spacing: 0) {
                    if let username = user.username {
                        Text(username)
                    }
                    HStack (spacing: 5) {
                        if let nativeLanguages = user.nativeLanguages {
                            let firstNativeLanguage = nativeLanguages[0]
                            let otherLanguages = nativeLanguages.count - 1
                            Text("N:")
                            Image("\(firstNativeLanguage)Flag")
                                .resizable()
                                .frame(width: 15, height: 15)
                            Text("+\(otherLanguages)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .opacity(otherLanguages > 0 ? 1 : 0)
                        }
                        
                        if let targetLanguages = user.targetLanguages {
                            let firstTargetLanguage = targetLanguages[0].language
                            let otherLanguages = targetLanguages.count - 1
                            Text("L:")
                            Image("\(firstTargetLanguage)Flag")
                                .resizable()
                                .frame(width: 15, height: 15)
                            Text("+\(otherLanguages)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .opacity(otherLanguages > 0 ? 1 : 0)
                        }
                    }
                    
                }
            }
        }
    }
}

