//
//  Notification.swift
//  Frontend
//
//  Created by Luke Thompson on 6/7/2024.
//

import Foundation
import SwiftUI

struct Notification: Codable {
    let pictureUrl: URL?
    let title: String
    let body: String
    let redirectView: AnyView
}
