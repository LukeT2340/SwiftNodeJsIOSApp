//
//  SelectedMediaPreview.swift
//  Frontend
//
//  Created by Luke Thompson on 27/6/2024.
//

import SwiftUI
import TLPhotoPicker
import Photos
import AVKit

struct SelectedMediaPreview: View {
    @Binding var selectedAssets: [TLPHAsset]
    @EnvironmentObject var messagesManager: MessagesManager
    
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        VStack(spacing: 10) {
            Text(LocalizedStringKey("Selected media"))
                .font(.title2)
            mediaDisplay
            
            Spacer()
            customNavBar
        }
        .padding()
    }
       
    private var mediaDisplay: some View {
        ScrollView {
            ForEach(0..<selectedAssets.count / 2 + selectedAssets.count % 2, id: \.self) { rowIndex in
                HStack(spacing: 10) {
                    ForEach(0..<2) { columnIndex in
                        let index = rowIndex * 2 + columnIndex
                        if index < selectedAssets.count {
                            let asset = selectedAssets[index]
                            if let uiImage = asset.fullResolutionImage {
                                if asset.type == .video {
                                    ZStack {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 160, height: 160)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 5))
                                        Image(systemName: "video.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: 150, maxHeight: 150, alignment: .bottomLeading)
                                    }
                                } else if asset.type == .photo {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 160, height: 160)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                }
                            }
                        } else {
                            Spacer()
                                .frame(width: 160, height: 160)
                        }
                    }
                }
            }
            .padding(10)
        }
    }
    
    private var customNavBar: some View {
        HStack {
            Button(action: {
                selectedAssets = []
                presentationMode.wrappedValue.dismiss()
            }) {
                Text(LocalizedStringKey("Cancel"))
                    .padding()
                    .background(Color.gray.opacity(0.4))
                    .fontWeight(.medium)
                    .cornerRadius(4)
            }
            Spacer()
            Button(action: {
                messagesManager.sendMediaMultiple(assets: selectedAssets)
                selectedAssets = []
                presentationMode.wrappedValue.dismiss()
            }) {
                Text(LocalizedStringKey("Send selected (\(selectedAssets.count))"))
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                    .cornerRadius(4)
            }
        }
    }
    
    
}
