//
//  NotificationViewModel.swift
//  Frontend
//
//  Created by Luke Thompson on 6/7/2024.
//

import Foundation
import SwiftUI
import Combine
import SocketIO

class NotificationViewModel: ObservableObject {
    @Published var isShowing: Bool = false
    @Published var notification: Notification?
    @Published var socketConnected = false

    private var manager: SocketManager!
    private var socket: SocketIOClient!
    private var queue: [Notification] = []
    private var timer: AnyCancellable?

    func showNotification(_ notification: Notification, duration: TimeInterval = 3) {
        queue.append(notification)
        if !isShowing {
            showNextNotification(duration: duration)
        }
    }

    private func showNextNotification(duration: TimeInterval) {
        guard !queue.isEmpty else { return }
        self.notification = queue.removeFirst()
        withAnimation {
            self.isShowing = true
        }

        timer?.cancel()
        timer = Timer.publish(every: duration, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                withAnimation {
                    self?.isShowing = false
                }
                self?.timer?.cancel()
                self?.showNextNotification(duration: duration)
            }
    }
    
    private func setupSocket(completion: @escaping () -> Void) {
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            print("Backend URL not set")
            completion()
            return
        }
        
        guard let _id = UserDefaults.standard.string(forKey: "_id") else {
            print("User Id not set")
            completion()
            return
        }
        
        manager = SocketManager(socketURL: URL(string: backendURL)!, config: [
            .connectParams(["clientUserId": _id])
        ])
        socket = manager.defaultSocket
        
        socket.on(clientEvent: .connect) { data, ack in
            DispatchQueue.main.async {
                self.socketConnected = true
            }
        }
        
        socket.on("Notification") { data, ack in
           if let notificationData = data.first as? [String: Any] {
               do {
                   let jsonData = try JSONSerialization.data(withJSONObject: notificationData, options: [])
                   let notification = try JSONDecoder().decode(Notification.self, from: jsonData)
                   self.showNotification(notification)
               } catch {
                   print("Failed to decode notification: \(error)")
               }
           }
        }
           
        
        socket.on(clientEvent: .disconnect) { data, ack in
            print("Socket disconnected")
            DispatchQueue.main.async {
                self.socketConnected = false
            }
        }
        
        socket.on(clientEvent: .disconnect) { data, ack in
            DispatchQueue.main.async {
                self.socketConnected = false
            }
            print("Socket disconnected")
        }
        
        socket.on(clientEvent: .reconnect) { data, ack in
            DispatchQueue.main.async {
                self.socketConnected = false
            }
            print("Socket reconnecting")
        }
        
        socket.on(clientEvent: .reconnectAttempt) { data, ack in
            DispatchQueue.main.async {
                self.socketConnected = false
            }
            print("Socket reconnect attempt")
        }
        
        socket.on(clientEvent: .error) { data, ack in
            DispatchQueue.main.async {
                self.socketConnected = false
            }
            print("Socket error: \(data)")
        }
        
        socket.connect()
    }
}
