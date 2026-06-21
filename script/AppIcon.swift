// 程序化生成 RightNow 的 App 图标（1024×1024 PNG）。
// 用法: swift script/AppIcon.swift <输出路径.png>
// 设计：蓝色渐变圆角砖 + 白色表盘（10:10 经典指针）。

import AppKit
import CoreGraphics
import ImageIO
import Foundation

let size = 1024
let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"
let W = CGFloat(size)
let cs = CGColorSpaceCreateDeviceRGB()

guard let ctx = CGContext(
    data: nil, width: size, height: size,
    bitsPerComponent: 8, bytesPerRow: 0, space: cs,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("无法创建 CGContext") }

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [r, g, b, a])!
}

// ---- 圆角砖 + 渐变（遵循 macOS 图标网格：824×824 居中，四周留透明边）----
let inset: CGFloat = 100
let tile = CGRect(x: inset, y: inset, width: W - inset * 2, height: W - inset * 2)
let tilePath = CGPath(roundedRect: tile, cornerWidth: 180, cornerHeight: 180, transform: nil)

let topColor = color(0.36, 0.70, 1.00)   // 浅蓝
let botColor = color(0.00, 0.46, 0.96)   // 系统蓝

ctx.saveGState()
ctx.addPath(tilePath)
ctx.clip()
let grad = CGGradient(colorsSpace: cs, colors: [topColor, botColor] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: W), end: CGPoint(x: 0, y: 0), options: [])
ctx.restoreGState()

// ---- 表盘 ----
let cx = W / 2, cy = W / 2
let white = color(1, 1, 1)
ctx.setStrokeColor(white)
ctx.setLineCap(.round)

// 外圈
let ring: CGFloat = 250
ctx.setLineWidth(42)
ctx.addArc(center: CGPoint(x: cx, y: cy), radius: ring, startAngle: 0, endAngle: .pi * 2, clockwise: false)
ctx.strokePath()

// 12 个刻度（整点更粗）
let tickOuter = ring - 50
let tickInner = ring - 88
for i in 0..<12 {
    let ang = CGFloat(i) * (.pi / 6)
    let dx = sin(ang), dy = cos(ang)
    ctx.setLineWidth(i % 3 == 0 ? 26 : 14)
    ctx.move(to: CGPoint(x: cx + dx * tickOuter, y: cy + dy * tickOuter))
    ctx.addLine(to: CGPoint(x: cx + dx * tickInner, y: cy + dy * tickInner))
    ctx.strokePath()
}

// 指针（10:10）
func hand(angleDeg: CGFloat, length: CGFloat, width: CGFloat) {
    let a = angleDeg * .pi / 180
    ctx.setLineWidth(width)
    ctx.move(to: CGPoint(x: cx, y: cy))
    ctx.addLine(to: CGPoint(x: cx + sin(a) * length, y: cy + cos(a) * length))
    ctx.strokePath()
}
hand(angleDeg: 305, length: 138, width: 34)   // 时针
hand(angleDeg: 60, length: 198, width: 26)    // 分针

// 中心轴
ctx.setFillColor(white)
ctx.fillEllipse(in: CGRect(x: cx - 27, y: cy - 27, width: 54, height: 54))
ctx.setFillColor(botColor)
ctx.fillEllipse(in: CGRect(x: cx - 12, y: cy - 12, width: 24, height: 24))

// ---- 导出 PNG ----
guard let image = ctx.makeImage() else { fatalError("无法生成图像") }
let url = URL(fileURLWithPath: outPath)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
    fatalError("无法创建 PNG 目标")
}
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("写入 PNG 失败") }
print("已写出 \(outPath)")
