import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let output = root.appendingPathComponent("Resources/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
var entries: [[String: String]] = []
for size in [16, 32, 128, 256, 512] {
  for scale in [1, 2] {
    let dimension = size * scale
    let bitmap = NSBitmapImageRep(
      bitmapDataPlanes: nil, pixelsWide: dimension, pixelsHigh: dimension, bitsPerSample: 8,
      samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
      bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let d = CGFloat(dimension)
    let bounds = NSRect(x: d * 0.04, y: d * 0.04, width: d * 0.92, height: d * 0.92)
    NSColor(calibratedRed: 0.15, green: 0.34, blue: 0.48, alpha: 1).setFill()
    NSBezierPath(roundedRect: bounds, xRadius: d * 0.2, yRadius: d * 0.2).fill()
    let text = "IW" as NSString
    let attributes: [NSAttributedString.Key: Any] = [
      .font: NSFont.systemFont(ofSize: d * 0.35, weight: .semibold),
      .foregroundColor: NSColor.white,
    ]
    let measured = text.size(withAttributes: attributes)
    text.draw(
      at: NSPoint(x: (d - measured.width) / 2, y: (d - measured.height) / 2),
      withAttributes: attributes)
    NSGraphicsContext.restoreGraphicsState()
    let filename = "icon-\(size)-\(scale).png"
    try bitmap.representation(using: .png, properties: [:])!.write(
      to: output.appendingPathComponent(filename))
    entries.append([
      "idiom": "mac", "size": "\(size)x\(size)", "scale": "\(scale)x", "filename": filename,
    ])
  }
}
let contents: [String: Any] = ["images": entries, "info": ["version": 1, "author": "xcode"]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys]).write(
  to: output.appendingPathComponent("Contents.json"))
