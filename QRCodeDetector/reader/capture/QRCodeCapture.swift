//
//  AppDelegate.swift
//  QRCodeDetector
//
//  Created by Eq inc. on 2017/06/22.
//  Copyright © 2017年 EQ. All rights reserved.
//

import Foundation
import AVFoundation


/// バーコードの読み取りに関する Delegate です。
protocol BarcodeCaptureDelegate {

    /// QRコードを検出した際に呼び出されます。
    ///
    /// - Parameters:
    ///   - capture: QRCodeCapture
    ///   - codeObject: 検出した QR コード
    ///   - value: 検出した QR コード内の文字列
    /// - Returns: 継続して検出を行うかどうか
    ///             true:継続する
    ///             false:検出を停止する
    func capture(_ capture: QRCodeCapture, didDetect codeObject: AVMetadataMachineReadableCodeObject, value: String) -> Bool

}

/// コード読み取りのための準備結果を示す
///
/// - notReady: 準備が完了していない
/// - success: 準備完了
/// - notAuthorized: 必要な機能の許可が得られていない
/// - configurationFailed: 初期化処理で問題が発生した
enum CaptureSessionSetupResult {
    case notReady
    case success
    case notAuthorized
    case configurationFailed
}

private enum CaptureSessionError: Error {
    case configure(String)
}


/// QRコードの読み込みを行うクラスです。
class QRCodeCapture: NSObject {

    fileprivate let captureSession = AVCaptureSession()
    /// AVCaptureSession 操作用のスレッド(serial)
    fileprivate let sessionQueue = DispatchQueue(label: "capture session queue", attributes: [], target: nil)
    fileprivate var setupResult: CaptureSessionSetupResult = .notReady
    private var videoDeviceInput: AVCaptureDeviceInput!
    private var metadataOutput: AVCaptureMetadataOutput!

    var session: AVCaptureSession {
        return captureSession
    }

    /// QRコード読み取り時の処理を行うための delegate です。
    var delegate: BarcodeCaptureDelegate? = nil

    //
    // MARK: - Setup
    //

    /// 読み取りのための準備を行います。
    /// setupResult が notReady の場合に一度だけ実行されます。
    func setUp() {
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }

    private func configureSession() {
        guard setupResult == .notReady else {
            return
        }
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        captureSession.sessionPreset = AVCaptureSessionPresetMedium

        do {
            let deviceInput = try usableCaptureInput()
            captureSession.addInput(deviceInput)
            self.videoDeviceInput = deviceInput

            let metaOutput = try usableCaptureOutput()
            captureSession.addOutput(metaOutput)
            self.metadataOutput = metaOutput

            metaOutput.setMetadataObjectsDelegate(self, queue: sessionQueue)
            metaOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            setupResult = .success
        } catch {
            print("Could not create video device input: \(error)")
            setupResult = .configurationFailed
            return
        }
    }

    private func usableCaptureInput() throws -> AVCaptureDeviceInput {
        guard let device = availableVideoDevice() else {
            throw CaptureSessionError.configure("This device do not have available video device")
        }
        let input = try AVCaptureDeviceInput(device: device)
        guard captureSession.canAddInput(input) else {
            throw CaptureSessionError.configure("Could not add video device input to the session")
        }
        return input
    }

    private func usableCaptureOutput() throws -> AVCaptureMetadataOutput {
        let output = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(output) else {
            throw CaptureSessionError.configure("Could not add video device output to the session")
        }
        if let connection = output.connection(withMediaType: AVMediaTypeVideo) {
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
        }
        return output
    }

    private func availableVideoDevice() -> AVCaptureDevice? {
        let discovery = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: AVMediaTypeVideo, position: .back)
        return discovery?.devices.first
    }

    //
    // MARK: - Manipulation
    //

    /// QRコードの読み取りを開始します。
    ///
    /// - Parameter result: 読み込み開始後に呼び出されます。また、その際の準備結果が返されます。
    ///                     この処理はメインスレッドで呼び出されます。
    func start(result: @escaping (CaptureSessionSetupResult) -> Void) {
        sessionQueue.async { [weak self] in
            guard self?.setupResult == .success else {
                DispatchQueue.main.async {
                    result(self?.setupResult ?? .notReady)
                }
                return
            }
            self?.captureSession.startRunning()
            DispatchQueue.main.async {
                result(.success)
            }
        }
    }

    /// QRコードの読み取りを停止します。
    func stop() {
        sessionQueue.async { [weak self] in
            guard self?.setupResult == .success else {
                return
            }
            guard self?.captureSession.isRunning == true else {
                return
            }
            self?.captureSession.stopRunning()
        }
    }
}

extension QRCodeCapture {

    fileprivate func didDetect(codeObject: AVMetadataMachineReadableCodeObject, value: String) {
        guard let delegate = delegate else {
            return
        }
        if !delegate.capture(self, didDetect: codeObject, value: value) {
            stop()
        }
    }
}

extension QRCodeCapture
    // Authorization
{

    /// 必要な機能の認証が得られているかを確認し、まだ未確認だった場合はユーザに対して認証要求を表示します。
    ///
    /// - Parameter authorized: 認証の確認後に呼び出されます。引数に認証の有無が渡されます（認証されている場合に true）。
    func checkAndConfirmAuthorization(authorized: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
        case .authorized:
            authorized(true)
            break
        case .notDetermined:
            self.requestAccess { [weak self] granted in
                if !granted {
                    self?.setupResult = .notAuthorized
                }
                authorized(granted)
            }
        default:
            setupResult = .notAuthorized
            authorized(false)
        }
    }

    private func requestAccess(_ authorized: @escaping (Bool) -> Void) {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { [weak self] granted in
            self?.sessionQueue.resume()
            authorized(granted)
        }
    }
}

extension QRCodeCapture: AVCaptureMetadataOutputObjectsDelegate {

    internal func captureOutput(_ output: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        for metadata in metadataObjects {
            guard let data = metadata as? AVMetadataMachineReadableCodeObject else {
                continue
            }
            guard data.type == AVMetadataObjectTypeQRCode else {
                continue
            }
            if let value = data.stringValue {
                didDetect(codeObject: data, value: value)
            }
            break
        }
    }

}
