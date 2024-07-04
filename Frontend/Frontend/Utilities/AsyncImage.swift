//
//  AsyncImage.swift
//  Frontend
//
//  Created by Luke Thompson on 23/6/2024.
//

import SwiftUI
import UIKit
import Foundation
import Combine

// An efficient way of presenting and caching images
struct AsyncImageView: View {
    @StateObject private var loader = ObservableImageLoader()
    let url: URL

    init(url: URL) {
        self.url = url
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
            } else {
                Text("")
                    .foregroundColor(.gray)
                    .frame(width: 100, height: 100)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .onAppear {
            loader.loadImage(from: url)
        }
    }
}

/*
 These classes are used for loading cached images
 */

class ObservableImageLoader: ObservableObject {
    @Published var image: UIImage?
    
    func loadImage(from url: URL) {
        ImageLoader.shared.loadImage(from: url) { [weak self] image in
            self?.image = image
        }
    }
}

class ImageLoader: ObservableObject {
    static let shared = ImageLoader()
    private let cache = NSCache<NSURL, UIImage>()
    @Published var downloadedImage: UIImage?

    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        // Check memory cache
        if let cachedImage = cache.object(forKey: url as NSURL) {
            completion(cachedImage)
            return
        }

        // Check disk cache
        if let diskCachedImage = DiskCacheManager.shared.loadImage(for: url) {
            cache.setObject(diskCachedImage, forKey: url as NSURL)
            completion(diskCachedImage)
            return
        }

        // Download image
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.cache.setObject(image, forKey: url as NSURL)
                    DiskCacheManager.shared.saveImage(image, for: url)
                    completion(image)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}

class DiskCacheManager {
    static let shared = DiskCacheManager()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ImageCache", isDirectory: true)

        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }

    func saveImage(_ image: UIImage, for url: URL) {
        guard let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else { return }
        let filePath = cacheDirectory.appendingPathComponent(url.lastPathComponent)
        try? data.write(to: filePath)
    }

    func loadImage(for url: URL) -> UIImage? {
        let filePath = cacheDirectory.appendingPathComponent(url.lastPathComponent)
        guard let data = try? Data(contentsOf: filePath) else { return nil }
        return UIImage(data: data)
    }
}
