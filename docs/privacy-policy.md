---
layout: default
title: Privacy Policy
---

# Privacy Policy

**Effective Date: March 24, 2026**

Neck Hump Reset ("the App") is committed to protecting your privacy. This Privacy Policy explains how the App handles your information.

## Summary

**All your personal data stays on your device.** The App does not collect, transmit, or store any personal data (photos, landmark coordinates, posture scores, or profile information) on external servers. There is no cloud component, no user accounts, and no analytics tracking. The Google ML Kit SDK used for pose detection may send anonymous SDK usage diagnostics to Google (see Third-Party Services below), but **no user photos, images, face data, or personal information** are included in these diagnostics.

## Data Collected

The App uses the following data, all of which is stored **locally on your device only**:

### Photos
- Side-profile photos taken during posture checks are stored on-device using Apple's SwiftData framework.
- Photos are **never** uploaded to any server or cloud service.
- You can delete your photos at any time from within the App.

### Face and Body Landmark Data
- The App uses Google ML Kit Pose Detection to detect body landmarks from your side-profile photo, including **ear position, eye position, nose position, shoulder position, and hip position**.
- These landmarks are used **solely** to calculate your craniovertebral angle (CVA) and determine your facing direction.
- **Ear and shoulder landmark coordinates** are stored locally on your device alongside each posture check photo using Apple's SwiftData framework. This allows the App to display the posture overlay on your historical photos and track your progress over time.
- **Eye, nose, and hip landmark coordinates** are used only transiently during the analysis to determine facing direction. They exist only in temporary memory and are **not saved** to disk or any database.
- **Face data is never used for facial recognition, identification, or tracking purposes.** The App does not identify who you are from the detected landmarks.
- All landmark data is processed **entirely on-device**. No face or body landmark data is **ever** transmitted off your device or shared with any third party, including Google.
- You can delete any stored landmark data at any time by deleting the associated posture check photo from within the App.

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
- **Face/Body Landmark Processing**: Detected landmark coordinates (including facial points such as ears, eyes, and nose) are processed on-device. Ear and shoulder coordinates are saved locally alongside each posture check photo to enable progress tracking and overlay display. Eye, nose, and hip coordinates are held in temporary memory only during the active analysis session and are then discarded.
- **Body Segmentation**: Apple's Vision framework runs on-device for improved C7 vertebra estimation.
- **Posture Scoring**: All angle calculations and scoring happen locally. The final posture score, angle, severity classification, and the ear/shoulder coordinates used for the calculation are saved locally on-device.

## Third-Party Services

The App does **not** use any third-party analytics, advertising, or tracking services.

### Google ML Kit (Pose Detection)

Google ML Kit is used for on-device pose detection. All pose detection inference (analyzing images to detect body landmarks) runs **entirely on-device**. **No user photos, images, face data, landmark coordinates, or personal information are sent to Google.**

However, as disclosed in [Google's ML Kit Terms](https://developers.google.com/ml-kit/terms), the ML Kit SDK may send **anonymous SDK usage diagnostics** to Google, including:

- SDK performance metrics (e.g., detection speed, API call frequency)
- Device information (e.g., device model, OS version)
- Error codes and crash diagnostics related to the SDK itself

This diagnostic data is:
- **Anonymous** — it does not contain any user-identifiable information
- **Not user content** — no photos, images, landmark data, or posture scores are included
- **Encrypted in transit** via HTTPS
- **Not shared with third parties** by Google, per their terms

This telemetry is a standard component of Google's ML Kit SDK and cannot be disabled independently. It is used by Google solely to maintain, improve, and debug the ML Kit APIs.

## Data Storage

- **Photos, posture history, and landmark coordinates**: Stored locally using Apple's SwiftData framework in the App's sandboxed container. This includes the side-profile photo, posture score, craniovertebral angle, severity, and the ear and shoulder landmark coordinates for each posture check.
- **User preferences**: Stored locally using Apple's UserDefaults.
- **No cloud storage**: The App has no server, database, or cloud storage component.

## Data Sharing

The App does **not** share any user photos, face data, landmark coordinates, posture scores, or personal information with any third party. The only data that may leave your device is the anonymous SDK usage diagnostics sent by the Google ML Kit library as described in the Third-Party Services section above. These diagnostics contain no user-identifiable information or user content.

## Data Retention

- **Ear and shoulder landmark coordinates**: Stored locally on-device alongside each posture check photo for as long as the photo exists. Deleted when you delete the associated posture check photo or uninstall the App.
- **Eye, nose, and hip landmark coordinates**: Not retained. These exist only in temporary memory during the active posture analysis and are discarded immediately after the calculation completes. They are never written to disk.
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
