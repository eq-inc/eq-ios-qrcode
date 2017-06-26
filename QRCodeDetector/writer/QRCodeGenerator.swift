//
//  AppDelegate.swift
//  QRCodeDetector
//
//  Created by Eq inc. on 2017/06/22.
//  Copyright © 2017年 EQ. All rights reserved.
//

import Foundation
import CoreImage
import UIKit


fileprivate let FilterNameQRCode = "CIQRCodeGenerator"
fileprivate let FilterParamInputMessage = "inputMessage"
fileprivate let FilterParamCorrectionLevel = "inputCorrectionLevel"

/// QRコードの生成を行うクラスです。
class QRCodeGenerator {

    /// 誤り訂正レベル（損傷等の心配はないため最低レベルを指定）
    private let correctionLevel = "L"

    private func generateCode(data: Data) -> CGImage? {
        let params: [String:Any] = [
            FilterParamInputMessage: data,
            FilterParamCorrectionLevel: correctionLevel
        ]
        let filter = CIFilter(name: FilterNameQRCode, withInputParameters: params)
        guard let image = filter?.outputImage else {
            return nil
        }
        return CIContext().createCGImage(image, from: image.extent)
    }

    /// QRコードを生成します。
    ///
    /// - Parameter data: コード内に含めるデータ
    /// - Returns: QRコードの画像
    class func generate(data: Data) -> UIImage? {
        guard let image = QRCodeGenerator().generateCode(data: data) else {
            return nil
        }
        return UIImage(cgImage: image)
    }

    /// QRコードを生成します。
    ///
    /// - Parameters:
    ///   - data: コード内に含めるデータ
    ///   - constraints: 画像サイズ（指定されたサイズに拡大/縮小されます。）
    /// - Returns: QRコードの画像
    class func generate(data: Data, constraints: CGSize) -> UIImage? {
        guard let image = self.generate(data: data) else {
            return nil
        }
        UIGraphicsBeginImageContextWithOptions(constraints, true, 0)
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.interpolationQuality = .none
        image.draw(in: CGRect(x: 0, y: 0, width: constraints.width, height: constraints.height))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized
    }
}
