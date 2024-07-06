//
//  NotificationView.swift
//  Frontend
//
//  Created by Luke Thompson on 6/7/2024.
//

import SwiftUI
import Kingfisher

struct NotificationView: View {
    @EnvironmentObject var notificationViewModel: NotificationViewModel
    var notification: Notification
    @State private var navigateToDestinationView = false
    var body: some View {
        HStack {
            KFImage(notification.pictureUrl)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 5))
            VStack {
                Text(notification.title)
                Text(notification.body)
            }
        }
        .navigationDestination(isPresented: $navigateToDestinationView) {
            notification.redirectView
        }
        .onTapGesture {
            navigateToDestinationView = true
        }
    }
}

