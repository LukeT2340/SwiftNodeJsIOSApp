//
//  ScrollOffsetPreferenceKey.swift
//  Frontend
//
//  Created by Luke Thompson on 28/6/2024.
//

import SwiftUI

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero

    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {

    }
}
