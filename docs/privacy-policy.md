---
layout: default
title: Privacy Policy
---

# Privacy Policy

**Effective Date: March 11, 2026**

Neck Hump Reset ("the App") is committed to protecting your privacy. This Privacy Policy explains how the App handles your information.

## Summary

**All data stays on your device.** The App does not collect, transmit, or store any personal data on external servers. There is no cloud component, no user accounts, and no analytics tracking.

## Data Collected

The App uses the following data, all of which is stored **locally on your device only**:

### Photos
- Side-profile photos taken during posture checks are stored on-device using Apple's SwiftData framework.
- Photos are **never** uploaded to any server or cloud service.
- You can delete your photos at any time from within the App.

### Posture Analysis Data
- Craniovertebral angle measurements, posture scores, and severity classifications are computed **entirely on-device** using Google ML Kit Pose Detection and Apple Vision.
- No analysis results are transmitted off your device.

### Personal Information
- Your name (if provided during onboarding) is stored locally using UserDefaults.
- Onboarding preferences (screen time habits, movement comfort level, exercise restrictions) are stored locally using UserDefaults.
- This information is used solely to personalize your in-app experience and **never** leaves your device.

## Data Processing

All data processing occurs **locally on your device**:

- **Pose Detection**: Google ML Kit's Accurate Pose Detector runs on-device. No images are sent to Google or any third party.
- **Body Segmentation**: Apple's Vision framework runs on-device for improved C7 vertebra estimation.
- **Posture Scoring**: All angle calculations and scoring happen locally.

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

All data remains on your device until you:
- Delete individual photos or records within the App
- Delete the App from your device (which removes all associated data)

## Children's Privacy

The App does not knowingly collect personal information from children under 13. Since all data is stored locally and never transmitted, no personal information of any user is collected by us.

## Camera Usage

The App requests camera access to take side-profile photos for posture analysis. The camera is used **only** for this purpose. Photos are processed on-device and are never uploaded or shared.

## Changes to This Policy

If this Privacy Policy is updated, the revised version will be posted on this page with an updated effective date.

## Contact

If you have questions about this Privacy Policy, please open an issue on the [GitHub repository](https://github.com/aryankhanna2004/Neck-Hump-Reset).
