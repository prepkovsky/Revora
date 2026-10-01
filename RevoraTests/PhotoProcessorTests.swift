import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import Revora

struct PhotoProcessorTests {
    /// A JPEG of the given size. Random pixels compress badly, which forces a lower quality or size.
    private func jpeg(width: Int, height: Int, noise: Bool = false, properties: [CFString: Any] = [:]) throws -> Data {
        let context = try #require(CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ))
        if noise, let pixels = context.data {
            arc4random_buf(pixels, context.bytesPerRow * height)
        } else {
            context.setFillColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        let image = try #require(context.makeImage())

        let output = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil))
        var options = properties
        options[kCGImageDestinationLossyCompressionQuality] = 1.0
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        return output as Data
    }

    private func properties(of data: Data) throws -> [CFString: Any] {
        let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
        return try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
    }

    private func pixelSize(of data: Data) throws -> (width: Int, height: Int) {
        let properties = try properties(of: data)
        return (
            try #require(properties[kCGImagePropertyPixelWidth] as? Int),
            try #require(properties[kCGImagePropertyPixelHeight] as? Int)
        )
    }

    @Test func shrinksLargePhotosKeepingAspectRatio() throws {
        let photo = try PhotoProcessor.prepare(jpeg(width: 3000, height: 2000))

        let full = try pixelSize(of: photo.full)
        #expect(full.width == PhotoProcessor.fullMaxPixelSize)
        #expect(abs(Double(full.width) / Double(full.height) - 1.5) < 0.01)

        let thumbnail = try pixelSize(of: photo.thumbnail)
        #expect(thumbnail.width == PhotoProcessor.thumbnailMaxPixelSize)
        #expect(abs(Double(thumbnail.width) / Double(thumbnail.height) - 1.5) < 0.01)
    }

    @Test func neverUpscales() throws {
        let photo = try PhotoProcessor.prepare(jpeg(width: 300, height: 200))
        #expect(try pixelSize(of: photo.full) == (300, 200))
        #expect(try pixelSize(of: photo.thumbnail) == (300, 200))
    }

    @Test func appliesOrientation() throws {
        // Orientation 6: stored landscape, shown rotated to portrait, as iPhone photos often are.
        let photo = try PhotoProcessor.prepare(jpeg(width: 400, height: 200, properties: [kCGImagePropertyOrientation: 6]))
        #expect(try pixelSize(of: photo.full) == (200, 400))
        #expect(try (properties(of: photo.full)[kCGImagePropertyOrientation] as? Int ?? 1) == 1)
    }

    @Test func fitsSizeLimits() throws {
        let photo = try PhotoProcessor.prepare(jpeg(width: 2000, height: 1500, noise: true))
        #expect(photo.full.count <= PhotoProcessor.fullMaxBytes)
        #expect(photo.thumbnail.count <= PhotoProcessor.thumbnailMaxBytes)
    }

    @Test func dropsLocation() throws {
        let gps: [CFString: Any] = [
            kCGImagePropertyGPSLatitude: 48.15,
            kCGImagePropertyGPSLatitudeRef: "N",
            kCGImagePropertyGPSLongitude: 17.11,
            kCGImagePropertyGPSLongitudeRef: "E",
        ]
        let original = try jpeg(width: 600, height: 400, properties: [kCGImagePropertyGPSDictionary: gps])
        #expect(try properties(of: original)[kCGImagePropertyGPSDictionary] != nil)

        let photo = try PhotoProcessor.prepare(original)
        #expect(try properties(of: photo.full)[kCGImagePropertyGPSDictionary] == nil)
        #expect(try properties(of: photo.thumbnail)[kCGImagePropertyGPSDictionary] == nil)
    }

    @Test func rejectsDataThatIsntAnImage() {
        #expect(throws: PhotoError.unreadableImage) {
            try PhotoProcessor.prepare(Data("not a photo".utf8))
        }
    }
}
