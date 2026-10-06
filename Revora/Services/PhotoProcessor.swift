import Foundation
import ImageIO
import UniformTypeIdentifiers

/// A cover photo shrunk to fit Firestore, as JPEGs ready to save.
nonisolated struct PreparedPhoto: Sendable {
    let full: Data
    let thumbnail: Data
}

/// Turns a picked photo into small JPEGs. ImageIO reads only what it needs, so even a
/// 48 MP photo never has to be fully decoded, and it applies the EXIF orientation.
/// The output carries no metadata, so a photo's location never leaves the device.
nonisolated enum PhotoProcessor {
    static let fullMaxPixelSize = 1280
    static let thumbnailMaxPixelSize = 400

    // A margin under the 500 KiB and 100 KiB that the security rules allow.
    static let fullMaxBytes = 450 * 1024
    static let thumbnailMaxBytes = 90 * 1024

    /// Larger than a cover photo, so a cookbook's small print stays readable.
    static let scanMaxPixelSize = 2048
    /// A margin under the 2 MiB that the `scanRecipe` function accepts.
    static let scanMaxBytes = 1536 * 1024

    private static let qualities = [0.8, 0.7, 0.6, 0.5]

    static func prepare(_ data: Data) throws(PhotoError) -> PreparedPhoto {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 0
        else { throw .unreadableImage }

        return PreparedPhoto(
            full: try jpeg(from: source, maxPixelSize: fullMaxPixelSize, maxBytes: fullMaxBytes),
            thumbnail: try jpeg(from: source, maxPixelSize: thumbnailMaxPixelSize, maxBytes: thumbnailMaxBytes)
        )
    }

    /// One JPEG for the `scanRecipe` function to read. It's sent, never saved.
    static func prepareForScan(_ data: Data) throws(PhotoError) -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 0
        else { throw .unreadableImage }

        return try jpeg(from: source, maxPixelSize: scanMaxPixelSize, maxBytes: scanMaxBytes)
    }

    /// Lowers the quality first, then the size, until the JPEG fits.
    private static func jpeg(from source: CGImageSource, maxPixelSize: Int, maxBytes: Int) throws(PhotoError) -> Data {
        // Never upscale a photo that's already small.
        var pixelSize = min(maxPixelSize, longestSide(of: source) ?? maxPixelSize)
        while pixelSize > 0 {
            guard let image = image(from: source, maxPixelSize: pixelSize) else { throw .unreadableImage }
            for quality in qualities {
                if let data = encode(image, quality: quality), data.count <= maxBytes {
                    return data
                }
            }
            pixelSize = pixelSize * 4 / 5
        }
        throw .unreadableImage
    }

    private static func longestSide(of source: CGImageSource) -> Int? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int
        else { return nil }
        return max(width, height)
    }

    private static func image(from source: CGImageSource, maxPixelSize: Int) -> CGImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    private static func encode(_ image: CGImage, quality: Double) -> Data? {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil)
        else { return nil }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }
}
