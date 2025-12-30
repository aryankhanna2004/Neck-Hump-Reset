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
    @Published var error: CameraError?
    
    // MARK: - Properties
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session")
    
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
            self?.configureSession()
        }
    }
    
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high
        
        // Add front camera input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
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
            }
            
            // Add photo output for capturing stills
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }
            
            // Add video output for live analysis
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video.output"))
            videoOutput.alwaysDiscardsLateVideoFrames = true
            
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
                
                // Set video orientation
                if let connection = videoOutput.connection(with: .video) {
                    if connection.isVideoRotationAngleSupported(90) {
                        connection.videoRotationAngle = 90
                    }
                    if connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = true
                    }
                }
            }
            
            session.commitConfiguration()
            
            DispatchQueue.main.async {
                self.isCameraReady = true
            }
            
        } catch {
            DispatchQueue.main.async {
                self.error = .setupFailed(error.localizedDescription)
            }
            session.commitConfiguration()
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
              let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            DispatchQueue.main.async {
                self.error = .captureFailed("Failed to process image")
            }
            return
        }
        
        DispatchQueue.main.async {
            self.capturedImage = cgImage
            print("📷 Photo captured: \(cgImage.width)x\(cgImage.height)")
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
            return "Front camera is not available on this device."
        case .setupFailed(let reason):
            return "Camera setup failed: \(reason)"
        case .captureFailed(let reason):
            return "Photo capture failed: \(reason)"
        }
    }
}
