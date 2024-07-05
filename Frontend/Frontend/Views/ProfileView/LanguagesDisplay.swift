//
//  LanguagesDisplay.swift
//  Frontend
//
//  Created by Luke Thompson on 5/7/2024.
//

import SwiftUI

struct LanguagesDisplay: View {
    var nativeLanguages: [String]
    var targetLanguages: [User.Language]
    
    var body: some View {
        VStack (alignment: .leading) {
            ScrollView(.horizontal) {
                HStack(alignment: .bottom, spacing: 10) {
                    Image(systemName: "globe.asia.australia.fill")
                        .foregroundColor(.accentColor)
                    let nativeLanguageCount = nativeLanguages.count
                    ForEach(0..<nativeLanguageCount, id: \.self) { index in
                        NativeLanguageDisplay(languageName: nativeLanguages[index])
                    }
                    Spacer()
                }
                Divider()
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "character.book.closed.fill")
                        .foregroundColor(.accentColor)
                    let targetLanguageCount = targetLanguages.count
                    ForEach(0..<targetLanguageCount, id: \.self) { index in
                        TargetLanguageDisplay(language: targetLanguages[index])
                    }
                    Spacer()
                }
            }
        }
        .padding(.leading)
        .font(.system(size: 25))
    }
}

struct NativeLanguageDisplay: View {
    var languageName: String
    
    var body: some View {
        VStack (alignment: .center, spacing: 0) {
            HStack (spacing: 3) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: "suit.diamond.fill")
                        .font(.system(size: 6))
                        .foregroundColor(Color.accentColor)
                        .opacity(0)
                }
            }
            let flagName = "\(languageName)Flag"
            Image(flagName)
                .resizable()
                .frame(width: 25, height: 25)
            .padding(.top, 5)
        }
    }
}

struct TargetLanguageDisplay: View {
    var language: User.Language
    
    var body: some View {
        VStack (alignment: .center, spacing: 0) {
            let languageName = language.language
            let flagName = "\(languageName)Flag"
            Image(flagName)
                .resizable()
                .frame(width: 25, height: 25)
            HStack (spacing: 3) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: "suit.diamond.fill")
                        .font(.system(size: 6))
                        .foregroundColor(Color.accentColor)
                        .opacity(index < language.proficiency ? 1 : 0.2)
                }
            }
            .padding(.top, 5)
        }
    }
}
