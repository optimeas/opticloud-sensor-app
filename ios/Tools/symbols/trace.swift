import CoreGraphics
import Foundation
import ImageIO

// Traces the shapes of an icon with a transparent background into closed contours (marching squares), simplifies
// them, and prints them as JSON: a list of loops of [x, y] points, y downwards, in pixels of the source.
let img = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL, nil)!, 0, nil)!
let w = img.width, h = img.height
var px = [UInt8](repeating: 0, count: w * h * 4)
let ctx = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
// CGContext memory is top row first.
func a(_ x: Int, _ y: Int) -> Double { x < 0 || y < 0 || x >= w || y >= h ? 0 : Double(px[(y * w + x) * 4 + 3]) / 255 }
let t = 0.5
struct P: Hashable { var x: Double; var y: Double }
// Marching squares on cell corners (pixel centers), with linear interpolation.
var segs: [(P, P)] = []
func lerp(_ p1: P, _ v1: Double, _ p2: P, _ v2: Double) -> P {
    let f = (t - v1) / (v2 - v1); return P(x: p1.x + f * (p2.x - p1.x), y: p1.y + f * (p2.y - p1.y))
}
for y in -1..<h { for x in -1..<w {
    let v0 = a(x, y), v1 = a(x + 1, y), v2 = a(x + 1, y + 1), v3 = a(x, y + 1)
    let c0 = P(x: Double(x), y: Double(y)), c1 = P(x: Double(x + 1), y: Double(y)), c2 = P(x: Double(x + 1), y: Double(y + 1)), c3 = P(x: Double(x), y: Double(y + 1))
    let idx = (v0 > t ? 8 : 0) | (v1 > t ? 4 : 0) | (v2 > t ? 2 : 0) | (v3 > t ? 1 : 0)
    if idx == 0 || idx == 15 { continue }
    let top = lerp(c0, v0, c1, v1), right = lerp(c1, v1, c2, v2), bottom = lerp(c3, v3, c2, v2), left = lerp(c0, v0, c3, v3)
    switch idx {
    case 1, 14: segs.append((left, bottom))
    case 2, 13: segs.append((bottom, right))
    case 3, 12: segs.append((left, right))
    case 4, 11: segs.append((top, right))
    case 6, 9: segs.append((top, bottom))
    case 7, 8: segs.append((left, top))
    case 5: segs.append((left, top)); segs.append((bottom, right))
    case 10: segs.append((top, right)); segs.append((left, bottom))
    default: break
    }
}}
// Link segments into loops.
func key(_ p: P) -> String { String(format: "%.3f,%.3f", p.x, p.y) }
var adj: [String: [Int]] = [:]
for (i, s) in segs.enumerated() { adj[key(s.0), default: []].append(i); adj[key(s.1), default: []].append(i) }
var used = [Bool](repeating: false, count: segs.count)
var loops: [[P]] = []
for i in segs.indices where !used[i] {
    used[i] = true
    var loop = [segs[i].0, segs[i].1]
    var end = segs[i].1
    while true {
        guard let j = adj[key(end)]?.first(where: { !used[$0] }) else { break }
        used[j] = true
        end = key(segs[j].0) == key(end) ? segs[j].1 : segs[j].0
        if key(end) == key(loop[0]) { break }
        loop.append(end)
    }
    if loop.count > 20 { loops.append(loop) }
}
// Douglas-Peucker.
func dp(_ pts: [P], _ eps: Double) -> [P] {
    guard pts.count > 2 else { return pts }
    let a = pts.first!, b = pts.last!
    var maxD = 0.0, idx = 0
    for i in 1..<(pts.count - 1) {
        let p = pts[i]
        let num = abs((b.y - a.y) * p.x - (b.x - a.x) * p.y + b.x * a.y - b.y * a.x)
        let den = max(1e-9, hypot(b.x - a.x, b.y - a.y))
        let d = num / den
        if d > maxD { maxD = d; idx = i }
    }
    if maxD > eps { return Array(dp(Array(pts[0...idx]), eps).dropLast()) + dp(Array(pts[idx...]), eps) }
    return [a, b]
}
let out = loops.map { loop -> [[Double]] in
    let half = loop.count / 2
    let s = dp(Array(loop[0...half]), 0.3).dropLast() + dp(Array(loop[half...]) + [loop[0]], 0.3).dropLast()
    return s.map { [($0.x * 10).rounded() / 10, ($0.y * 10).rounded() / 10] }
}
let data = try! JSONSerialization.data(withJSONObject: out)
FileManager.default.createFile(atPath: CommandLine.arguments[2], contents: data)
for l in out { let xs = l.map { $0[0] }, ys = l.map { $0[1] }; print(l.count, xs.min()!, xs.max()!, ys.min()!, ys.max()!) }
