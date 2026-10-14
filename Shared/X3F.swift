import Foundation

/// Returns the largest JPEG preview that is embedded in an X3F file.
///
/// An X3F file starts with "FOVb". Its last 4 bytes give the offset of the
/// "SECd" directory. Each 12-byte directory entry has an offset, a length, and
/// a tag. An image section starts with "SECi" and a 28-byte header. Type 2
/// with format 18 is a JPEG.
func x3fPreviewJPEG(at url: URL) throws -> Data {
    let handle = try FileHandle(forReadingFrom: url)
    defer { try? handle.close() }
    let size = Int(try handle.seekToEnd())
    let corrupt = CocoaError(.fileReadCorruptFile, userInfo: [NSURLErrorKey: url])

    func bytes(_ offset: Int, _ count: Int) throws -> Data {
        guard offset >= 0, count > 0, offset <= size - count else { throw corrupt }
        try handle.seek(toOffset: UInt64(offset))
        guard let data = try handle.read(upToCount: count), data.count == count else { throw corrupt }
        return data
    }
    func u32(_ data: Data, _ offset: Int) -> Int {
        data.withUnsafeBytes { Int(UInt32(littleEndian: $0.loadUnaligned(fromByteOffset: offset, as: UInt32.self))) }
    }

    guard try bytes(0, 4) == Data("FOVb".utf8) else { throw corrupt }
    let directory = u32(try bytes(size - 4, 4), 0)
    let header = try bytes(directory, 12)
    guard header.prefix(4) == Data("SECd".utf8) else { throw corrupt }
    // Real files have fewer than 10 entries. The limit makes a bad count fail fast.
    let count = u32(header, 8)
    guard count <= 1 << 16 else { throw corrupt }
    let entries = try bytes(directory + 12, count * 12)

    var best: (offset: Int, length: Int)?
    for entry in stride(from: 0, to: entries.count, by: 12) {
        let offset = u32(entries, entry), length = u32(entries, entry + 4)
        // Skip bad entries, so that one bad entry does not hide a good JPEG.
        // Real previews are about 10 MB. The 128 MB limit stops huge allocations.
        guard length > 28, length <= 1 << 27, length > best?.length ?? 0, offset <= size - length,
              let section = try? bytes(offset, 16), section.prefix(4) == Data("SECi".utf8),
              u32(section, 8) == 2, u32(section, 12) == 18 else { continue }
        best = (offset, length)
    }
    guard let best else { throw CocoaError(.fileReadUnknown, userInfo: [NSURLErrorKey: url]) }
    return try bytes(best.offset + 28, best.length - 28)
}
