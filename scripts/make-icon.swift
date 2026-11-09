// Put an image on the macOS icon grid: an 824 pt rounded square on a 1024 pt
// canvas. Macs frame anything else in a grey plate.
// Usage: make-icon <glyph.svg> <out.png>          a white glyph on a dark plate
//        make-icon --full <icon.svg> <out.png>    an icon that brings its own plate
import AppKit

var arguments = Array(CommandLine.arguments.dropFirst())
let full = arguments.first == "--full"
if full { arguments.removeFirst() }
guard arguments.count == 2, let image = NSImage(contentsOfFile: arguments[0]) else {
    FileHandle.standardError.write(Data("make-icon: cannot read the image\n".utf8))
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
if full {
    image.draw(in: plate, from: .zero, operation: .sourceOver, fraction: 1)
} else {
    NSColor(srgbRed: 0.05, green: 0.05, blue: 0.06, alpha: 1).setFill()
    NSBezierPath(roundedRect: plate, xRadius: 185, yRadius: 185).fill()
    image.draw(in: plate.insetBy(dx: 160, dy: 160), from: .zero, operation: .sourceOver, fraction: 1)
}
context.flushGraphics()
NSGraphicsContext.current = nil

guard let png = bitmap.representation(using: .png, properties: [:]) else { exit(1) }
try png.write(to: URL(fileURLWithPath: arguments[1]))
