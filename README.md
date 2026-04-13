# VidyaSetu 🎓

VidyaSetu is a smart learning companion designed to help students organize their studies with AI-powered timetables, focus modes, and mentor connections.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (Latest Stable)
- Android Studio / Xcode
- A Firebase Project

### 🔑 Security & Configuration
For security reasons, project-specific secrets and Firebase configurations are **not** included in this repository. To run the app locally, you must provide your own configuration files:

1. **Firebase (Android)**: Place your `google-services.json` in `android/app/`.
2. **Firebase (iOS)**: Place your `GoogleService-Info.plist` in `ios/Runner/`.
3. **Environment Variables**: Create a `.env` file in the root directory with the following keys:
   ```env
   # API Keys for AI & Services
   GEMINI_API_KEY=your_key_here
   ```

## 🛠️ Development Tools
Developer scripts and utility tools are located in the `scripts/dev/` directory.

## 📜 License
This project is for educational purposes.
