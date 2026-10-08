# Android APK updates

The sideloaded Android app checks the public HTTPS release feed on launch, on
return after at least 15 minutes, and every six hours while in the foreground:
`https://apps.farmestates.farm/downloads/android-release.json`.
Web, Windows and other platforms do not run this Android installer workflow.
Users of older builds must install the first APK containing this feature once.

A newer build shows an optional update sheet. **Download update** uses Android
DownloadManager, which continues while the app is suspended and shows a system
download notification. The sheet shows progress. **Install update** verifies
the file's length and SHA-256 hash, package ID, higher build number and signing
certificate before opening the Android installer. Android asks for approval;
the app does not silently install or force an update. When needed, it guides
the user to allow installation from Farm Estates in Android settings.

Closing the sheet does not stop a running download. Reopening the app restores
the download from Android's persisted state. Dismissing an update that has not
started snoozes that build for 24 hours. Feed failures never affect API
connectivity, sign-in or normal work. Install cancellation permits retry.

For every release:

1. Increment the build number in `pubspec.yaml`.
2. Run `scripts/prepare_android_download.ps1`. It builds the APK, copies it to
   `web/downloads/farm-estates.apk`, and generates `android-release.json` with
   verified APK version metadata and the hash of the copied file.
3. Commit the APK and JSON together and deploy the web build from that commit.
   Publish them atomically and serve the JSON with `Cache-Control: no-cache`.
   If staging an APK separately, run `scripts/write_android_release.ps1` after
   replacing the download. Never hand-edit the hash or advertise a future APK.
4. Keep the application ID and signing key unchanged. Installed apps cannot
   accept an APK signed by another key. Testing builds currently use the
   existing testing certificate; release signing needs a planned transition.

`UI_BASE_URL` selects the HTTPS release host for another deployment. APK URLs
must stay on that feed's origin under `/downloads/`. The feed and APK are
public artifacts and do not contain user data or service credentials.

This workflow is for direct APK distribution. A future Google Play build must
use Play's update mechanism and omit the sideload installation permission.
