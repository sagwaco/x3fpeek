import ImageIO
import QuickLookUI
import UniformTypeIdentifiers

final class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let jpeg = try x3fPreviewJPEG(at: request.fileURL)
        guard let source = CGImageSourceCreateWithData(jpeg as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            throw CocoaError(.fileReadCorruptFile)
        }
        // EXIF orientations 5 to 8 rotate the image by 90 degrees.
        let rotated = (properties[kCGImagePropertyOrientation] as? Int ?? 1) >= 5
        let size = rotated ? CGSize(width: height, height: width) : CGSize(width: width, height: height)
        return QLPreviewReply(dataOfContentType: .jpeg, contentSize: size) { _ in jpeg }
    }
}
