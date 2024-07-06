//
//  ProfileSlidingTabView.swift
//  Frontend
//
//  Created by Luke Thompson on 5/7/2024.
//

import SwiftUI

struct ProfileSlidingTabView: View {    
    var user: User
    @State private var selectedTab: Tab = .info
    @State var tabItemWidth: CGFloat = 0

    var body: some View {
        VStack {
            HStack {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }) {
                        Text(tab.displayName)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(selectedTab == tab ? Color.accentColor : Color.secondary)
                    }
                    .overlay(
                        GeometryReader { proxy in
                            Color.clear.preference(key: TabPreferenceKey.self, value: proxy.size.width)
                        }
                    )
                    .onPreferenceChange(TabPreferenceKey.self) { value in
                        tabItemWidth = value
                    }
                }
            }
            .overlay(
                 overlay
             )
            .padding(.bottom)
            
            if selectedTab == .info {
                ProfileInfo(user: user)
            }
            if selectedTab == .notes {
                ProfileNotes(user: user)
            }
            if selectedTab == .media {
                EmptyView()
            }
        }
    }
    
    private var overlay: some View {
        HStack {
            if selectedTab == .media {
                Spacer()
            }
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: 35, height: 3)
                .cornerRadius(3)
                .frame(width: tabItemWidth)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .offset(y: 10)
            if selectedTab == .info {
                Spacer()
            }
            
        }
    }
}

enum Tab: CaseIterable {
    case info
    case notes
    case media
    
    var displayName: LocalizedStringKey {
        switch self {
        case .info:
            return LocalizedStringKey("Info")
        case .notes:
            return LocalizedStringKey("Notes")
        case .media:
            return LocalizedStringKey("Media")
        }
    }
}


struct TabPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
