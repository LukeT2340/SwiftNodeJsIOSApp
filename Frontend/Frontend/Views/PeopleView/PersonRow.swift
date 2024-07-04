//
//  PersonRow.swift
//  Frontend
//
//  Created by Luke Thompson on 23/6/2024.
//

import SwiftUI
import Kingfisher

struct PersonRow: View {
    var user: User
    
    var body: some View {
        HStack {
            if let profilePictureUrl = user.profilePictureUrl, let url = URL(string: profilePictureUrl) {
                KFImage(url)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            
            VStack(alignment: .leading) { // Align content to the leading edge
                if let username = user.username {
                    Text(username)
                        .font(.headline)
                }
                
                if let bio = user.bio {
                    Text(bio)
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 8)
            Spacer()
            VStack (spacing: 5) {
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
                }
                HStack (spacing: 5) {
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

struct PersonRow_Previews: PreviewProvider {
    static var previews: some View {
        PersonRow(user: User(_id: "1", username: "Luke", email: "example@example.com", profilePictureUrl: "https://firebasestorage.googleapis.com/v0/b/mylanguageapp-b7504.appspot.com/o/profileImages%2Fimage0.jpeg?alt=media&token=4dae410d-d28c-4172-8ac0-a166ab62cada", targetLanguages: [User.Language(language: "Mandarin", proficiency: 4)], nativeLanguages: ["English"], bio: "This is a sample bio.", createdAt: "2024-06-23T11:11:55.001Z"))
            .previewLayout(.sizeThatFits)
            .frame(maxWidth: .infinity)
    }
}
