// 裁掉 PNG 的透明边、四周留少量内边距，输出用于菜单栏的模板图（保留 alpha）。
// 用法: swift script/TrimIcon.swift <in.png> <out.png> [paddingFraction=0.12]

import AppKit
import CoreGraphics
import ImageIO
import Foundation

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write("用法: TrimIcon.swift <in.png> <out.png> [paddingFraction]\n".data(using: .utf8)!)
    exit(2)
}
let inPath = args[1]
let outPath = args[2]
let paddingFraction = args.count > 3 ? (Double(args[3]) ?? 0.12) : 0.12

guard
    let dataProvider = CGDataProvider(filename: inPath),
    let cg = CGImage(pngDataProviderSource: dataProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
else { fatalError("无法读取 \(inPath)") }

let w = cg.width, h = cg.height
let bytesPerRow = w * 4
var pixels = [UInt8](repeating: 0, count: bytesPerRow * h)
guard let ctx = CGContext(
    data: &pixels, width: w, height: h, bitsPerComponent: 8, bytesPerRow: bytesPerRow,
    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("ctx") }
ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h)) // 原点左下：pixels[0] 是底行

// 找非透明包围盒（注意 pixels 行序是从底到顶）
var minX = w, maxX = -1, minYBottom = h, maxYBottom = -1
for row in 0..<h {
    for col in 0..<w {
        let alpha = pixels[row * bytesPerRow + col * 4 + 3]
        if alpha > 12 {
            if col < minX { minX = col }
            if col > maxX { maxX = col }
            if row < minYBottom { minYBottom = row }
            if row > maxYBottom { maxYBottom = row }
        }
    }
}
guard maxX >= minX, maxYBottom >= minYBottom else { fatalError("图像全透明") }

let bw = maxX - minX + 1
let bh = maxYBottom - minYBottom + 1
let pad = Int((Double(max(bw, bh)) * paddingFraction).rounded())
let outW = bw + pad * 2
let outH = bh + pad * 2

guard let out = CGContext(
    data: nil, width: outW, height: outH, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("out ctx") }
// 把原图整体平移，使包围盒左下角落在 (pad, pad)
out.draw(cg, in: CGRect(x: pad - minX, y: pad - minYBottom, width: w, height: h))

guard let result = out.makeImage() else { fatalError("makeImage") }
let url = URL(fileURLWithPath: outPath)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else { fatalError("dest") }
CGImageDestinationAddImage(dest, result, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("写入失败") }
print("裁剪完成 \(w)x\(h) -> \(outW)x\(outH)（包围盒 \(bw)x\(bh)，pad \(pad)）-> \(outPath)")
