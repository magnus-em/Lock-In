#!/usr/bin/env swift
import Cocoa

func renderIcon(size: Int) -> NSImage {
    let dim = CGFloat(size)
    let image = NSImage(size: NSSize(width: dim, height: dim))
    image.lockFocus()

    // Rounded rect background
    let radius = dim * 0.22
    let bgPath = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: dim, height: dim),
                               xRadius: radius, yRadius: radius)
    NSColor(red: 0.96, green: 0.36, blue: 0.36, alpha: 1).setFill()
    bgPath.fill()

    // Build a white version of the lock symbol by:
    // 1. Filling a canvas white, then masking it with the symbol's alpha (destinationIn)
    let pt = dim * 0.45
    let cfg = NSImage.SymbolConfiguration(pointSize: pt, weight: .medium)
    if let symbol = NSImage(systemSymbolName: "lock.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(cfg) {

        let sw = symbol.size.width
        let sh = symbol.size.height

        // White-tinted symbol image
        let whiteSymbol = NSImage(size: symbol.size, flipped: false) { rect in
            NSColor.white.setFill()
            rect.fill()
            symbol.draw(in: rect, from: .zero,
                        operation: .destinationIn, fraction: 1.0,
                        respectFlipped: false, hints: nil)
            return true
        }

        // Center it in the icon
        let x = (dim - sw) / 2
        let y = (dim - sh) / 2
        whiteSymbol.draw(in: NSRect(x: x, y: y, width: sw, height: sh),
                         from: .zero, operation: .sourceOver, fraction: 1.0,
                         respectFlipped: false, hints: nil)
    }

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to path: String) {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else { return }
    try? png.write(to: URL(fileURLWithPath: path))
}

let iconsetPath = "/tmp/AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes = [16, 32, 64, 128, 256, 512, 1024]
for size in sizes {
    let img = renderIcon(size: size)
    savePNG(img, to: "\(iconsetPath)/icon_\(size)x\(size).png")
    if size <= 512 {
        let img2 = renderIcon(size: size * 2)
        savePNG(img2, to: "\(iconsetPath)/icon_\(size)x\(size)@2x.png")
    }
}
print("Done")
