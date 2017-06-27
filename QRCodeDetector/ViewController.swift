//
//  ViewController.swift
//  QRCodeDetector
//
//  Created by Eq inc. on 2017/06/22.
//  Copyright © 2017年 EQ. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var readButton: UIButton!
    @IBOutlet var writeButton: UIButton!
    @IBOutlet var inputField: UITextField!
    @IBOutlet var barcodeView: UIImageView!

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

    @IBAction func write() {
        var text = inputField.text ?? ""
        if text.lengthOfBytes(using: .utf8) == 0 {
            text = "EQいいゾ〜"
        }
        barcodeView.image = QRCodeGenerator.generate(string: text, constraints: barcodeView.bounds.size)
        if inputField.isFirstResponder {
            inputField.resignFirstResponder()
        }
    }

    fileprivate func logMessage(_ message: String) {
        DispatchQueue.main.async {
            let text = self.logView.text
            self.logView.text = message + "\n" + (text ?? "")
        }
    }
}

extension ViewController: QRCodeCaptureDelegate {
    func capture(_ capture: QRCodeCapture, didDetect value: String) -> Bool {
        logMessage("# \(value)")
        return true
    }
}

