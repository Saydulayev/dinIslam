//
//  AvatarImageProcessorTests.swift
//  dinIslamTests
//
//  Фото профиля хранится уменьшенным до 512 px, в JPEG без метаданных (EXIF, геотеги);
//  по отпечатку содержимого синхронизация понимает, изменилось ли фото.
//

import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import dinIslam

final class AvatarImageProcessorTests: XCTestCase {

    func testPrepareDownscalesLongSideTo512() throws {
        let original = try makeImageData(width: 2000, height: 1000, type: .jpeg)

        let prepared = try XCTUnwrap(AvatarImageProcessor.prepare(original))
        let properties = try imageProperties(of: prepared)

        XCTAssertEqual(properties[kCGImagePropertyPixelWidth] as? Int, 512)
        XCTAssertEqual(properties[kCGImagePropertyPixelHeight] as? Int, 256)
        XCTAssertLessThan(prepared.count, original.count)
    }

    func testPrepareStripsExifAndLocation() throws {
        let original = try makeImageData(width: 800, height: 800, type: .jpeg, withMetadata: true)
        let originalProperties = try imageProperties(of: original)
        XCTAssertNotNil(originalProperties[kCGImagePropertyGPSDictionary], "Исходное фото должно содержать геотег")

        let prepared = try XCTUnwrap(AvatarImageProcessor.prepare(original))
        let properties = try imageProperties(of: prepared)

        XCTAssertNil(properties[kCGImagePropertyGPSDictionary])
        let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
        XCTAssertNil(exif?[kCGImagePropertyExifDateTimeOriginal])
        let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
        XCTAssertNil(tiff?[kCGImagePropertyTIFFModel])
    }

    func testPrepareOutputsJPEG() throws {
        let original = try makeImageData(width: 300, height: 300, type: .png)

        let prepared = try XCTUnwrap(AvatarImageProcessor.prepare(original))
        let source = try XCTUnwrap(CGImageSourceCreateWithData(prepared as CFData, nil))

        XCTAssertEqual(CGImageSourceGetType(source) as String?, UTType.jpeg.identifier)
    }

    func testPrepareRejectsNonImageData() {
        XCTAssertNil(AvatarImageProcessor.prepare(Data("not an image".utf8)))
    }

    func testFingerprintDependsOnlyOnContent() {
        let first = AvatarImageProcessor.fingerprint(of: Data([1, 2, 3]))

        XCTAssertEqual(first, AvatarImageProcessor.fingerprint(of: Data([1, 2, 3])))
        XCTAssertNotEqual(first, AvatarImageProcessor.fingerprint(of: Data([1, 2, 4])))
        XCTAssertFalse(first.isEmpty, "Пустая строка в записи означает «фото нет»")
    }

    // MARK: - Helpers

    private func makeImageData(width: Int, height: Int, type: UTType, withMetadata: Bool = false) throws -> Data {
        let context = try XCTUnwrap(CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ))
        context.setFillColor(red: 0.2, green: 0.6, blue: 0.4, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = try XCTUnwrap(context.makeImage())

        var properties: [CFString: Any] = [:]
        if withMetadata {
            properties[kCGImagePropertyGPSDictionary] = [
                kCGImagePropertyGPSLatitude: 43.3,
                kCGImagePropertyGPSLatitudeRef: "N",
                kCGImagePropertyGPSLongitude: 45.7,
                kCGImagePropertyGPSLongitudeRef: "E"
            ]
            properties[kCGImagePropertyExifDictionary] = [kCGImagePropertyExifDateTimeOriginal: "2026:10:14 12:00:00"]
            properties[kCGImagePropertyTIFFDictionary] = [kCGImagePropertyTIFFModel: "iPhone"]
        }

        let output = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(output, type.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return output as Data
    }

    private func imageProperties(of data: Data) throws -> [CFString: Any] {
        let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
        return try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
    }
}
