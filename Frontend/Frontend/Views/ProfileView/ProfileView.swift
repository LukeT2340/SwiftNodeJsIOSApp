//
//  ProfileView.swift
//  Frontend
//
//  Created by Luke Thompson on 24/6/2024.
//

import SwiftUI
import Kingfisher

struct ProfileView: View {
    @State var user: User
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let profilePictureUrl = user.profilePictureUrl, let url = URL(string: profilePictureUrl) {
                        KFImage(url)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                            .padding(.top, 20)
                    }
                    
                    Text(user.username ?? "Unknown User")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 5)
                    
                    Text(user.bio ?? "No bio available")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(LocalizedStringKey("Target Languages"))
                            .font(.headline)
                        
                        ForEach(user.targetLanguages ?? [], id: \.language) { lang in
                            HStack {
                                Text(lang.language)
                                Spacer()
                                Text("Proficiency: \(lang.proficiency)")
                            }
                        }
                    }
                    .padding(.bottom, 20)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(LocalizedStringKey("Native Languages"))
                            .font(.headline)
                        
                        ForEach(user.nativeLanguages ?? [], id: \.self) { lang in
                            Text(lang)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .navigationTitle(LocalizedStringKey("Profile"))
                .navigationBarItems(trailing:
                                        Button(action: {}) {
                    Image(systemName: "ellipsis")
                }
                )
            }
            ProfileTabView(user: user)
        }
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
            createdAt: "2024-06-23T11:11:55.001Z"
        ))
            .previewLayout(.sizeThatFits)
            .frame(maxWidth: .infinity)
    }
}
