import AppKit
import Foundation

let arguments = Array(CommandLine.arguments.dropFirst())
let output = arguments.first ?? ".build/AppIcon-1024.png"
let mascotPath = arguments.dropFirst().first ?? "Sources/RemoteAI/Resources/Mascot/mascot-thinking.png"
let size = 1024

guard let mascot = NSImage(contentsOfFile: mascotPath) else {
    fputs("Не удалось загрузить канонический маскот для значка: \(mascotPath)\n", stderr)
    exit(1)
}

guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fputs("Не удалось создать bitmap-контекст значка\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.imageInterpolation = .none
context.cgContext.clear(CGRect(x: 0, y: 0, width: size, height: size))
let backgroundPath = NSBezierPath(roundedRect: NSRect(x: 68, y: 68, width: 888, height: 888), xRadius: 220, yRadius: 220)
let gradient = NSGradient(starting: NSColor(calibratedRed: 0.10, green: 0.14, blue: 0.28, alpha: 1), ending: NSColor(calibratedRed: 0.28, green: 0.30, blue: 0.61, alpha: 1))!
gradient.draw(in: backgroundPath, angle: -70)
let mascotRect = NSRect(x: 152, y: 142, width: 720, height: 720)
let shadow = NSShadow()
shadow.shadowBlurRadius = 24
shadow.shadowOffset = NSSize(width: 0, height: -12)
shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
shadow.set()
mascot.draw(in: mascotRect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: [.interpolation: NSNumber(value: NSImageInterpolation.none.rawValue)])
NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Не удалось закодировать значок приложения\n", stderr)
    exit(1)
}
let url = URL(fileURLWithPath: output)
try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
try png.write(to: url, options: .atomic)
print(url.path)
