// make_appicon.swift — renders Ember's 1024×1024 app icon.
// Rouge (#fb3b5a) field with a dark (#1a1410) ring glyph, matching
// the in-app EmberLogo. Opaque, full-bleed (iOS applies the mask).
//
// Usage: swift scripts/make_appicon.swift <output.png>

import Foundation
import CoreGraphics
import ImageIO

let outPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "Ember/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

let size = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()

guard let ctx = CGContext(
    data: nil, width: size, height: size,
    bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else { fatalError("could not create context") }

func rgb(_ r: Double, _ g: Double, _ b: Double) -> CGColor {
    CGColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: 1)
}
let rouge = rgb(251, 59, 90)   // #fb3b5a
let dark  = rgb(26, 20, 16)    // #1a1410

// Field
ctx.setFillColor(rouge)
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

// Ring glyph (matches EmberLogo: diameter ~0.42, stroke ~0.085)
let d = Double(size) * 0.42
let lineWidth = Double(size) * 0.085
let ringRect = CGRect(x: (Double(size) - d) / 2, y: (Double(size) - d) / 2, width: d, height: d)
ctx.setStrokeColor(dark)
ctx.setLineWidth(lineWidth)
ctx.strokeEllipse(in: ringRect)

guard let image = ctx.makeImage() else { fatalError("could not render image") }

let url = URL(fileURLWithPath: outPath)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
    fatalError("could not create destination")
}
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("could not write PNG") }
print("Wrote \(outPath) (\(size)×\(size))")
