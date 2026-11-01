import AppKit
import Foundation

let output = CommandLine.arguments.dropFirst().first ?? ".build/AppIcon-1024.png"
let size = 1024
let canvas = NSSize(width: size, height: size)
let image = NSImage(size: canvas)

let rows = [
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
].map(Array.init)

func isFilled(_ x: Int, _ y: Int) -> Bool {
    guard y >= 0, y < rows.count, x >= 0, x < 16 else { return false }
    return rows[y][x] == "#"
}

image.lockFocus()
defer { image.unlockFocus() }

NSColor.clear.setFill()
NSRect(origin: .zero, size: canvas).fill()

let backgroundPath = NSBezierPath(
    roundedRect: NSRect(x: 68, y: 68, width: 888, height: 888),
    xRadius: 220,
    yRadius: 220
)
let gradient = NSGradient(
    starting: NSColor(calibratedRed: 0.106, green: 0.153, blue: 0.271, alpha: 1),
    ending: NSColor(calibratedRed: 0.169, green: 0.263, blue: 0.404, alpha: 1)
)!
gradient.draw(in: backgroundPath, angle: -90)

let pixel = 44
let originX = (size - 16 * pixel) / 2
let originY = 306

let cloudFill = NSColor(calibratedRed: 0.878, green: 0.957, blue: 1.0, alpha: 1)
let cloudEdge = NSColor(calibratedRed: 0.545, green: 0.788, blue: 0.922, alpha: 1)
let ink = NSColor(calibratedRed: 0.086, green: 0.153, blue: 0.239, alpha: 1)

func fillPixel(x: Int, y: Int, width: Int = 1, height: Int = 1, color: NSColor) {
    color.setFill()
    NSRect(
        x: originX + x * pixel,
        y: originY + (9 - y) * pixel - (height - 1) * pixel,
        width: width * pixel,
        height: height * pixel
    ).fill()
}

for y in 0..<rows.count {
    for x in 0..<16 where isFilled(x, y) {
        let edge = !isFilled(x - 1, y)
            || !isFilled(x + 1, y)
            || !isFilled(x, y - 1)
            || !isFilled(x, y + 1)
        fillPixel(x: x, y: y, color: edge ? cloudEdge : cloudFill)
    }
}

fillPixel(x: 5, y: 4, height: 2, color: ink)
fillPixel(x: 10, y: 4, height: 2, color: ink)
fillPixel(x: 6, y: 6, color: ink)
fillPixel(x: 7, y: 7, width: 2, color: ink)
fillPixel(x: 9, y: 6, color: ink)

let cyan = NSColor(calibratedRed: 0.361, green: 0.882, blue: 0.902, alpha: 1)
cyan.setFill()
NSRect(x: 788, y: 740, width: 24, height: 68).fill()
NSRect(x: 766, y: 762, width: 68, height: 24).fill()

NSColor(calibratedRed: 0.451, green: 0.922, blue: 0.745, alpha: 1).setFill()
NSRect(x: 820, y: 660, width: 24, height: 24).fill()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Unable to encode app icon\n", stderr)
    exit(1)
}

let url = URL(fileURLWithPath: output)
try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
try png.write(to: url, options: .atomic)
print(url.path)
