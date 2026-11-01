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
    let blink: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Canvas { context, size in
            let pixel = floor(min(
                size.width / CGFloat(PixelCloudArt.columns),
                size.height / CGFloat(PixelCloudArt.rowCount)
            ))
            let artWidth = pixel * CGFloat(PixelCloudArt.columns)
            let artHeight = pixel * CGFloat(PixelCloudArt.rowCount)
            let origin = CGPoint(
                x: floor((size.width - artWidth) / 2),
                y: floor((size.height - artHeight) / 2)
            )

            for y in 0..<PixelCloudArt.rowCount {
                for x in 0..<PixelCloudArt.columns where PixelCloudArt.isFilled(x: x, y: y) {
                    let edge = !PixelCloudArt.isFilled(x: x - 1, y: y)
                        || !PixelCloudArt.isFilled(x: x + 1, y: y)
                        || !PixelCloudArt.isFilled(x: x, y: y - 1)
                        || !PixelCloudArt.isFilled(x: x, y: y + 1)
                    let color = edge
                        ? MascotDesign.Palette.cloudShade(for: colorScheme)
                        : MascotDesign.Palette.cloudFill(for: colorScheme)
                    Self.fillPixel(
                        context: &context,
                        x: x,
                        y: y,
                        width: 1,
                        height: 1,
                        origin: origin,
                        pixel: pixel,
                        color: color
                    )
                }
            }

            Self.drawFace(
                context: &context,
                state: state,
                blink: blink,
                origin: origin,
                pixel: pixel,
                ink: MascotDesign.Palette.faceInk(for: colorScheme)
            )
        }
        .accessibilityHidden(true)
    }

    private static func drawFace(
        context: inout GraphicsContext,
        state: MascotState,
        blink: Bool,
        origin: CGPoint,
        pixel: CGFloat,
        ink: Color
    ) {
        let sleeping: Bool
        if case .offline = state { sleeping = true } else { sleeping = false }

        if sleeping || blink {
            fillPixel(context: &context, x: 5, y: 5, width: 2, height: 1, origin: origin, pixel: pixel, color: ink)
            fillPixel(context: &context, x: 10, y: 5, width: 2, height: 1, origin: origin, pixel: pixel, color: ink)
        } else {
            fillPixel(context: &context, x: 5, y: 4, width: 1, height: 2, origin: origin, pixel: pixel, color: ink)
            fillPixel(context: &context, x: 10, y: 4, width: 1, height: 2, origin: origin, pixel: pixel, color: ink)
        }

        switch state {
        case .waiting:
            fillPixel(context: &context, x: 6, y: 6, width: 1, height: 1, origin: origin, pixel: pixel, color: ink)
            fillPixel(context: &context, x: 7, y: 7, width: 2, height: 1, origin: origin, pixel: pixel, color: ink)
            fillPixel(context: &context, x: 9, y: 6, width: 1, height: 1, origin: origin, pixel: pixel, color: ink)
        case .error:
            fillPixel(context: &context, x: 5, y: 3, width: 1, height: 1, origin: origin, pixel: pixel, color: ink)
            fillPixel(context: &context, x: 10, y: 3, width: 1, height: 1, origin: origin, pixel: pixel, color: ink)
            fillPixel(context: &context, x: 6, y: 7, width: 1, height: 1, origin: origin, pixel: pixel, color: ink)
            fillPixel(context: &context, x: 7, y: 6, width: 2, height: 1, origin: origin, pixel: pixel, color: ink)
            fillPixel(context: &context, x: 9, y: 7, width: 1, height: 1, origin: origin, pixel: pixel, color: ink)
        default:
            break
        }
    }

    private static func fillPixel(
        context: inout GraphicsContext,
        x: Int,
        y: Int,
        width: Int,
        height: Int,
        origin: CGPoint,
        pixel: CGFloat,
        color: Color
    ) {
        let rect = CGRect(
            x: origin.x + CGFloat(x) * pixel,
            y: origin.y + CGFloat(y) * pixel,
            width: CGFloat(width) * pixel,
            height: CGFloat(height) * pixel
        )
        context.fill(Path(rect), with: .color(color))
    }
}

struct MascotStatusPixels: View {
    let state: MascotState
    let reduceMotion: Bool

    @State private var phase = false

    private var color: Color { MascotDesign.Palette.status(for: state) }

    var body: some View {
        ZStack {
            switch state {
            case .offline:
                EmptyView()
            case .connecting:
                Rectangle()
                    .fill(color)
                    .frame(width: 4, height: 4)
                    .offset(x: phase ? 29 : 21, y: -22)
                    .opacity(phase ? 1 : 0.45)
            case .syncing:
                ZStack {
                    Rectangle().fill(color).frame(width: 4, height: 4).offset(y: -30)
                    Rectangle().fill(color).frame(width: 3, height: 3).offset(y: 30)
                }
                .rotationEffect(.degrees(phase ? 360 : 0))
            case .thinking:
                ZStack {
                    Rectangle().fill(color).frame(width: 3, height: 3).offset(y: -6)
                    Rectangle().fill(color).frame(width: 3, height: 3).offset(y: 6)
                    Rectangle().fill(color).frame(width: 3, height: 3).offset(x: -6)
                    Rectangle().fill(color).frame(width: 3, height: 3).offset(x: 6)
                }
                .offset(x: 25, y: -22)
                .scaleEffect(phase ? 1 : 0.62)
                .opacity(phase ? 1 : 0.48)
            case .waiting:
                ZStack {
                    Rectangle().fill(color).frame(width: 5, height: 5)
                    Rectangle().fill(color).frame(width: 2, height: 2).offset(x: 6, y: -6)
                }
                .offset(x: 25, y: -21)
            case .error:
                VStack(spacing: 2) {
                    Rectangle().fill(color).frame(width: 4, height: 8)
                    Rectangle().fill(color).frame(width: 4, height: 4)
                }
                .offset(x: 26, y: -20)
            }
        }
        .frame(width: MascotDesign.Metric.hitSize, height: MascotDesign.Metric.hitSize)
        .onAppear { startAnimation() }
    }

    private func startAnimation() {
        guard !reduceMotion else { return }
        DispatchQueue.main.async {
            switch state {
            case .syncing:
                withAnimation(MascotDesign.Motion.orbit) { phase = true }
            case .connecting, .thinking:
                withAnimation(MascotDesign.Motion.sparkle) { phase = true }
            default:
                break
            }
        }
    }
}
