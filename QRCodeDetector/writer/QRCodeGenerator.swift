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

let QRCodeEncoding = String.Encoding.isoLatin1

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
    /// - Parameters:
    ///   - data: コード内に含めるデータ
    ///   - constraints: 画像サイズ（指定されたサイズに拡大/縮小されます。）
    /// - Returns: QRコードの画像
    class func generate(data: Data, constraints: CGSize? = nil) -> UIImage? {
        guard let image = QRCodeGenerator().generateCode(data: data) else {
            return nil
        }
        guard let size = constraints else {
            return UIImage(cgImage: image)
        }
        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.interpolationQuality = .none
        ctx?.draw(image, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized
    }

    /// QRコードを生成します。
    /// 指定された文字列のエンコードは以下の順で行われます。
    ///
    /// * ISO Latin1 (ISO 8859-1)
    /// * UTF-8
    ///
    /// いずれのエンコードにも失敗した場合は nil が返されます。
    ///
    /// - Parameter string: コード内に含める文字列
    /// - Returns: QRコードの画像
    class func generate(string: String, constraints: CGSize? = nil) -> UIImage? {
        for encoding in [QRCodeEncoding, .utf8] {
            if let data = string.data(using: encoding) {
                return generate(data: data, constraints: constraints)
            }
        }
        return nil
    }
}

