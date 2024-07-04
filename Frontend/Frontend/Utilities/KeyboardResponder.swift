//
//  KeyboardResponder.swift
//  Frontend
//
//  Created by Luke Thompson on 28/6/2024.
//

import SwiftUI
import Combine

class KeyboardResponder: ObservableObject {
    @Published var isKeyboardVisible: Bool = false
    private var cancellables: Set<AnyCancellable> = []

    init() {
        let willShowPublisher = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { _ in true }

        let willHidePublisher = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in false }

        Publishers.Merge(willShowPublisher, willHidePublisher)
            .assign(to: \.isKeyboardVisible, on: self)
            .store(in: &cancellables)
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
