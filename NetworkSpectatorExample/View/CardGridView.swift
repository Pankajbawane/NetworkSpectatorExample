//
//  CardGridView.swift
//  NetworkSpectatorExample
//
//  Example app demonstrating NetworkSpectator framework for iOS/macOS
//  https://github.com/Pankajbawane/NetworkSpectator
//
//  Created by Pankaj Bawane on 02/03/26.
//

import SwiftUI

/// A reusable grid layout that displays items as rounded rectangle cards.
/// Columns adapt based on available width.
struct CardGridView<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let cardColor: Color
    @ViewBuilder let content: (Item) -> Content

    private let spacing: CGFloat = 10
    private let minCardWidth: CGFloat = 160
    private let cardHeight: CGFloat = 100

    @State private var gridHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let columns = max(1, Int(availableWidth / (minCardWidth + spacing)))
            let cardWidth = (availableWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns)
            let rows = items.isEmpty ? 0 : (items.count + columns - 1) / columns

            Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
                ForEach(0..<rows, id: \.self) { rowIndex in
                    GridRow {
                        ForEach(0..<columns, id: \.self) { columnIndex in
                            let index = rowIndex * columns + columnIndex
                            if index < items.count {
                                content(items[index])
                                    .frame(width: cardWidth, height: cardHeight)
                                    .background(cardColor.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(cardColor.opacity(0.3), lineWidth: 1)
                                    )
                            } else {
                                Color.clear
                                    .frame(width: cardWidth, height: cardHeight)
                            }
                        }
                    }
                }
            }
            .background(
                GeometryReader { gridGeometry in
                    Color.clear
                        .onAppear { gridHeight = gridGeometry.size.height }
                        .onChange(of: gridGeometry.size.height) { _, newHeight in
                            gridHeight = newHeight
                        }
                }
            )
        }
        .frame(height: gridHeight)
        .padding(.horizontal)
    }
}
