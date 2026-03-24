---
layout: default
title: Privacy Policy
---

# Privacy Policy

**Effective Date: March 24, 2026**

Neck Hump Reset ("the App") is committed to protecting your privacy. This Privacy Policy explains how the App handles your information.

## Summary

**All data stays on your device.** The App does not collect, transmit, or store any personal data on external servers. There is no cloud component, no user accounts, and no analytics tracking.

## Data Collected

The App uses the following data, all of which is stored **locally on your device only**:

### Photos
- Side-profile photos taken during posture checks are stored on-device using Apple's SwiftData framework.
- Photos are **never** uploaded to any server or cloud service.
- You can delete your photos at any time from within the App.

### Face and Body Landmark Data
- The App uses Google ML Kit Pose Detection to detect body landmarks from your side-profile photo, including **ear position, eye position, nose position, shoulder position, and hip position**.
- These landmarks are used **solely** to calculate your craniovertebral angle (CVA) and determine your facing direction. The ear and shoulder landmarks are the primary data points used for posture scoring.
- **Face data is never collected, stored, or used for facial recognition, identification, or tracking purposes.** The App does not identify who you are from the detected landmarks.
- Landmark coordinates are processed **entirely on-device** in real-time. They exist only in temporary memory during the analysis and are **not saved** to disk or any database. Only the resulting posture score and angle measurement are stored.
- No face or body landmark data is **ever** transmitted off your device or shared with any third party, including Google.

### Posture Analysis Data
- Craniovertebral angle measurements, posture scores, and severity classifications are computed **entirely on-device** using Google ML Kit Pose Detection and Apple Vision.
- No analysis results are transmitted off your device.

### Personal Information
- Your name (if provided during onboarding) is stored locally using UserDefaults.
- Onboarding preferences (screen time habits, movement comfort level, exercise restrictions) are stored locally using UserDefaults.
- This information is used solely to personalize your in-app experience and **never** leaves your device.

## Data Processing

All data processing occurs **locally on your device**:

- **Pose Detection**: Google ML Kit's Accurate Pose Detector runs on-device to detect body landmarks (ears, eyes, nose, shoulders, hips). No images or landmark data are sent to Google or any third party.
- **Face/Body Landmark Processing**: Detected landmark coordinates (including facial points such as ears, eyes, and nose) are held in temporary memory only during the active analysis session. They are used to calculate the craniovertebral angle and are then discarded. Landmark coordinates are **never** written to persistent storage.
- **Body Segmentation**: Apple's Vision framework runs on-device for improved C7 vertebra estimation.
- **Posture Scoring**: All angle calculations and scoring happen locally. Only the final posture score, angle, and severity classification are saved — not the underlying landmark data.

## Third-Party Services

The App does **not** use any third-party analytics, advertising, or tracking services. There are no third-party SDKs that collect or transmit user data.

Google ML Kit is used for pose detection, but it operates **entirely on-device**. No data is sent to Google's servers.

## Data Storage

- **Photos and posture history**: Stored locally using Apple's SwiftData framework in the App's sandboxed container.
- **User preferences**: Stored locally using Apple's UserDefaults.
- **No cloud storage**: The App has no server, database, or cloud storage component.

## Data Sharing

The App does **not** share any data with third parties. There is no data to share because nothing leaves your device.

## Data Retention

- **Face and body landmark data**: Not retained. Landmark coordinates exist only in temporary memory during the active posture analysis and are discarded immediately after the posture score is calculated. They are never written to disk.
- **Photos and posture scores**: Remain on your device until you delete them within the App or delete the App itself (which removes all associated data).
- **Personal preferences**: Remain on your device until you delete the App.

## Children's Privacy

The App does not knowingly collect personal information from children under 13. Since all data is stored locally and never transmitted, no personal information of any user is collected by us.

## Camera Usage

The App requests camera access to take side-profile photos for posture analysis. The camera is used **only** for this purpose. Photos are processed on-device and are never uploaded or shared.

## Changes to This Policy

If this Privacy Policy is updated, the revised version will be posted on this page with an updated effective date.

## Contact & Issues

If you have questions about this Privacy Policy or encounter any issues with the App, please open an issue on our [GitHub Issues page](https://github.com/aryankhanna2004/Neck-Hump-Reset/issues).
