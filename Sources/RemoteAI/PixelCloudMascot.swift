import SwiftUI

enum PixelCloudArt {
    static let rows = [
        "......####......",
        "....########....",
        "..############..",
        ".##############.",
        "################",
        "################",
        ".##############.",
        "..############..",
        "...##########...",
        "....########...."
    ]

    static let grid = rows.map(Array.init)
    static let columns = 16
    static let rowCount = rows.count

    static var filledPixelCount: Int {
        grid.reduce(0) { total, row in total + row.filter { $0 == "#" }.count }
    }

    static func isFilled(x: Int, y: Int) -> Bool {
        guard y >= 0, y < grid.count, x >= 0, x < columns else { return false }
        return grid[y][x] == "#"
    }
}

struct PixelCloudMascot: View {
    let state: MascotState
    var blink: Bool = false

    var body: some View {
        PolishedMascotArtwork(state: state)
            .accessibilityHidden(true)
    }
}

struct MascotStatusPixels: View {
    let state: MascotState
    var reduceMotion: Bool = false

    var body: some View {
        EmptyView()
    }
}
