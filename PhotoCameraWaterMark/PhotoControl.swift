import Foundation
import UIKit
import Photos
import ImageIO

class PhotoControl: NSObject , ObservableObject{
    @Published var image: UIImage? = nil
    @Published var isAdded: Bool = false
    @Published var modelInfo: String = ""
    @Published var isSaveSuccess: Bool = false
    
    @Published var cameraInfo: String = ""
    @Published var focalLength: String = ""
    @Published var fNumber: String = ""
    @Published var exposureTime: String = ""
    @Published var iso: String = ""
    
    func resetData() {
        cameraInfo = ""
        focalLength = ""
        fNumber = ""
        exposureTime = ""
        iso = ""
    }
    
    /**
     添加水印
     */
    func setPhotoWaterMark(originalImage: UIImage) {
        if isAdded { return }
        // 设置水印条的高度和颜色
        let width = originalImage.size.width
        let watermarkHeight: CGFloat = originalImage.size.width > 2000 ? 300.0 : 200
        let watermarkColor = UIColor.white
        let newSize = CGSize(width: originalImage.size.width, height: originalImage.size.height + watermarkHeight) // 新的画布大小
        
        // 创建一个绘制上下文，以便操作图片和添加水印
        UIGraphicsBeginImageContextWithOptions(newSize, false, originalImage.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            // 处理无法获取绘制上下文的情况
            return
        }
        
        // 将原始图片绘制到上下文中
        originalImage.draw(at: CGPoint(x: 0, y: 0))
        
        // 在下方添加白色水印条
        context.setFillColor(watermarkColor.cgColor)
        UIRectFill(CGRect(x: 0, y: newSize.height - watermarkHeight, width: newSize.width, height: watermarkHeight))
        
        // 在水印条上左侧绘制文字（相机信息）
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: (originalImage.size.width > 2000 ? 80.0 : 40.0)),
            .foregroundColor: UIColor.black // 文字颜色为黑色
        ]
        
        let text = cameraInfo
        let textSize1 = (text as NSString).size(withAttributes: textAttributes)
        let textRect = CGRect(x: 100, y: originalImage.size.height + (watermarkHeight - textSize1.height) / 2, width: originalImage.size.width - 20, height: textSize1.height)
        (text as NSString).draw(in: textRect, withAttributes: textAttributes)
        
        //在水印条上右侧绘制文字（相机信息）
        let textArray = [focalLength, fNumber, exposureTime, iso]
        var totalWidth: CGFloat = 0
        for text in textArray {
            let textSize = (text as NSString).size(withAttributes: textAttributes)
            totalWidth = totalWidth + textSize.width
        }
        
        var xOffset: CGFloat = originalImage.size.width - totalWidth - 250 // 从右侧开始
        for text in textArray {
            let textSize = (text as NSString).size(withAttributes: textAttributes)
            let textRect = CGRect(x: xOffset, y: originalImage.size.height + (watermarkHeight - textSize1.height) / 2, width: textSize.width, height: textSize.height)
            (text as NSString).draw(in: textRect, withAttributes: textAttributes)
            
            // 更新下一个文本的 x 坐标
            xOffset += textSize.width + 50 // 添加一些间距
        }
        
        
        // 从绘制的上下文中获取新的图片
        let watermarkedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        image = watermarkedImage
        isAdded = true
    }
    
    /**
     保存图片
     */
    func saveToPhotosAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // 保存失败时的处理
            print("Error saving image: \(error.localizedDescription)")
        } else {
            // 保存成功时的处理
            isSaveSuccess = true
            print("Image saved successfully")
        }
    }
    
    /**
     获取照片信息
     */
    func getPhotoInfo(photoAsset: PHAsset?) {
        // 假设你有一个 PHAsset 对象，名为 photoAsset，代表了你想要获取信息的照片
        if let asset = photoAsset {
            let imageManager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            
            // 获取照片的基本信息
            let assetIdentifier = asset.localIdentifier
            let creationDate = asset.creationDate
            let modificationDate = asset.modificationDate
            let location = asset.location
            
            // 获取照片的相关资源
            let resources = PHAssetResource.assetResources(for: asset)
            for resource in resources {
                let originalFilename = resource.originalFilename
                let assetType = resource.type
                let assetSize = resource.accessibilityFrame.size
                
            }
            
            // 获取照片的相机信息
            imageManager.requestImageData(for: asset, options: requestOptions) { (data, _, _, info) in
                if let imageData = data,
                   let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
                   let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] {
                    
                    // 相机相关
                    if let cameraInfo = imageProperties["{TIFF}"] as? [String: Any] {
//                        let cameraModel = cameraInfo["HostComputer"]  //只有手机信息
                        let cameraModel = cameraInfo["Model"]
                        let dateTime = cameraInfo["DateTime"]
                        
                        if let info = cameraModel as? String {
                            self.cameraInfo = info
                        }
                        
                        print("相机信息\(cameraModel)")
                        print("拍摄时间\(dateTime)")
                    }
                    
                    if let cameraInfo = imageProperties[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
                        let latitude = cameraInfo[kCGImagePropertyGPSLatitude as String]
                        print("照片纬度信息\(latitude)")
                    }
                    
                    if let cameraInfo = imageProperties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
                        // 获取更多相机信息，例如相机型号、光圈、快门速度等
//                        let cameraModel = cameraInfo[kCGImagePropertyExifLensModel as String]
                        let focalLength = cameraInfo[kCGImagePropertyExifFocalLength as String]
                        let fNumber = cameraInfo[kCGImagePropertyExifFNumber as String]
                        let exposureTime = cameraInfo[kCGImagePropertyExifExposureTime as String]
                        let cameraISO = cameraInfo[kCGImagePropertyExifISOSpeedRatings as String]
                       
//                        if ((cameraModel != nil) && (cameraModel as! String) != "nil") {
//                            self.modelInfo = cameraModel as! String
//                        }
                        
                        if let focalLength = focalLength as? Double {
                            self.focalLength = String(focalLength) + "mm"
                        }
                        
                        if let fNumber = fNumber as? Double {
                            self.fNumber = "f/" + String(fNumber)
                        }
                        
                        if let exposureTime = exposureTime as? Double {
                            self.exposureTime = self.convertToFraction(seconds: (exposureTime as? Double) ?? 0.00)
                        }
                        
                        if let cameraISO  = cameraISO as? [Any] {
                            if let firstValue = cameraISO.first {
                                var value = firstValue as? Int ?? 0
                                self.iso = value != 0 ? "ISO\(String(value))" : ""
                                
                                print("相机iso：\(firstValue)")
                            }
                        }
                        
//                        print("手机信息：\(cameraModel)")
                        print("相机焦距：\(focalLength)")
                        print("光圈：\(fNumber)")
                        print("快门速度：\(self.convertToFraction(seconds: (exposureTime as? Double) ?? 0.00))")
                        print("相机iso：\(cameraISO)")
                    }
                    
                }
            }
        }
    }
    
    func convertToFraction(seconds: Double) -> String {
        let tolerance = 1.0e-6 // 误差范围
        var (numerator, denominator) = (1, 1)
        let x = seconds
        var error = abs(x - Double(numerator) / Double(denominator))
        
        while error > tolerance {
            if x > Double(numerator) / Double(denominator) {
                numerator += 1
            } else {
                denominator += 1
            }
            error = abs(x - Double(numerator) / Double(denominator))
        }
        
        return "\(numerator)/\(denominator)s"
    }
}
