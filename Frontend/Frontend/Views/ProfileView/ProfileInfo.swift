//
//  ProfileInfo.swift
//  Frontend
//
//  Created by Luke Thompson on 5/7/2024.
//

import SwiftUI

struct ProfileInfo: View {
    var user: User
    
    var body: some View {
        VStack (alignment: .leading) {
            if let idealLanguagePartner = user.idealLanguagePartner {
                Text(LocalizedStringKey("Ideal language partner"))
                    .fontWeight(.medium)
                    .bold()
                    .padding(.bottom, 5)
                Text(idealLanguagePartner)
                    .fontWeight(.medium)
                    .font(.footnote)
                Divider()
            }
            if let hobbies = user.hobbies {
                Text(LocalizedStringKey("Hobbies"))
                    .fontWeight(.medium)
                    .bold()
                    .padding(.bottom, 5)
                let hobbiesCount = hobbies.count
                ForEach(0..<hobbiesCount, id: \.self) { index in
                    HStack {
                        Text("•")
                            .font(.system(size: 20))
                            .foregroundColor(.accentColor)
                        
                        Text(hobbies[index])
                            .fontWeight(.medium)
                            .font(.footnote)
                    }
                    .padding(.leading)
                }
                Divider()
            }
            if let languageGoals = user.languageGoals {
                Text(LocalizedStringKey("Language goals"))
                    .fontWeight(.medium)
                    .bold()
                    .padding(.bottom, 5)
                Text(languageGoals)
                    .fontWeight(.medium)
                    .font(.footnote)
                Divider()
            }
            HStack {
                Spacer()
            }
        }
    }
}
