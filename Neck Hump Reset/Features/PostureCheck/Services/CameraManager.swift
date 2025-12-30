//
//  CameraManager.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import AVFoundation
import SwiftUI
import Combine

/// Manages camera capture session for posture detection
class CameraManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAuthorized: Bool = false
    @Published var isCameraReady: Bool = false
    @Published var capturedImage: CGImage?
    @Published var capturedImageData: Data? // For SwiftData storage
    @Published var error: CameraError?
    @Published var isUsingFrontCamera: Bool = true
    
    // MARK: - Properties
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session")
    private var currentCameraInput: AVCaptureDeviceInput?
    
    var onFrameCaptured: ((CMSampleBuffer) -> Void)?
    
    // MARK: - Init
    override init() {
        super.init()
        checkAuthorization()
    }
    
    // MARK: - Authorization
    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.isAuthorized = true
            }
            setupCamera()
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                }
                if granted {
                    self?.setupCamera()
                }
            }
            
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.isAuthorized = false
                self.error = .notAuthorized
            }
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Setup
    private func setupCamera() {
        sessionQueue.async { [weak self] in
            self?.configureSession(position: .front)
        }
    }
    
    private func configureSession(position: AVCaptureDevice.Position) {
        session.beginConfiguration()
        session.sessionPreset = .high
        
        // Remove existing input if any
        if let existingInput = currentCameraInput {
            session.removeInput(existingInput)
        }
        
        // Get camera for requested position
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            DispatchQueue.main.async {
                self.error = .cameraUnavailable
            }
            session.commitConfiguration()
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            
            if session.canAddInput(input) {
                session.addInput(input)
                currentCameraInput = input
            }
            
            // Add photo output for capturing stills (only if not already added)
            if !session.outputs.contains(photoOutput) {
                if session.canAddOutput(photoOutput) {
                    session.addOutput(photoOutput)
                }
            }
            
            // Configure photo connection
            if let photoConnection = photoOutput.connection(with: .video) {
                if photoConnection.isVideoRotationAngleSupported(90) {
                    photoConnection.videoRotationAngle = 90
                }
                // Mirror only for front camera
                if photoConnection.isVideoMirroringSupported {
                    photoConnection.isVideoMirrored = (position == .front)
                }
            }
            
            // Add video output for live analysis (only if not already added)
            if !session.outputs.contains(videoOutput) {
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video.output"))
                videoOutput.alwaysDiscardsLateVideoFrames = true
                
                if session.canAddOutput(videoOutput) {
                    session.addOutput(videoOutput)
                }
            }
            
            // Configure video connection
            if let connection = videoOutput.connection(with: .video) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
                // Mirror only for front camera
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = (position == .front)
                }
            }
            
            session.commitConfiguration()
            
            DispatchQueue.main.async {
                self.isCameraReady = true
                self.isUsingFrontCamera = (position == .front)
            }
            
        } catch {
            DispatchQueue.main.async {
                self.error = .setupFailed(error.localizedDescription)
            }
            session.commitConfiguration()
        }
    }
    
    // MARK: - Camera Flip
    func flipCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            let newPosition: AVCaptureDevice.Position = self.isUsingFrontCamera ? .back : .front
            self.configureSession(position: newPosition)
        }
    }
    
    // MARK: - Session Control
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
                print("📷 Camera session started")
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                print("📷 Camera session stopped")
            }
        }
    }
    
    // MARK: - Capture Photo
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - Set image from external source (photo library)
    func setImage(from uiImage: UIImage) {
        let portraitImage = uiImage.toPortrait()
        let jpegData = portraitImage.jpegData(compressionQuality: 0.8)
        
        DispatchQueue.main.async {
            self.capturedImage = portraitImage.cgImage
            self.capturedImageData = jpegData
            print("📷 Image set from library: \(portraitImage.size.width)x\(portraitImage.size.height)")
        }
    }
    
    // MARK: - Clear captured image
    func clearCapturedImage() {
        capturedImage = nil
        capturedImageData = nil
    }
}

// MARK: - Video Output Delegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        onFrameCaptured?(sampleBuffer)
    }
}

// MARK: - Photo Capture Delegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.error = .captureFailed(error.localizedDescription)
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let uiImage = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                self.error = .captureFailed("Failed to process image")
            }
            return
        }
        
        // Ensure portrait orientation (fixes EXIF and rotates if landscape)
        let portraitImage = uiImage.toPortrait()
        
        // Convert to JPEG for storage (good quality, reasonable size)
        let jpegData = portraitImage.jpegData(compressionQuality: 0.8)
        
        DispatchQueue.main.async {
            self.capturedImage = portraitImage.cgImage
            self.capturedImageData = jpegData
            print("📷 Photo captured: \(portraitImage.size.width)x\(portraitImage.size.height)")
        }
    }
}

// MARK: - Camera Errors
enum CameraError: LocalizedError {
    case notAuthorized
    case cameraUnavailable
    case setupFailed(String)
    case captureFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Camera access not authorized. Please enable in Settings."
        case .cameraUnavailable:
            return "Camera is not available on this device."
        case .setupFailed(let reason):
            return "Camera setup failed: \(reason)"
        case .captureFailed(let reason):
            return "Photo capture failed: \(reason)"
        }
    }
}

// MARK: - UIImage Extension for Orientation Fix
extension UIImage {
    /// Fixes the orientation of the image to be upright (portrait)
    /// This properly handles all EXIF orientations and rotates/flips as needed
    func fixedOrientation() -> UIImage {
        // If already correct orientation, return as-is
        guard imageOrientation != .up else { return self }
        
        // Calculate the proper transform
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2)
        default:
            break
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        // Create the properly oriented image
        guard let cgImage = cgImage,
              let colorSpace = cgImage.colorSpace else {
            return self
        }
        
        // Determine output size (swap width/height for 90° rotations)
        let outputSize: CGSize
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            outputSize = CGSize(width: size.height, height: size.width)
        default:
            outputSize = size
        }
        
        guard let context = CGContext(
            data: nil,
            width: Int(outputSize.width),
            height: Int(outputSize.height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: cgImage.bitmapInfo.rawValue
        ) else {
            return self
        }
        
        context.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        guard let newCGImage = context.makeImage() else {
            return self
        }
        
        return UIImage(cgImage: newCGImage)
    }
    
    /// Returns a portrait-oriented version of the image
    /// Forces portrait even if the original was landscape
    func toPortrait() -> UIImage {
        // First fix any EXIF orientation issues
        let fixedImage = fixedOrientation()
        
        // Check if image is landscape (width > height)
        if fixedImage.size.width > fixedImage.size.height {
            // Rotate 90 degrees to make it portrait
            guard let cgImage = fixedImage.cgImage else { return fixedImage }
            
            let rotatedSize = CGSize(width: fixedImage.size.height, height: fixedImage.size.width)
            
            UIGraphicsBeginImageContextWithOptions(rotatedSize, false, fixedImage.scale)
            guard let context = UIGraphicsGetCurrentContext() else {
                UIGraphicsEndImageContext()
                return fixedImage
            }
            
            // Rotate 90 degrees clockwise
            context.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            context.rotate(by: .pi / 2)
            context.translateBy(x: -fixedImage.size.width / 2, y: -fixedImage.size.height / 2)
            
            context.draw(cgImage, in: CGRect(origin: .zero, size: fixedImage.size))
            
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return rotatedImage ?? fixedImage
        }
        
        return fixedImage
    }
}
