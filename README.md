# Neck Hump Reset

An iOS app that helps users track and improve their neck posture using on-device pose detection. Take a side-profile photo, get instant analysis of your craniovertebral angle (CVA), and follow research-backed exercises to correct forward head posture.

## Features

- **AI Posture Analysis** - Uses Google ML Kit Pose Detection to measure your craniovertebral angle from a side-profile photo. All processing happens on-device.
- **Posture Score** - Receive a posture score (0-100) with severity classification (minimal, mild, moderate, severe).
- **Progress Tracking** - Track your posture over time with photo history, daily streaks, and weekly averages. Data is stored locally using SwiftData.
- **Research-Backed Exercises** - Exercise routines based on peer-reviewed studies:
  - Isometric neck strengthening (Sadeghi et al. 2022)
  - Deep neck flexor training (Jull et al. 2008)
  - Cervical proprioception training (Gallego Izquierdo et al. 2016)
- **Personalized Onboarding** - Tailors the experience based on screen time habits, movement comfort level, and any exercise restrictions.
- **Real-Time Camera Guidance** - Live pose overlay and positioning feedback while taking your posture check photo.

## Tech Stack

- **SwiftUI** - Declarative UI framework
- **SwiftData** - Local data persistence for posture photos and history
- **Google ML Kit (Pose Detection Accurate)** - On-device pose landmark detection
- **Apple Vision** - Body segmentation for improved C7 vertebra estimation
- **AVFoundation** - Camera capture and management
- **CocoaPods** - Dependency management

## Requirements

- iOS 17.0+
- Xcode 16.0+
- CocoaPods

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/aryankhanna2004/Neck-Hump-Reset.git
   cd Neck-Hump-Reset
   ```

2. Install dependencies:
   ```bash
   pod install
   ```

3. Open the workspace in Xcode:
   ```bash
   open "Neck Hump Reset.xcworkspace"
   ```

4. Build and run on a physical device (camera required for posture checks).

## Privacy

All data stays on your device. No photos, posture scores, or personal information are uploaded to any server. See our [Privacy Policy](https://aryankhanna2004.github.io/Neck-Hump-Reset/privacy-policy).

## License

This project is proprietary software. All rights reserved. You may view the source code but may not copy, modify, distribute, or use it without permission. See [LICENSE](LICENSE) for details.
