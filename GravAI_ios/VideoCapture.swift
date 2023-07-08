import Foundation
import AVFoundation

class VideoCapture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let captureSession = AVCaptureSession()
    var handler: ((CMSampleBuffer) -> Void)?
    var currentZoomFactor: CGFloat = 1.0

    override init() {
        super.init()
        setup()
    }

    func setup() {
        captureSession.beginConfiguration()
        let device = defaultFrontCamera() //インカメラを取得するメソッドを呼び出す

        guard
            let deviceInput = try? AVCaptureDeviceInput(device: device!),
            captureSession.canAddInput(deviceInput)
        else { return }
        captureSession.addInput(deviceInput)
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "mydispatchqueue"))
        videoDataOutput.alwaysDiscardsLateVideoFrames = true

        guard captureSession.canAddOutput(videoDataOutput) else { return }
        captureSession.addOutput(videoDataOutput)

        for connection in videoDataOutput.connections {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            
            // インカメラを使用している場合に画像を水平に反転させる
            if let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput,
               currentInput.device.position == .front,
               connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }

        captureSession.commitConfiguration()
    }

    func switchCamera(_ useFrontCamera: Bool) {
        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else { return }
        
        captureSession.beginConfiguration()
        
        captureSession.removeInput(currentInput)
        
        let newCameraPosition: AVCaptureDevice.Position = useFrontCamera ? .front : .back
        if let newCamera = camera(withPosition: newCameraPosition), let newInput = try? AVCaptureDeviceInput(device: newCamera) {
            captureSession.addInput(newInput)
            
            // インカメラを使用している場合に画像を水平に反転させる
            if useFrontCamera {
                if let videoDataOutput = captureSession.outputs.first as? AVCaptureVideoDataOutput {
                    for connection in videoDataOutput.connections {
                        if connection.isVideoOrientationSupported {
                            connection.videoOrientation = .portrait
                            connection.isVideoMirrored = true
                        }
                    }
                }
            }
        }

        if let videoDataOutput = captureSession.outputs.first as? AVCaptureVideoDataOutput {
            for connection in videoDataOutput.connections {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
        }
        
        captureSession.commitConfiguration()
    }

    func run(_ handler: @escaping (CMSampleBuffer) -> Void) {
        if !captureSession.isRunning {
            self.handler = handler
            DispatchQueue.global(qos: .background).async {
                self.switchCamera(true)
                self.captureSession.startRunning()
            }
        }
    }

    func stop() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    func defaultFrontCamera() -> AVCaptureDevice? {
        if let device = AVCaptureDevice.default(.builtInTrueDepthCamera, for: AVMediaType.video, position: .front) {
            return device
        } else if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) {
            return device
        } else {
            return nil
        }
    }
    
    func defaultCamera() -> AVCaptureDevice? {
        if let device = AVCaptureDevice.default(.builtInTripleCamera, for: AVMediaType.video, position: .back) {
            return device
        } else if let device = AVCaptureDevice.default(.builtInDualWideCamera, for: AVMediaType.video, position: .back) {
            return device
        } else if let device = AVCaptureDevice.default(.builtInDualCamera, for: AVMediaType.video, position: .back) {
            return device
        } else if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) {
            return device
        } else {
            return nil
        }
    }

    func camera(withPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        
        return discoverySession.devices.first { $0.position == position }
    }

    func zoom(factor: CGFloat) {
        guard let deviceInput = captureSession.inputs.first as? AVCaptureDeviceInput else { return }
        let device = deviceInput.device
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = factor
            device.unlockForConfiguration()
        } catch {
            print("Error setting zoom: \(error)")
        }
    }


    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let handler = handler {
            handler(sampleBuffer)
        }
    }
}
