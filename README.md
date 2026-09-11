# Farm Estates Flutter UI

Cross-platform Flutter application for Farm Estates operations. The app provides role-based workflows for super administrators, administrators, farm managers, farm owners, caretakers, technicians, sales teams, accountants, fulfillment teams, packaging supervisors, and quality assurance users.

## Features

- Role-based dashboards and navigation
- Farm, crop, inventory, delivery, pricing, finance, and reporting workflows
- Real-time sensor telemetry, range settings, online/offline status, and diagnostics
- Tasks, notifications, messaging, audit logs, backups, and system configuration
- Responsive desktop, web, and Android layouts
- Skeleton loading states and backend-driven data

## Stack

- Flutter and Dart
- `http` for API communication
- FastAPI backend with Appwrite persistence
- `fl_chart` and Flutter Material components for dashboards

## Local setup

```powershell
cd farm_flutter_ui
flutter pub get
```

The production Android build uses `https://api-5u45d.ondigitalocean.app` by default. Override the value for local development with `--dart-define=API_BASE_URL=...`. Use `http://127.0.0.1:8000` for local web development and `http://10.0.2.2:8000` for an Android Emulator.

Run the application:

```powershell
flutter run
```

Run the web build:

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://api-5u45d.ondigitalocean.app
```

Do not commit `.env` files, API keys, Appwrite keys, or other credentials.

## Project structure

```text
lib/
  core/       Shared services, navigation, themes, and widgets
  models/     Data models
  screens/    Role-specific screens
  services/   API and backend integrations
  widgets/    Reusable UI components
```

## Related repository

The backend is maintained at [farm_appwrite_api](https://github.com/Philippo20/farm_appwrite_api).
# Password recovery app handoff

After a successful reset, Android and Windows browsers offer **Open Farm Estates
app** and **Continue on web**. Opening the app requires a user click because
browsers restrict external app launches after asynchronous requests. Android
uses an intent with a browser fallback; Windows uses `farmestates://app/login`.
The page falls back to web sign-in after three seconds. No reset credentials
are included in the app link.

Deploy the web build and distribute the updated Android/Windows builds. Android
registers the link on installation. Open the updated Windows build once to
register the per-user protocol handler (no administrator access required).
Existing older app builds cannot handle the link. Other browser platforms
continue with web sign-in. Browser prompts and installed-app detection remain
controlled by the browser and operating system.
