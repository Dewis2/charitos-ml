# Pastelería Charito’s Android App

Flutter Android-only app for managing bakery sales (`ventas`), production (`produccion`), waste (`merma`), and ML production recommendations (`predicciones`) stored in Firebase Firestore.

## Firebase setup

1. Create a Firebase Android app with package name `com.charitos.ml`.
2. Download `google-services.json` and place it at:

   ```text
   android/app/google-services.json
   ```

3. Install FlutterFire CLI and generate real Firebase options:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --platforms=android --out=lib/firebase_options.dart
   ```

   The checked-in `lib/firebase_options.dart` is a placeholder so the project structure is complete. Replace it with the generated file before running against Firebase.

4. Configure anonymous authentication in Firebase Authentication.
5. Create/allow Firestore collections: `ventas`, `produccion`, `merma`, and `predicciones`.

## Backend ML API

The backend base URL is configured in `lib/utils/app_config.dart`. The app sends a `POST /predict` request and expects a response like:

```json
{
  "recommendations": [
    {"product": "Concha", "recommendedQuantity": 120, "confidence": 0.87}
  ]
}
```

You can override the URL at build time:

```bash
flutter run --dart-define=BACKEND_BASE_URL=https://your-api.example.com
```

## Android only

This repository intentionally includes only the Android Flutter platform folder. No iOS setup is included.
