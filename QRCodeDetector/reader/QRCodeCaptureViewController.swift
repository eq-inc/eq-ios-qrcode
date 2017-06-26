//
//  AppDelegate.swift
//  QRCodeDetector
//
//  Created by Eq inc. on 2017/06/22.
//  Copyright © 2017年 EQ. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation


protocol QRCodeCaptureDelegate {

    /// QRコードを検出した際に呼び出されます。
    ///
    /// - Parameters:
    ///   - capture: QRCodeCapture
    ///   - value: 検出した QR コード内の文字列
    /// - Returns: 継続して検出を行うかどうか
    ///     true:継続する
    ///     false:検出を停止する
    func capture(_ capture: QRCodeCapture, didDetect value: String) -> Bool
}

/// QRコードの読み取りを行う画面です。
class QRCodeCaptureViewController: UIViewController {

    private let capture = QRCodeCapture()
    private let previewView = PreviewView()
    private lazy var detectAreaView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.layer.borderColor = UIColor.red.cgColor
        view.layer.borderWidth = 1
        return view
    }()

    var isShowDetectedArea = false

    /// QRコード読み取り時の処理を行うための delegate です。
    var delegate: QRCodeCaptureDelegate? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        capture.delegate = self

        previewView.session = capture.session
        previewView.frame = self.view.bounds
        self.view.addSubview(previewView)

        if let nav = self.navigationController {
            nav.navigationBar.setBackgroundImage(UIImage(), for: .default)
            nav.navigationBar.shadowImage = UIImage()
            let cancel = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelCapturing))
            self.navigationItem.rightBarButtonItem = cancel
        }
    }

    private func startCapturing() {
        capture.checkAndConfirmAuthorization { [weak self] in
            guard $0 else {
                return
            }
            self?.capture.setUp()
            self?.capture.start { [weak self] in
                switch $0 {
                case .notReady:
                    break
                case .success:
                    break
                case .notAuthorized:
                    self?.alertNotAuthorization()
                case .configurationFailed:
                    self?.alertConfigurationFailed()
                }
            }
        }
    }

    @objc private func cancelCapturing() {
        capture.stop()
        self.dismiss(animated: true, completion: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startCapturing()
    }

    override func viewWillDisappear(_ animated: Bool) {
        capture.stop()
        super.viewWillDisappear(animated)
    }

    fileprivate func showDetectedArea(_ metadata: AVMetadataObject) {
        DispatchQueue.main.async {
            guard let obj = self.previewView.videoPreviewLayer.transformedMetadataObject(for: metadata) else {
                return
            }
            self.detectAreaView.frame = obj.bounds
            print("bounds: \(metadata.bounds) --transform--> \(obj.bounds)")
            self.previewView.addSubview(self.detectAreaView)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                self.detectAreaView.removeFromSuperview()
            }
        }
    }
}

extension QRCodeCaptureViewController: BarcodeCaptureDelegate {

    func capture(_ capture: QRCodeCapture, didDetect codeObject: AVMetadataMachineReadableCodeObject, value: String) -> Bool {
        if isShowDetectedArea {
            showDetectedArea(codeObject)
        }
        if let delegate = delegate {
            return delegate.capture(capture, didDetect: value)
        }
        return true
    }
}

extension QRCodeCaptureViewController
    // Alert
{
    fileprivate func alertNotAuthorization() {
        let changePrivacySetting = "QRCode sample doesn't have permission to use the camera, please change privacy settings"
        let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
        let alertController = UIAlertController(title: "QRCode sample", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                style: .cancel,
                                                handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                                style: .`default`,
                                                handler: { _ in
                                                    let url = URL(string: UIApplicationOpenSettingsURLString)!
                                                    UIApplication.shared.openURL(url)
        }))
        self.present(alertController, animated: true, completion: nil)
    }

    fileprivate func alertConfigurationFailed() {
        let alertMsg = "Alert message when something goes wrong during capture session configuration"
        let message = NSLocalizedString("Unable to capture media", comment: alertMsg)
        let alertController = UIAlertController(title: "QRCode sample", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                style: .cancel,
                                                handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}
