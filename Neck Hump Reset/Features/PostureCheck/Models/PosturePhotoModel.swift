//
//  PosturePhotoModel.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI
import SwiftData

/// SwiftData model for storing posture check photos and results
@Model
final class PosturePhoto {
    /// Unique identifier
    var id: UUID
    
    /// Photo data stored as binary
    @Attribute(.externalStorage)
    var imageData: Data?
    
    /// Timestamp when the photo was taken
    var timestamp: Date
    
    /// Craniovertebral Angle (CVA) in degrees - key metric for forward head posture
    var craniovertebralAngle: Double?
    
    /// Forward head distance in estimated cm
    var forwardHeadDistance: Double?
    
    /// Neck angle in degrees
    var neckAngle: Double?
    
    /// Overall posture score (0-100)
    var postureScore: Int?
    
    /// Severity classification
    var severityRaw: String?
    
    /// Detected ear position (normalized 0-1)
    var earPointX: Double?
    var earPointY: Double?
    
    /// Detected shoulder position (normalized 0-1)
    var shoulderPointX: Double?
    var shoulderPointY: Double?
    
    /// Optional notes from user
    var notes: String?
    
    // MARK: - Computed Properties
    
    var severity: HumpSeverity? {
        get {
            guard let raw = severityRaw else { return nil }
            return HumpSeverity(rawValue: raw)
        }
        set {
            severityRaw = newValue?.rawValue
        }
    }
    
    var earPoint: CGPoint? {
        get {
            guard let x = earPointX, let y = earPointY else { return nil }
            return CGPoint(x: x, y: y)
        }
        set {
            earPointX = newValue.map { Double($0.x) }
            earPointY = newValue.map { Double($0.y) }
        }
    }
    
    var shoulderPoint: CGPoint? {
        get {
            guard let x = shoulderPointX, let y = shoulderPointY else { return nil }
            return CGPoint(x: x, y: y)
        }
        set {
            shoulderPointX = newValue.map { Double($0.x) }
            shoulderPointY = newValue.map { Double($0.y) }
        }
    }
    
    /// Get UIImage from stored data
    var image: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
    
    // MARK: - Init
    
    init(
        imageData: Data? = nil,
        timestamp: Date = Date(),
        result: NeckHumpAnalysisResult? = nil
    ) {
        self.id = UUID()
        self.imageData = imageData
        self.timestamp = timestamp
        
        if let result = result {
            self.craniovertebralAngle = result.craniovertebralAngle
            self.forwardHeadDistance = result.forwardHeadDistance
            self.neckAngle = result.neckAngle
            self.postureScore = result.overallScore
            self.severityRaw = result.humpSeverity.rawValue
            self.earPointX = Double(result.earPosition.x)
            self.earPointY = Double(result.earPosition.y)
            self.shoulderPointX = Double(result.shoulderPosition.x)
            self.shoulderPointY = Double(result.shoulderPosition.y)
        }
    }
    
    // MARK: - Helpers
    
    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    /// Short date for cards
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: timestamp)
    }
    
    /// Time only
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    /// Relative date (e.g., "Today", "Yesterday", "3 days ago")
    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
