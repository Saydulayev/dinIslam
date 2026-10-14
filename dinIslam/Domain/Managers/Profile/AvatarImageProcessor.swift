//
//  AvatarImageProcessor.swift
//  dinIslam
//

import CryptoKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Готовит фото профиля к хранению: уменьшает до `maxPixelSize` по длинной стороне
/// и перекодирует в JPEG без метаданных (EXIF, геотеги, данные камеры).
enum AvatarImageProcessor {
    static let maxPixelSize = 512
    static let compressionQuality = 0.8
    static let fileExtension = "jpg"

    /// Возвращает JPEG или `nil`, если данные не удалось прочитать как изображение.
    static func prepare(_ data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

        // Миниатюра строится из исходника с учётом ориентации и без его метаданных
        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) else {
            return nil
        }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        let destinationOptions: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]
        CGImageDestinationAddImage(destination, image, destinationOptions as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }

    /// Отпечаток содержимого файла: по нему синхронизация понимает, изменилось ли фото.
    static func fingerprint(of data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func fingerprint(ofFileAt url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return fingerprint(of: data)
    }
}
