//
//  ProfileView.swift
//  Frontend
//
//  Created by Luke Thompson on 24/6/2024.
//

import SwiftUI
import Kingfisher

struct ProfileView: View {
    @StateObject var profileInfoManager = ProfileInfoManager()

    @State var user: User
    
    var body: some View {
        ZStack {
            ScrollView {
                top
                ProfileSlidingTabView(user: user)
                    .environmentObject(profileInfoManager)
            }
            ProfileBottomBar(user: user)
        }
        .navigationTitle(LocalizedStringKey("Profile"))
        .navigationBarItems(trailing:
                                Button(action: {}) {
            Image(systemName: "ellipsis")
        }
        )
    }
    
    private var top: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack (alignment: .center) {
                VStack(alignment: .leading, spacing: 20) {
                    if let profilePictureUrl = user.profilePictureUrl, let url = URL(string: profilePictureUrl) {
                        KFImage(url)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .shadow(radius: 10)
                    }
                    
                }
                LanguagesDisplay(nativeLanguages: user.nativeLanguages ?? [], targetLanguages: user.targetLanguages ?? [])
                Spacer()
            }
            Text(user.username ?? "Unknown User")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 5)
            
            Text(user.bio ?? "No bio available")
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            
            Spacer()
        }
        .padding()
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(user: User(
            _id: "1",
            username: "Luke",
            email: "example@example.com",
            profilePictureUrl: "https://firebasestorage.googleapis.com/v0/b/mylanguageapp-b7504.appspot.com/o/profileImages%2Fimage0.jpeg?alt=media&token=4dae410d-d28c-4172-8ac0-a166ab62cada",
            targetLanguages: [User.Language(language: "Mandarin", proficiency: 4)],
            nativeLanguages: ["English"],
            bio: "This is a sample bio.",
            createdAt: "2024-06-23T11:11:55.001Z",
            idealLanguagePartner: "Someone who is patient and actually interested in learning",
            hobbies: ["Running", "Reading", "Sleeping"],
            languageGoals: "Good good study, day day up up. Get to a native speaker level."
        ))
            .previewLayout(.sizeThatFits)
            .frame(maxWidth: .infinity)
    }
}
