#!/usr/bin/env swift

import AppKit
import Foundation

struct AppIconSlot {
    let filename: String
    let pixels: Int
    let size: String
    let scale: String
}

let slots: [AppIconSlot] = [
    .init(filename: "appicon-16.png", pixels: 16, size: "16x16", scale: "1x"),
    .init(filename: "appicon-16@2x.png", pixels: 32, size: "16x16", scale: "2x"),
    .init(filename: "appicon-32.png", pixels: 32, size: "32x32", scale: "1x"),
    .init(filename: "appicon-32@2x.png", pixels: 64, size: "32x32", scale: "2x"),
    .init(filename: "appicon-128.png", pixels: 128, size: "128x128", scale: "1x"),
    .init(filename: "appicon-128@2x.png", pixels: 256, size: "128x128", scale: "2x"),
    .init(filename: "appicon-256.png", pixels: 256, size: "256x256", scale: "1x"),
    .init(filename: "appicon-256@2x.png", pixels: 512, size: "256x256", scale: "2x"),
    .init(filename: "appicon-512.png", pixels: 512, size: "512x512", scale: "1x"),
    .init(filename: "appicon-512@2x.png", pixels: 1024, size: "512x512", scale: "2x"),
]

let iconsetPath = CommandLine.arguments.dropFirst().first
    ?? "FrogTray/FrogTray/Assets.xcassets/AppIcon.appiconset"
let iconsetURL = URL(fileURLWithPath: iconsetPath, isDirectory: true)

try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

func color(_ hex: Int, alpha: CGFloat = 1) -> NSColor {
    let red = CGFloat((hex >> 16) & 0xff) / 255
    let green = CGFloat((hex >> 8) & 0xff) / 255
    let blue = CGFloat(hex & 0xff) / 255
    return NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
}

func circle(_ centerX: CGFloat, _ centerY: CGFloat, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(
        ovalIn: NSRect(
            x: centerX - radius,
            y: centerY - radius,
            width: radius * 2,
            height: radius * 2
        )
    )
}

func drawWithShadow(
    context: NSGraphicsContext,
    color: NSColor,
    blur: CGFloat,
    offsetX: CGFloat = 0,
    offsetY: CGFloat = 0,
    draw: () -> Void
) {
    context.saveGraphicsState()
    context.cgContext.setShadow(
        offset: CGSize(width: offsetX, height: offsetY),
        blur: blur,
        color: color.cgColor
    )
    draw()
    context.restoreGraphicsState()
}

func renderIcon(size: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    rep.size = NSSize(width: size, height: size)

    let scale = CGFloat(size) / 1024

    func r(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> NSRect {
        NSRect(x: x * scale, y: y * scale, width: width * scale, height: height * scale)
    }

    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    color(0x000000, alpha: 0).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size))).fill()

    let backgroundPath = NSBezierPath(
        roundedRect: r(66, 66, 892, 892),
        xRadius: 220 * scale,
        yRadius: 220 * scale
    )

    drawWithShadow(
        context: context,
        color: color(0x04111d, alpha: 0.28),
        blur: 46 * scale,
        offsetY: -14 * scale
    ) {
        backgroundPath.addClip()
        NSGradient(
            colors: [
                color(0x10263f),
                color(0x125666),
                color(0x2bc475),
            ]
        )!.draw(in: backgroundPath, angle: -55)
    }

    context.saveGraphicsState()
    backgroundPath.addClip()
    color(0xffffff, alpha: 0.11).setFill()
    NSBezierPath(ovalIn: r(140, 694, 430, 190)).fill()
    color(0x07213a, alpha: 0.10).setFill()
    NSBezierPath(ovalIn: r(420, 72, 650, 470)).fill()
    context.restoreGraphicsState()

    let trayPath = NSBezierPath(
        roundedRect: r(166, 198, 692, 268),
        xRadius: 114 * scale,
        yRadius: 114 * scale
    )
    drawWithShadow(
        context: context,
        color: color(0x05131f, alpha: 0.25),
        blur: 34 * scale,
        offsetY: -16 * scale
    ) {
        NSGradient(
            colors: [
                color(0x16324b, alpha: 0.96),
                color(0x0e2132, alpha: 0.96),
            ]
        )!.draw(in: trayPath, angle: -90)
    }
    color(0xffffff, alpha: 0.12).setStroke()
    trayPath.lineWidth = 5 * scale
    trayPath.stroke()

    let shelfPath = NSBezierPath(
        roundedRect: r(214, 404, 596, 24),
        xRadius: 12 * scale,
        yRadius: 12 * scale
    )
    color(0xffffff, alpha: 0.14).setFill()
    shelfPath.fill()

    let barSpecs: [(CGFloat, CGFloat, Int)] = [
        (248, 112, 0x8df26f),
        (454, 164, 0x59d3ff),
        (660, 132, 0xffc857),
    ]

    for (x, height, hex) in barSpecs {
        let barRect = r(x, 242, 116, height)
        let barPath = NSBezierPath(
            roundedRect: barRect,
            xRadius: 36 * scale,
            yRadius: 36 * scale
        )

        drawWithShadow(
            context: context,
            color: color(hex, alpha: 0.30),
            blur: 24 * scale,
            offsetY: -4 * scale
        ) {
            NSGradient(
                colors: [
                    color(hex, alpha: 0.95),
                    color(hex, alpha: 0.72),
                ]
            )!.draw(in: barPath, angle: -90)
        }

        color(0xffffff, alpha: 0.18).setStroke()
        barPath.lineWidth = 4 * scale
        barPath.stroke()
    }

    let leftEyeBump = circle(382 * scale, 736 * scale, 88 * scale)
    let rightEyeBump = circle(642 * scale, 736 * scale, 88 * scale)
    let headPath = NSBezierPath(
        roundedRect: r(238, 324, 548, 424),
        xRadius: 200 * scale,
        yRadius: 200 * scale
    )

    let frogParts = [leftEyeBump, rightEyeBump, headPath]
    for part in frogParts {
        drawWithShadow(
            context: context,
            color: color(0x09151b, alpha: 0.20),
            blur: 20 * scale,
            offsetY: -10 * scale
        ) {
            NSGradient(
                colors: [
                    color(0xbef86b),
                    color(0x54cf68),
                    color(0x279b5d),
                ]
            )!.draw(in: part, angle: -90)
        }
    }

    context.saveGraphicsState()
    headPath.addClip()
    color(0xffffff, alpha: 0.16).setFill()
    NSBezierPath(ovalIn: r(290, 560, 360, 138)).fill()
    color(0x0f6e4d, alpha: 0.18).setFill()
    NSBezierPath(ovalIn: r(332, 332, 366, 172)).fill()
    context.restoreGraphicsState()

    for x in [382, 642] {
        let sclera = circle(CGFloat(x) * scale, 736 * scale, 46 * scale)
        color(0xf7fff1).setFill()
        sclera.fill()

        let pupil = circle(CGFloat(x) * scale, 730 * scale, 18 * scale)
        color(0x153126).setFill()
        pupil.fill()

        let catchlight = circle((CGFloat(x) - 10) * scale, 744 * scale, 7 * scale)
        color(0xffffff, alpha: 0.85).setFill()
        catchlight.fill()
    }

    let mouth = NSBezierPath()
    mouth.lineCapStyle = .round
    mouth.lineJoinStyle = .round
    mouth.lineWidth = 18 * scale
    mouth.move(to: CGPoint(x: 380 * scale, y: 492 * scale))
    mouth.curve(
        to: CGPoint(x: 644 * scale, y: 492 * scale),
        controlPoint1: CGPoint(x: 432 * scale, y: 420 * scale),
        controlPoint2: CGPoint(x: 592 * scale, y: 420 * scale)
    )
    color(0x163628, alpha: 0.65).setStroke()
    mouth.stroke()

    let leftCheek = circle(332 * scale, 510 * scale, 28 * scale)
    let rightCheek = circle(692 * scale, 510 * scale, 28 * scale)
    color(0xffffff, alpha: 0.08).setFill()
    leftCheek.fill()
    rightCheek.fill()

    let noseLeft = circle(470 * scale, 558 * scale, 7 * scale)
    let noseRight = circle(554 * scale, 558 * scale, 7 * scale)
    color(0x194930, alpha: 0.34).setFill()
    noseLeft.fill()
    noseRight.fill()

    NSGraphicsContext.restoreGraphicsState()

    return rep.representation(using: .png, properties: [:])!
}

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

let contents = [
    "images": slots.map { slot in
        [
            "filename": slot.filename,
            "idiom": "mac",
            "scale": slot.scale,
            "size": slot.size,
        ]
    },
    "info": [
        "author": "xcode",
        "version": 1,
    ],
] as [String: Any]

let jsonData = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try jsonData.write(to: iconsetURL.appendingPathComponent("Contents.json"))

for slot in slots {
    let data = renderIcon(size: slot.pixels)
    try data.write(to: iconsetURL.appendingPathComponent(slot.filename))
    print("generated \(slot.filename) (\(slot.pixels)x\(slot.pixels))")
}

print("updated \(iconsetURL.path)")
