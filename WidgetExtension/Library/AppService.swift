//
//  AppService.swift
//  WidgetExtension
//
//  Created by Nikita Verkhovin on 18.04.2025.
//

import SDWebImage
import SDWebImageSVGNativeCoder

class AppService {
    static let shared = AppService()
        
    init() {
        SDImageCodersManager.shared.addCoder(SDImageSVGNativeCoder.shared)
    }
    
    func downloadImage(url: String) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let thumbnailSize = CGSize(width: 128, height: 128)
            SDWebImageManager.shared.loadImage(
                with: URL(string: url),
                options: [.retryFailed],
                context: [.imageThumbnailPixelSize: thumbnailSize],
                progress: nil) { image, _, error, cacheType, _, _ in
                    if let img = image {
                        if cacheType == .none {
                            print("Image download success: \(url)")
                        }
                        continuation.resume(returning: img)
                    } else {
                        print("Image download error: \(url) \(String(describing: error))")
                        continuation.resume(returning: nil)
                    }
            }
        }
    }
    
    func formatPrice(_ price: Double, _ currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        let priceString = String(format: "%.8f", price)
        let fractionDigits = priceString.split(separator: ".").last?.count ?? 0
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = price > 1000 ? 0 : fractionDigits
        return formatter.string(from: NSNumber(value: price)) ?? ""
    }
}

extension String {
    static func localized(_ key: String, _ args: CVarArg...) -> String {
        String(format: NSLocalizedString(key, comment: ""), arguments: args)
    }
}
