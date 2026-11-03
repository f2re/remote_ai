import Foundation
import ImageIO
import SwiftUI

enum MascotAsset: String, CaseIterable, Identifiable, Equatable {
    case offline
    case connecting
    case syncing
    case thinking
    case waiting
    case error

    var id: String { rawValue }
    var fileName: String { "mascot-\(rawValue)" }

    init(state: MascotState) {
        switch state {
        case .offline: self = .offline
        case .connecting: self = .connecting
        case .syncing: self = .syncing
        case .thinking: self = .thinking
        case .waiting: self = .waiting
        case .error: self = .error
        }
    }

    var resourceURL: URL? {
        if let resourceRoot = Bundle.main.resourceURL {
            let packaged = resourceRoot
                .appendingPathComponent("RemoteAI_RemoteAI.bundle", isDirectory: true)
                .appendingPathComponent("Mascot", isDirectory: true)
                .appendingPathComponent("\(fileName).png")
            if FileManager.default.fileExists(atPath: packaged.path) {
                return packaged
            }
        }

        return Bundle.module.url(
            forResource: fileName,
            withExtension: "png",
            subdirectory: "Mascot"
        )
    }

    var cgImage: CGImage? {
        guard let resourceURL,
              let source = CGImageSourceCreateWithURL(resourceURL as CFURL, nil) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}

@MainActor
struct PixelCloudMascot: View {
    let state: MascotState
    var animated = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase = false

    private var asset: MascotAsset { MascotAsset(state: state) }

    var body: some View {
        Group {
            if let image = asset.cgImage {
                Image(decorative: image, scale: 1, orientation: .up)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            } else {
                Image(systemName: "icloud.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(12)
                    .foregroundStyle(.secondary)
            }
        }
        .scaleEffect(motionScale)
        .offset(y: motionOffset)
        .animation(motionAnimation, value: phase)
        .onAppear { updateMotion() }
        .onChange(of: reduceMotion) { _ in updateMotion() }
        .onChange(of: asset) { _ in
            phase = false
            updateMotion()
        }
        .accessibilityHidden(true)
    }

    private var motionScale: CGFloat {
        guard animated, !reduceMotion, phase else { return 1 }
        switch asset {
        case .offline: return 1
        case .connecting: return 1.018
        case .syncing: return 1.012
        case .thinking: return 1.02
        case .waiting: return 1.012
        case .error: return 1.01
        }
    }

    private var motionOffset: CGFloat {
        guard animated, !reduceMotion, phase else { return 0 }
        switch asset {
        case .offline: return 0
        case .connecting, .thinking: return -1.5
        case .syncing, .waiting: return -1
        case .error: return 0
        }
    }

    private var motionAnimation: Animation? {
        guard animated, !reduceMotion else { return nil }
        switch asset {
        case .offline: return nil
        case .connecting, .thinking: return MascotDesign.Motion.livelyIdle
        case .syncing, .waiting: return MascotDesign.Motion.idle
        case .error: return MascotDesign.Motion.errorPulse
        }
    }

    private func updateMotion() {
        phase = false
        guard animated, !reduceMotion, asset != .offline else { return }
        DispatchQueue.main.async { phase = true }
    }
}
