//
//  AppConfig.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import Foundation

/// App-wide configuration settings
/// Toggle these during development
struct AppConfig {
    
    /// Set to `true` to show developer options in Settings
    /// Set to `false` before shipping to App Store
    static let testMode = true
    
    /// Set to `true` to always show onboarding (ignores saved state)
    static let alwaysShowOnboarding = false
    
    /// Splash screen duration in seconds
    static let splashDuration: Double = 1
}
