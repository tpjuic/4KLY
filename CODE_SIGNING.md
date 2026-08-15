# Code Signing Configuration Guide

This guide explains how to configure code signing for 4Kly so the app can be distributed without macOS Gatekeeper warnings.

## Prerequisites

- An Apple Developer ID (free or paid Apple Developer Program membership)
- Xcode installed with your Apple ID signed in
- For distribution outside the App Store: a paid Apple Developer Program membership ($99/year) with a "Developer ID Application" certificate

## 1. Configure Code Signing in Xcode

1. Open `4Kly.xcodeproj` in Xcode
2. Select the **4Kly** project in the Navigator (left sidebar)
3. Select the **4Kly** target
4. Go to the **Signing & Capabilities** tab

## 2. Set the Development Team

1. In the **Signing & Capabilities** tab, locate the **Team** dropdown
2. Select your Apple Developer team from the dropdown
   - If you don't see your team, go to **Xcode → Settings → Accounts** and add your Apple ID
3. The team ID will be automatically applied to the project settings

## 3. Enable Automatic Code Signing

1. In the **Signing & Capabilities** tab, check the **Automatically manage signing** checkbox
2. Xcode will automatically:
   - Create and manage provisioning profiles
   - Select the appropriate signing certificate
   - Resolve signing issues when they arise
3. Verify that no signing errors appear in the status area below the checkbox

## 4. Verify the Signing Identity

After configuring the team and automatic signing:

1. Check that the **Signing Certificate** field shows a valid certificate (e.g., "Apple Development: your@email.com")
2. Check that the **Provisioning Profile** field shows "Xcode Managed Profile"
3. Build the project (⌘B) — a successful build confirms the signing identity is valid

To verify from the command line after building:

```bash
codesign --verify --deep --strict /path/to/4Kly.app
codesign -dv --verbose=4 /path/to/4Kly.app
```

## 5. Configure Developer ID Certificate for Distribution

For distributing 4Kly outside the Mac App Store (e.g., via GitHub DMG releases):

### Create a Developer ID Certificate

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/certificates/list)
2. Click the **+** button to create a new certificate
3. Select **Developer ID Application** under the "Software" section
4. Follow the prompts to upload a Certificate Signing Request (CSR)
5. Download and install the certificate by double-clicking it

### Switch to Developer ID Signing for Release

When building for distribution:

1. In Xcode, change the **Signing Certificate** to "Developer ID Application" (you may need to uncheck automatic signing temporarily for the Release configuration)
2. Alternatively, use `xcodebuild` with explicit signing:

```bash
xcodebuild archive \
  -project 4Kly.xcodeproj \
  -scheme 4Kly \
  -archivePath ./build/4Kly.xcarchive \
  CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAM_ID)" \
  DEVELOPMENT_TEAM="YOUR_TEAM_ID"
```

### Notarize the App

After archiving, notarize the app to avoid Gatekeeper warnings:

```bash
# Export the archive
xcodebuild -exportArchive \
  -archivePath ./build/4Kly.xcarchive \
  -exportPath ./build/export \
  -exportOptionsPlist ExportOptions.plist

# Submit for notarization
xcrun notarytool submit ./build/export/4Kly.app.zip \
  --apple-id "your@email.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "app-specific-password" \
  --wait

# Staple the notarization ticket
xcrun stapler staple ./build/export/4Kly.app
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "No signing certificate" error | Go to Xcode → Settings → Accounts → Manage Certificates and create a new certificate |
| "Provisioning profile" errors | Delete derived data (`~/Library/Developer/Xcode/DerivedData`) and re-open the project |
| Notarization rejected | Check the rejection log with `xcrun notarytool log <submission-id>` and fix any issues (hardened runtime, missing entitlements) |
| Gatekeeper still blocks app | Ensure you stapled the notarization ticket to the app before creating the DMG |

## Notes

- Code signing requires credentials specific to each developer — this cannot be automated in the repository
- For CI/CD pipelines, store certificates in GitHub Secrets and use `fastlane match` or manual keychain setup
- The app's entitlements file (`4Kly.entitlements`) is already configured with the necessary sandbox permissions
