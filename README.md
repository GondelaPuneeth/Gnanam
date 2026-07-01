# GemmaEdge

An offline AI tutor app for Indian students (grades 1-12) using on-device Gemma 2-2B GGUF models via the `llama_cpp_dart` package.

## Features

- **Offline First**: Works completely without internet connection
- **Grade Adaptive**: Tailored content for Spark (1-4), Scholar (5-8), and Sage (9-12) tiers
- **Beautiful UI**: Premium chat interface with Material 3 design
- **Math Rendering**: LaTeX equations with `flutter_math_fork`
- **Markdown Support**: Rich text formatting with custom markdown rendering
- **Code Highlighting**: Syntax highlighting for multiple programming languages
- **Voice Input**: Speech-to-text capabilities
- **OCR**: Text recognition from images

## Tech Stack

- Flutter 3.x
- Dart
- Material 3
- Riverpod for state management
- llama_cpp_dart for model inference

## Screens

1. **Splash Screen**: Loading indicator while model initializes
2. **Onboarding**: Introduction to app features
3. **Grade Selection**: Choose your grade level
4. **Home/Chat**: Main chat interface with AI tutor
5. **Drawer Menu**: Navigation to other sections
6. **Settings**: App configuration

## UI Components

- Custom markdown rendering with LaTeX support
- Streaming token animation
- Beautiful message bubbles
- Responsive design for Android phones (4-6 GB RAM)

## Installation

1. Clone the repository
2. Run `flutter pub get`
3. Connect an Android device or start an emulator
4. Run `flutter run`

## Dependencies

All dependencies are listed in `pubspec.yaml`:

- flutter_riverpod: ^2.6.1
- flutter_markdown: ^0.7.4
- flutter_math_fork: ^0.7.2
- flutter_highlight: ^0.7.0
- google_fonts: ^6.2.1
- flutter_animate: ^4.5.0
- shared_preferences: ^2.3.3
- And more...

## Project Structure

```
lib/
├── app.dart
├── main.dart
├── models/
│   └── chat_message.dart
├── providers/
│   ├── grade_provider.dart
│   └── theme_provider.dart
├── screens/
│   ├── drawer_menu.dart
│   ├── grade_selection_screen.dart
│   ├── home_screen.dart
│   ├── onboarding_screen.dart
│   ├── settings_screen.dart
│   └── splash_screen.dart
├── theme/
│   ├── app_theme.dart
│   └── theme_notifier.dart
└── widgets/
    ├── chat_message.dart
    └── custom_markdown.dart
```

## Development

This is the LITE version — pure Dart, no NDK, no C++ custom code.

## Requirements

- Android API 26+ (Android 8+)
- Minimum 4GB RAM device recommended

## Future Enhancements

- Integration with actual llama_cpp_dart model
- Advanced OCR capabilities
- Progress tracking and analytics
- Practice tests and quizzes
- Saved lessons and bookmarks