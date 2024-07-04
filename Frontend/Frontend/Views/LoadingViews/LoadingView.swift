//
//  LoadingView.swift
//  Frontend
//
//  Created by Luke Thompson on 26/6/2024.
//

import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Color.accentColor, lineWidth: 1.7)
            .frame(width: 13, height: 13)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            .onAppear {
                self.isAnimating = true
            }
    }
}
