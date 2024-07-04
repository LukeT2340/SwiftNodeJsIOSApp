//
//  CustomTLPhotoPicker.swift
//  Frontend
//
//  Created by Luke Thompson on 27/6/2024.
//

import Combine
import SwiftUI
import TLPhotoPicker
import Photos

struct CustomTLPhotoPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedAssets: [TLPHAsset]
    
    func makeUIViewController(context: Context) -> TLPhotosPickerViewController {
        let viewController = TLPhotosPickerViewController()
        viewController.delegate = context.coordinator
        
        var configure = TLPhotosPickerConfigure()
        configure.allowedVideo = true
        configure.allowedLivePhotos = true
        configure.allowedVideoRecording = false
        configure.maxSelectedAssets = 10
        
        viewController.configure = configure
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: TLPhotosPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, TLPhotosPickerViewControllerDelegate {
        var parent: CustomTLPhotoPicker
        
        init(_ parent: CustomTLPhotoPicker) {
            self.parent = parent
        }
        
        func shouldDismissPhotoPicker(withTLPHAssets: [TLPHAsset]) -> Bool {
            parent.selectedAssets = withTLPHAssets
            parent.isPresented = false
            return true
        }
        
    }
}

extension TLPHAsset: Identifiable {
    public var id: String {
        let uuid = UUID()
        let localIdentifier = uuid.uuidString
        return localIdentifier
    }
}
