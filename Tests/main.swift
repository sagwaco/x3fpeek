import Foundation
import ImageIO

// Self-check for x3fPreviewJPEG. Pass real X3F files to print their previews.
// swiftc Shared/X3F.swift Tests/main.swift -o "$TMPDIR/x3fcheck" && "$TMPDIR/x3fcheck" [file.x3f ...]

func le(_ values: UInt32...) -> Data {
    values.reduce(into: Data()) { data, value in withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }
}
func section(type: UInt32, format: UInt32, payload: Data) -> Data {
    Data("SECi".utf8) + le(0x20000, type, format, 1, 1, 0) + payload
}
func x3f(_ sections: [Data], count: UInt32? = nil, extra: Data = Data()) -> Data {
    var file = Data("FOVb".utf8) + Data(count: 20)
    var entries = Data()
    for section in sections {
        entries += le(UInt32(file.count), UInt32(section.count)) + Data("IMA2".utf8)
        file += section
    }
    entries += extra
    let directory = file.count
    file += Data("SECd".utf8) + le(0x20000, count ?? UInt32(sections.count)) + entries + le(UInt32(directory))
    return file
}
func preview(_ file: Data) -> Data? {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("x3fcheck-\(UUID()).x3f")
    try! file.write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }
    return try? x3fPreviewJPEG(at: url)
}

let small = Data([0xFF, 0xD8, 1, 0xFF, 0xD9]), large = Data([0xFF, 0xD8, 1, 2, 3, 0xFF, 0xD9])
let sections = [
    section(type: 2, format: 18, payload: small),
    section(type: 1, format: 30, payload: Data(count: 99)),
    section(type: 2, format: 18, payload: large),
]
precondition(preview(x3f(sections)) == large, "picks the largest JPEG, skips raw data")
precondition(preview(x3f([sections[1]])) == nil, "no JPEG")
precondition(preview(x3f(sections, count: .max)) == nil, "bad entry count")
let pastEnd = le(24, 1 << 30) + Data("IMA2".utf8), badOffset = le(.max, 100) + Data("IMA2".utf8)
precondition(preview(x3f(sections, count: 5, extra: pastEnd + badOffset)) == large, "skips bad entries")
precondition(preview(x3f(sections).dropLast(5)) == nil, "truncated file")
precondition(preview(Data("FOVb".utf8)) == nil, "tiny file")
print("x3f self-check passed")

for path in CommandLine.arguments.dropFirst() {
    do {
        let jpeg = try x3fPreviewJPEG(at: URL(fileURLWithPath: path))
        let source = CGImageSourceCreateWithData(jpeg as CFData, nil)!
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as! [CFString: Any]
        print(path, jpeg.count, props[kCGImagePropertyPixelWidth]!, props[kCGImagePropertyPixelHeight]!,
              "orientation", props[kCGImagePropertyOrientation] ?? 1)
    } catch {
        print(path, "error:", error)
    }
}
