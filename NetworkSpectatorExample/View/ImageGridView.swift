//
//  ImageGridView.swift
//  NetworkSpectatorExample
//
//  Example app demonstrating NetworkSpectator framework for iOS/macOS
//  https://github.com/Pankajbawane/NetworkSpectator
//
//  Created by Pankaj Bawane on 27/02/26.
//

import SwiftUI
import Foundation

struct ImageGridView: View {
    let images: [ImageItem]
    
    private let spacing: CGFloat = 12
    private let minImageWidth: CGFloat = 100
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let columns = max(1, Int(availableWidth / (minImageWidth + spacing)))
            let imageWidth = (availableWidth - (spacing * CGFloat(columns + 1))) / CGFloat(columns)
            let imageHeight = imageWidth * 0.75
            
            ScrollView {
                gridContent(columns: columns, imageWidth: imageWidth, imageHeight: imageHeight)
                    .padding(spacing)
            }
        }
    }
    
    private func gridContent(columns: Int, imageWidth: CGFloat, imageHeight: CGFloat) -> some View {
        let rowCount = (images.count + columns - 1) / columns
        return Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
            ForEach(0..<rowCount, id: \.self) { rowIndex in
                GridRow {
                    ForEach(0..<columns, id: \.self) { columnIndex in
                        gridCell(rowIndex: rowIndex, columnIndex: columnIndex, columns: columns, imageWidth: imageWidth, imageHeight: imageHeight)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func gridCell(rowIndex: Int, columnIndex: Int, columns: Int, imageWidth: CGFloat, imageHeight: CGFloat) -> some View {
        let index = rowIndex * columns + columnIndex
        if index < images.count {
            ImageCacheView(url: images[index].download_url, width: imageWidth, height: imageHeight)
        } else {
            Color.clear
        }
    }
}

private final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, CGImage>()
    
    private init() {
        cache.countLimit = 0
    }
    
    func image(forKey key: String) -> CGImage? {
        cache.object(forKey: key as NSString)
    }
    
    func setImage(_ image: CGImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

struct ImageCacheView: View {
    
    enum Phase {
        case loading
        case loaded(CGImage)
        case failure
    }
    
    let width: CGFloat
    let height: CGFloat
    
    @State private var phase: Phase = .loading
    let url: String
    
    init(url: String, width: CGFloat, height: CGFloat) {
        self.url = url
        self.width = width
        self.height = height
    }
    
    var body: some View {
        Group {
            switch phase {
            case .loading:
                ProgressView()
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
            case .loaded(let uiImage):
                Image(uiImage, scale: 0.1, label: Text("Image"))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

            case .failure:
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
                    .frame(width: width, height: height)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .task {
            if let cached = ImageCache.shared.image(forKey: url) {
                phase = .loaded(cached)
            } else {
                do {
                    let data = try await fetchData(from: url)
                    if let downsampled = downsample(data: data, toWidth: width, height: height) {
                        ImageCache.shared.setImage(downsampled, forKey: url)
                        phase = .loaded(downsampled)
                    } else {
                        phase = .failure
                    }
                } catch {
                    phase = .failure
                }
            }
        }
    }
    
    private func fetchData(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
    
    private func downsample(data: Data, toWidth width: CGFloat, height: CGFloat) -> CGImage? {
        let maxPixelSize = max(width, height) * 2.0
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
