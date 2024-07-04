//
//  AppDelegate.swift
//  Frontend
//
//  Created by Luke Thompson on 26/6/2024.
//

import Foundation
import SwiftUI
import UIKit
import UserNotifications
import Alamofire

class AppDelegate: NSObject, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Request permission for notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        // Send this token to your backend server
        sendTokenToServer(token)
    }

    func sendTokenToServer(_ apnToken: String) {
        guard let backendURL = UserDefaults.standard.string(forKey: "backend_url") else {
            print("Backend URL not set")
            return
        }
        
        guard let authToken = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not set")
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(authToken)"
        ]
        
        let endpointURL = "\(backendURL)/auth/submitAPNToken"
        let parameters: [String: Any] = ["apnToken": apnToken]
        
        AF.request(endpointURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseData { response in
                switch response.result {
                case .success(let data):
                    print("Raw response data: \(String(data: data, encoding: .utf8) ?? "No data")")
                case .failure(let error):
                    print("APN token submission failed: \(error.localizedDescription)")
                }
            }
    }
    
    
}
