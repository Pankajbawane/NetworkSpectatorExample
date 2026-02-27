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

struct ImageGridView: View {
    let images: [ImageItem]
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let spacing: CGFloat = 12
            let minImageWidth: CGFloat = 100
            
            // Calculate optimal number of columns based on available width
            let columns = max(1, Int(availableWidth / (minImageWidth + spacing)))
            
            // Calculate dynamic image size to fit the available width
            let imageWidth = (availableWidth - (spacing * CGFloat(columns + 1))) / CGFloat(columns)
            let imageHeight = imageWidth * 0.75 // Maintain 4:3 aspect ratio
            
            ScrollView {
                Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
                    ForEach(0..<(images.count + columns - 1) / columns, id: \.self) { rowIndex in
                        GridRow {
                            ForEach(0..<columns, id: \.self) { columnIndex in
                                let index = rowIndex * columns + columnIndex
                                if index < images.count {
                                    let image = images[index]
                                    AsyncImage(url: URL(string: image.download_url)) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(width: imageWidth, height: imageHeight)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: imageWidth, height: imageHeight)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        case .failure:
                                            Image(systemName: "photo")
                                                .foregroundStyle(.secondary)
                                                .frame(width: imageWidth, height: imageHeight)
                                                .background(Color.secondary.opacity(0.2))
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                } else {
                                    Color.clear
                                        .frame(width: imageWidth, height: imageHeight)
                                }
                            }
                        }
                    }
                }
                .padding(spacing)
            }
        }
    }
}
