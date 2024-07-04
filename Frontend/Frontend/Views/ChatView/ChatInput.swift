//
//  ChatInput.swift
//  Frontend
//
//  Created by Luke Thompson on 27/6/2024.
//

import SwiftUI
import TLPhotoPicker

struct ChatInput: View {
    @State private var text: String = ""
    @State private var showAllButtons = false
    @State private var isShowingMediaPicker = false
    @State private var selectedAssets: [TLPHAsset] = []
    @State private var showingVoiceMessageUI = false
    @State private var assetsAreSelected = false
    
    @EnvironmentObject var messagesManager: MessagesManager
    var body: some View {
        VStack {
            HStack {
                if showingVoiceMessageUI {
                    VoiceMessageInput(showingVoiceMessageUI: $showingVoiceMessageUI)

                } else {
                    openOptionsButton
                    textField
                    if text.isEmpty {
                        openVoiceMessageButton
                    } else {
                        sendButton
                    }
                }
                
            }
            options
        }
        .padding(.bottom)
        .padding(.horizontal)
        .animation(.smooth, value: showAllButtons)
        .fullScreenCover(isPresented: $isShowingMediaPicker) {
            CustomTLPhotoPicker(isPresented: $isShowingMediaPicker, selectedAssets: $selectedAssets).onDisappear {
                assetsAreSelected = !selectedAssets.isEmpty
            }
        }
        .fullScreenCover(isPresented: $assetsAreSelected) {
            SelectedMediaPreview(selectedAssets: $selectedAssets)
        }
    }
    
    @ViewBuilder
    private var options: some View {
        if showAllButtons {
            HStack {
                Spacer()
                Button(action: {
                    self.isShowingMediaPicker = true
                }) {
                    Image(systemName: "photo.on.rectangle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .frame(width: 40, height: 40)
                .padding(8)
                .background(Color.white)
                .cornerRadius(10)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "photo.on.rectangle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .frame(width: 40, height: 40)
                .padding(8)
                .background(Color.white)
                .cornerRadius(10)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "photo.on.rectangle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .frame(width: 40, height: 40)
                .padding(8)
                .background(Color.white)
                .cornerRadius(10)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "photo.on.rectangle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .frame(width: 40, height: 40)
                .padding(8)
                .background(Color.white)
                .cornerRadius(10)
                Spacer()
            }
            HStack {
                Spacer()
                Button(action: {}) {
                    Image(systemName: "photo.on.rectangle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .frame(width: 40, height: 40)
                .padding(8)
                .background(Color.white)
                .cornerRadius(10)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "photo.on.rectangle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .frame(width: 40, height: 40)
                .padding(8)
                .background(Color.white)
                .cornerRadius(10)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "photo.on.rectangle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .frame(width: 40, height: 40)
                .padding(8)
                .background(Color.white)
                .cornerRadius(10)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "photo.on.rectangle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .frame(width: 40, height: 40)
                .padding(8)
                .background(Color.white)
                .cornerRadius(10)
                Spacer()
            }
        }
    }
    
    private var openOptionsButton: some View {
        Button(action: {
            showAllButtons.toggle()
        }) {
            Image(systemName: showAllButtons ? "minus.circle.fill" : "plus.circle.fill")
        }
        .font(.system(size: 25))
    }
    
    private var textField: some View {
        TextField(LocalizedStringKey("Type your message"), text: $text, axis: .vertical)
            .padding(10)
           .background(RoundedRectangle(cornerRadius: 15)
                           .strokeBorder(Color.gray, lineWidth: 1))
           .lineLimit(5)
           .font(.system(size: 16))
    }
    
    private var sendButton: some View {
        Button(action: {
            messagesManager.sendTextMessage(text: text)
            text = ""
        }) {
            Image(systemName: "paperplane.fill")
        }
        .font(.system(size: 25))
    }
    
    private var openVoiceMessageButton: some View {
        Button(action: {
            showingVoiceMessageUI.toggle()
        }) {
            Image(systemName: "mic.fill")
                .font(.system(size: 25))
        }
    }
}
