import SwiftUI

struct GeometricBackground: View {
    
    // 0.7 = slower, 1 = original speed.
    var speed: Double = 0.7
    @Environment(\.colorScheme)
    private var colorScheme

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @Environment(\.scenePhase)
    private var scenePhase

    @State private var tiles = Self.generateTiles()
    @State private var swappingIDs: Set<Int> = []
    @State private var coloringID: Int?
    
    private var themeColor: Color {
        colorScheme == .dark
            ? DesignSystem.Palette.brand800
            : DesignSystem.Palette.brand200
    }

    private enum TileShape: CaseIterable {
        case circle, square, diamond
    }

    private struct Tile: Identifiable {
        let id: Int
        let shape: TileShape

        var column: Int
        var row: Int
        var colorIndex: Int
    }

    private var palette: [Color] {
        colors.isEmpty
            ? [DesignSystem.Semantic.foregroundPrimary]
            : colors
    }

    private var playbackSpeed: Double {
        max(0.05, speed)
    }

    private var shouldAnimate: Bool {
        !reduceMotion && scenePhase == .active
    }

    private var animationKey: String {
        "\(shouldAnimate)-\(palette.count)-\(playbackSpeed)"
    }
    
    private var colors: [Color] {
        [
            DesignSystem.Semantic.foregroundPrimary,
            themeColor,
            DesignSystem.Palette.brand500
        ]
    }

    var body: some View {
        GeometryReader { geometry in
            let cell = min(
                geometry.size.width / 2.67,
                geometry.size.height / 4
            )

            let originX = (geometry.size.width - cell * 4) / 2
            let originY: CGFloat = 0

            ZStack(alignment: .topLeading) {
                ForEach(tiles) { tile in
                    tileArtwork(tile)
                        .frame(width: cell, height: cell)
                        .position(
                            x: originX
                                + (CGFloat(tile.column) + 0.5) * cell,
                            y: originY
                                + (CGFloat(tile.row) + 0.5) * cell
                        )
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .clipped()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: animationKey) {
            guard shouldAnimate else { return }

            do {
                async let swaps: Void = animateSwaps()
                async let colorChanges: Void = animateColors()

                _ = try await (swaps, colorChanges)
            } catch {
                // Cancellation stops both loops.
            }
        }
    }

    // MARK: - Tile appearance

    private func tileArtwork(_ tile: Tile) -> some View {
        GeometryReader { geometry in
            let rect = CGRect(
                origin: .zero,
                size: geometry.size
            )

            path(for: tile.shape, in: rect)
                .fill(palette[resolvedColorIndex(for: tile)])
        }
    }

    private func resolvedColorIndex(for tile: Tile) -> Int {
        tile.colorIndex % palette.count
    }

    // MARK: - Position swaps

    @MainActor
    private func animateSwaps() async throws {
        var previousIDs: Set<Int> = []

        defer {
            swappingIDs = []
        }

        try await pause(0.3)

        while !Task.isCancelled {
            let pairs = neighboringPairs().filter { pair in
                tiles[pair.0].id != coloringID
                    && tiles[pair.1].id != coloringID
            }

            let freshPairs = pairs.filter { pair in
                !previousIDs.contains(tiles[pair.0].id)
                    && !previousIDs.contains(tiles[pair.1].id)
            }

            guard let pair = (
                freshPairs.isEmpty ? pairs : freshPairs
            ).randomElement() else {
                try await pause(0.15)
                continue
            }

            let first = pair.0
            let second = pair.1

            swappingIDs = [
                tiles[first].id,
                tiles[second].id
            ]

            previousIDs = swappingIDs

            let firstColumn = tiles[first].column
            let firstRow = tiles[first].row
            let secondColumn = tiles[second].column
            let secondRow = tiles[second].row

            withAnimation(
                .timingCurve(
                    0.42, 0,
                    0.22, 1,
                    duration: 0.55 / playbackSpeed
                )
            ) {
                tiles[first].column = secondColumn
                tiles[first].row = secondRow

                tiles[second].column = firstColumn
                tiles[second].row = firstRow
            }

            try await pause(0.6)

            swappingIDs = []

            try await pause(Double.random(in: 0.15...0.35))
        }
    }

    // MARK: - Independent color changes

    @MainActor
    private func animateColors() async throws {
        var previousID: Int?

        defer {
            coloringID = nil
        }

        // A single-color palette doesn't need color animations.
        guard palette.count > 1 else { return }

        try await pause(0.5)

        while !Task.isCancelled {
            let available = tiles.indices.filter {
                !swappingIDs.contains(tiles[$0].id)
            }

            let fresh = available.filter {
                tiles[$0].id != previousID
            }

            guard let index = (
                fresh.isEmpty ? available : fresh
            ).randomElement() else {
                try await pause(0.15)
                continue
            }

            coloringID = tiles[index].id
            previousID = coloringID

            let currentColor = resolvedColorIndex(for: tiles[index])

            // Pick another palette entry without repeating the current one.
            let offset = Int.random(in: 1..<palette.count)
            let nextColor = (currentColor + offset) % palette.count

            withAnimation(
                .easeInOut(duration: 0.4 / playbackSpeed)
            ) {
                tiles[index].colorIndex = nextColor
            }

            try await pause(0.45)

            coloringID = nil

            try await pause(Double.random(in: 0.2...0.45))
        }
    }

    // MARK: - Grid

    private func neighboringPairs() -> [(Int, Int)] {
        var pairs: [(Int, Int)] = []

        for first in tiles.indices {
            for second in tiles.indices where second > first {
                let distance =
                    abs(tiles[first].column - tiles[second].column)
                    + abs(tiles[first].row - tiles[second].row)

                let looksDifferent =
                    tiles[first].shape != tiles[second].shape
                    || resolvedColorIndex(for: tiles[first])
                        != resolvedColorIndex(for: tiles[second])

                if distance == 1 && looksDifferent {
                    pairs.append((first, second))
                }
            }
        }

        return pairs
    }

//    private static func generateTiles() -> [Tile] {
//        let positions = Array((0..<16).shuffled().prefix(12))
//        let shapes = (0..<12).map {
//            TileShape.allCases[$0 % TileShape.allCases.count]
//        }.shuffled()
//
//        return positions.sorted().enumerated().map { index, position in
//            Tile(
//                id: position,
//                shape: shapes[index],
//                column: position % 4,
//                row: position / 4,
//                colorIndex: Int.random(in: 0..<1_000_000)
//            )
//        }
//    }
    
    private static func generateTiles() -> [Tile] {
        let shapes = (0..<16).map {
            TileShape.allCases[$0 % TileShape.allCases.count]
        }.shuffled()

        return (0..<16).map { position in
            Tile(
                id: position,
                shape: shapes[position],
                column: position % 4,
                row: position / 4,
                colorIndex: Int.random(in: 0..<1_000_000)
            )
        }
    }

    // MARK: - Drawing

    private func path(
        for shape: TileShape,
        in rect: CGRect
    ) -> Path {
        switch shape {
        case .circle:
            return Path(ellipseIn: rect)

        case .square:
            return Path(rect)

        case .diamond:
            return Path { path in
                path.move(
                    to: CGPoint(x: rect.midX, y: rect.minY)
                )
                path.addLine(
                    to: CGPoint(x: rect.maxX, y: rect.midY)
                )
                path.addLine(
                    to: CGPoint(x: rect.midX, y: rect.maxY)
                )
                path.addLine(
                    to: CGPoint(x: rect.minX, y: rect.midY)
                )
                path.closeSubpath()
            }
        }
    }

    // MARK: - Timing

    private func pause(_ seconds: Double) async throws {
        try await Task.sleep(
            nanoseconds: UInt64(
                (seconds / playbackSpeed) * 1_000_000_000
            )
        )
    }
}
