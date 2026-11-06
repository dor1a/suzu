// Put a white vector glyph on the macOS icon grid: an 824 pt rounded square on a
// 1024 pt canvas. Macs frame anything else in a grey plate.
// Usage: make-icon <glyph.svg> <out.png>
import AppKit

let arguments = CommandLine.arguments
guard arguments.count == 3, let glyph = NSImage(contentsOfFile: arguments[1]) else {
    FileHandle.standardError.write(Data("make-icon: cannot read the glyph\n".utf8))
    exit(1)
}

let canvas = 1024
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: canvas, pixelsHigh: canvas, bitsPerSample: 8,
    samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: bitmap) else { exit(1) }

NSGraphicsContext.current = context
let plate = NSRect(x: 100, y: 100, width: 824, height: 824)
NSColor(srgbRed: 0.05, green: 0.05, blue: 0.06, alpha: 1).setFill()
NSBezierPath(roundedRect: plate, xRadius: 185, yRadius: 185).fill()
glyph.draw(in: plate.insetBy(dx: 160, dy: 160), from: .zero, operation: .sourceOver, fraction: 1)
context.flushGraphics()
NSGraphicsContext.current = nil

guard let png = bitmap.representation(using: .png, properties: [:]) else { exit(1) }
try png.write(to: URL(fileURLWithPath: arguments[2]))
