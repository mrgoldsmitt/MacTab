import Cocoa
import CoreGraphics

public class ThumbnailEngine {
    public static let shared = ThumbnailEngine()
    
    private let cache = NSCache<NSNumber, NSImage>()
    private let queue = DispatchQueue(label: "com.mactab.thumbnail", qos: .userInitiated, attributes: .concurrent)
    
    private init() {
        cache.countLimit = 64
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB max thumbnail cache
    }
    
    public func getCachedThumbnail(for windowID: CGWindowID) -> NSImage? {
        return cache.object(forKey: NSNumber(value: windowID))
    }
    
    public func captureThumbnail(
        for windowID: CGWindowID,
        bounds: CGRect = .null,
        maxPixelDimension: CGFloat = 500,
        completion: @escaping (NSImage?) -> Void
    ) {
        if let cached = cache.object(forKey: NSNumber(value: windowID)) {
            DispatchQueue.main.async {
                completion(cached)
            }
            return
        }
        
        queue.async {
            // Options: capture single window, nominal resolution for fast preview
            let imageOptions: CGWindowImageOption = [.nominalResolution, .boundsIgnoreFraming]
            let listOptions: CGWindowListOption = [.optionIncludingWindow]
            
            guard let cgImage = CGWindowListCreateImage(
                bounds,
                listOptions,
                windowID,
                imageOptions
            ) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Downscale to reasonable size to save memory and ensure snappy UI rendering
            let width = CGFloat(cgImage.width)
            let height = CGFloat(cgImage.height)
            
            guard width > 0, height > 0 else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let scale = min(maxPixelDimension / max(width, height), 1.0)
            let targetSize = CGSize(width: width * scale, height: height * scale)
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
            
            guard let context = CGContext(
                data: nil,
                width: Int(targetSize.width),
                height: Int(targetSize.height),
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else {
                let directImage = NSImage(cgImage: cgImage, size: targetSize)
                self.cache.setObject(directImage, forKey: NSNumber(value: windowID))
                DispatchQueue.main.async {
                    completion(directImage)
                }
                return
            }
            
            context.interpolationQuality = .medium
            context.draw(cgImage, in: CGRect(origin: .zero, size: targetSize))
            
            if let scaledCgImage = context.makeImage() {
                let finalImage = NSImage(cgImage: scaledCgImage, size: targetSize)
                self.cache.setObject(finalImage, forKey: NSNumber(value: windowID))
                DispatchQueue.main.async {
                    completion(finalImage)
                }
            } else {
                let directImage = NSImage(cgImage: cgImage, size: targetSize)
                self.cache.setObject(directImage, forKey: NSNumber(value: windowID))
                DispatchQueue.main.async {
                    completion(directImage)
                }
            }
        }
    }
    
    public func clearCache() {
        cache.removeAllObjects()
    }
}
