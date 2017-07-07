//
//  ViewController.swift
//  QRCodeDetector
//
//  Created by Eq inc. on 2017/06/22.
//  Copyright © 2017年 EQ. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var albumButton: UIButton!
    @IBOutlet weak var readButton: UIButton!
    @IBOutlet weak var writeButton: UIButton!
    @IBOutlet weak var inputField: UITextField!
    @IBOutlet weak var barcodeView: UIImageView!

    let logView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // 検出した内容を表示するための View を作成
        logView.frame = barcodeView.frame // たまたま都合がいいので同じ frame で表示
        logView.backgroundColor = UIColor.clear
        logView.textColor = UIColor.magenta
        if let window = UIApplication.shared.delegate?.window {
            window?.addSubview(logView)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logView.isHidden = true
        logView.text = nil
    }

    func startQRCodeDetecting() {
        let vc = QRCodeCaptureViewController()
        vc.delegate = self
        vc.isShowDetectedArea = true
        let nav = UINavigationController.init(rootViewController: vc)
        present(nav, animated: true, completion: nil)
    }

    @IBAction func read() {
        startQRCodeDetecting()
        logView.isHidden = false
        // 前面に表示したいので付け直し
        if let view = logView.superview {
            view.bringSubview(toFront: logView)
        }
    }

    @IBAction func album() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }

    @IBAction func write() {
        var text = inputField.text ?? ""
        if text.lengthOfBytes(using: .utf8) == 0 {
            text = "EQいいゾ〜"
        }
        if let image = QRCodeGenerator.generate(string: text, constraints: barcodeView.bounds.size) {
            showQRCode(image: image)
        }
    }

    fileprivate func logMessage(_ message: String) {
        DispatchQueue.main.async {
            let text = self.logView.text
            self.logView.text = message + "\n" + (text ?? "")
        }
    }

    fileprivate func showQRCode(image: UIImage) {
        barcodeView.image = image
        if inputField.isFirstResponder {
            inputField.resignFirstResponder()
        }
    }
}

extension ViewController: QRCodeCaptureDelegate {
    func capture(_ capture: QRCodeCapture, didDetect value: String) -> Bool {
        logMessage("# \(value)")
        return true
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }
        guard let arr = QRCodeDetector().detect(from: image) else {
            return
        }
        if let descriptor = arr.first {
            if let image = QRCodeGenerator.generate(descriptor: descriptor, constraints: barcodeView.bounds.size) {
                showQRCode(image: image)
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
}
