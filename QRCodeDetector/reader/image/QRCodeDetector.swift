import Foundation
import UIKit
import Vision


class QRCodeDetector {

    func detect(from image: UIImage) -> [CIBarcodeDescriptor]? {
        guard let cgImage = image.cgImage else {
            return nil
        }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        guard let results = detectBarcode(handler) else {
            return nil
        }
        return results.flatMap { $0.barcodeDescriptor }
    }

    private func detectBarcode(_ handler: VNImageRequestHandler) -> [VNBarcodeObservation]? {
        let request = VNDetectBarcodesRequest()
        try? handler.perform([request])
        return request.results as? [VNBarcodeObservation]
    }
}
