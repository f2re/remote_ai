import SwiftUI

enum MascotDesign {
    enum Metric {
        static let panelWidth: CGFloat = 96
        static let panelHeight: CGFloat = 96
        static let hitSize: CGFloat = 86
        static let artWidth: CGFloat = 80
        static let artHeight: CGFloat = 80
        static let hoverScale: CGFloat = 1.028
        static let pressedScale: CGFloat = 0.97
        static let haloSize: CGFloat = 84
        static let haloOpacity: Double = 0.36
    }

    enum Motion {
        static let hover = Animation.easeOut(duration: 0.12)
        static let press = Animation.easeOut(duration: 0.08)
        static let state = Animation.easeInOut(duration: 0.18)
        static let idle = Animation.easeInOut(duration: 1.65).repeatForever(autoreverses: true)
        static let livelyIdle = Animation.easeInOut(duration: 1.05).repeatForever(autoreverses: true)
        static let errorPulse = Animation.easeInOut(duration: 0.72).repeatForever(autoreverses: true)
    }
}

struct MascotButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? MascotDesign.Metric.pressedScale : 1)
            .animation(MascotDesign.Motion.press, value: configuration.isPressed)
    }
}
