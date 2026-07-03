# Gnanam

An intelligent, offline-first AI tutor application built for Indian students (grades 1-12) leveraging powerful on-device AI inference using Google's Gemma models via the `flutter_gemma` package.

**"Gnanam"** translates to "Knowledge", and the app acts as a personalized, privacy-first companion that tailors educational content to the student's level.

## ✨ Key Features

- **🧠 Offline On-Device AI**: Runs Gemma AI models entirely on your phone's hardware. Zero internet required after the initial setup. 100% privacy.
- **📚 Grade Adaptive Tiers**: Automatically adjusts the AI persona and difficulty based on the student's grade:
  - 🌟 **Spark** (Grades 1-4)
  - 🎓 **Scholar** (Grades 5-8)
  - 🦉 **Sage** (Grades 9-12)
- **💬 Conversational UI**: Premium chat interface with typing animations, beautiful message bubbles, and Material 3 design.
- **📝 Smart Markdown & Math**: Renders LaTeX equations natively with `flutter_math_fork` and parses complex markdown and code blocks.
- **📊 Progress Dashboard**: Track streaks, accuracy, study time, and mastery across different subjects.
- **📜 Chat History**: Automatically saves your sessions and allows you to bookmark important lessons for later review.
- **🎯 Interactive Quizzes**: The AI generates dynamic multiple-choice quizzes on the fly for any subject and grades them instantly!

## 🛠️ Tech Stack

- **Framework**: Flutter 3.x & Dart
- **AI Inference**: `flutter_gemma`
- **State Management**: Riverpod (`flutter_riverpod`)
- **Local Storage**: `sqflite` for chat history and progress tracking, `shared_preferences` for settings
- **Design System**: Material 3

## 📱 App Architecture & Screens

1. **Splash Screen**: Validates the presence of the on-device Gemma model, activates it, and prepares the `LlmService`.
2. **Onboarding**: Explains the offline nature and features of the app to new users.
3. **Grade Selection**: Sets the user's tier (Spark/Scholar/Sage) and initializes the specialized AI system prompt.
4. **Home (Chat Screen)**: The primary workspace for interacting with the AI tutor.
5. **Chat History**: Browse past sessions, grouped by date, with swipe-to-delete and bookmarking functionality.
6. **Progress Screen**: A comprehensive dashboard showing study streaks, subject-wise mastery, and a visual activity chart.
7. **Quiz Screen & Results**: A specialized flow for taking AI-generated practice tests and reviewing performance.
8. **Settings**: Hardware configuration, UI scaling, and cache management.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.x)
- Android Studio / Android SDK (API 26+)
- A physical Android device with at least 4-6GB of RAM (Recommended for on-device AI)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/GondelaPuneeth/Gnanam.git
   cd Gnanam
   ```

2. **Fetch Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the App**
   Connect your Android device via USB (with Developer Mode and USB Debugging enabled) and run:
   ```bash
   flutter run
   ```

> **Note on Initial Setup**: The app requires the Gemma GGUF model to function. The `flutter_gemma` setup handles loading the model. Ensure your device has enough storage space to accommodate the model file.

## 🗂️ Project Structure

```text
lib/
├── core/
│   ├── database/         # SQLite schema and data access
│   ├── security/         # Local data protection
│   └── errors/           # Exception handling
├── features/
│   ├── quiz/             # Quiz generation logic
│   └── vision/           # Camera sensing features
├── inference/
│   ├── llm_service.dart  # Core integration with flutter_gemma
│   └── chat_controller.dart
├── orchestrator/
│   └── agent_manager.dart # Task routing and intent classification
├── providers/            # Riverpod state management
├── screens/              # UI Views
├── theme/                # Material 3 styling
└── widgets/              # Reusable UI components (custom markdown, chat bubbles)
```

## 🛡️ Privacy by Design

Gnanam was built with student privacy as the #1 priority. Because all AI inference happens **on-device**:
- No chat logs are ever sent to the cloud.
- No PII (Personally Identifiable Information) leaves the phone.
- The app requires absolutely no internet connection to answer questions.