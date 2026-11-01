import SwiftUI

enum MascotDesign {
    enum Metric {
        static let panelWidth: CGFloat = 88
        static let panelHeight: CGFloat = 80
        static let hitSize: CGFloat = 76
        static let artWidth: CGFloat = 64
        static let artHeight: CGFloat = 44
        static let hoverScale: CGFloat = 1.035
        static let pressedScale: CGFloat = 0.965
        static let haloSize: CGFloat = 70
        static let haloOpacity: Double = 0.42
    }

    enum Motion {
        static let hover = Animation.easeOut(duration: 0.12)
        static let press = Animation.easeOut(duration: 0.08)
        static let state = Animation.easeInOut(duration: 0.18)
        static let orbit = Animation.linear(duration: 1.35).repeatForever(autoreverses: false)
        static let sparkle = Animation.easeInOut(duration: 0.85).repeatForever(autoreverses: true)
    }

    enum Palette {
        static func cloudFill(for scheme: ColorScheme) -> Color {
            scheme == .dark
                ? Color(red: 0.72, green: 0.79, blue: 0.88)
                : Color(red: 0.91, green: 0.95, blue: 0.99)
        }

        static func cloudShade(for scheme: ColorScheme) -> Color {
            scheme == .dark
                ? Color(red: 0.42, green: 0.49, blue: 0.60)
                : Color(red: 0.59, green: 0.69, blue: 0.80)
        }

        static func faceInk(for scheme: ColorScheme) -> Color {
            scheme == .dark
                ? Color(red: 0.10, green: 0.13, blue: 0.18)
                : Color(red: 0.13, green: 0.17, blue: 0.23)
        }

        static func status(for state: MascotState) -> Color {
            switch state {
            case .offline: .secondary
            case .connecting: .blue
            case .syncing: .cyan
            case .thinking: .indigo
            case .waiting: .green
            case .error: .orange
            }
        }
    }
}

struct MascotButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? MascotDesign.Metric.pressedScale : 1)
            .animation(MascotDesign.Motion.press, value: configuration.isPressed)
    }
}
