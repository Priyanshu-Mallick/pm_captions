# 🎬 PM Captions

AI Caption Generator for voiceover videos - Add captions to your videos instantly.

## 🚀 Overview

**PM Captions** is a comprehensive Flutter application designed to effortlessly generate and embed captions into your voiceover videos. Whether you are a content creator, marketer, or educator, this tool provides a seamless experience for adding stylized text to your videos, enhancing accessibility and viewer engagement.

## ✨ Features

- **Video Processing**: Seamlessly pick, preview, and process videos right from your gallery.
- **AI Caption Generation**: Automatically transcribe and generate accurate captions for spoken audio.
- **Customizable Styling**: Personalize your captions with various fonts, vibrant colors, and styles.
- **Smooth Animations**: Enjoy a polished, modern user interface with smooth transitions and dynamic loading states.
- **Local Storage**: Efficiently save your projects and preferences locally.
- **Easy Export & Share**: Render the final captioned video using FFmpeg, save it directly to your device gallery, or share it instantly with others.

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev/) (^3.7.0)
- **State/Dependency Management**: `provider`, `get_it`
- **Video Processing**: `ffmpeg_kit_flutter_new`, `video_player`
- **Networking**: `dio`, `connectivity_plus`
- **Local Storage**: `sqflite`, `shared_preferences`
- **UI & Animations**: `lottie`, `flutter_animate`, `google_fonts`, `shimmer`
- **Routing**: `go_router`

## 📦 Getting Started

### Prerequisites

- Flutter SDK
- Android Studio or Xcode (for emulation and building)

### Installation

1. **Clone the repository (or navigate to the project directory):**

   ```bash
   git clone <repository-url>
   cd pm_captions
   ```

2. **Install dependencies:**

   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

## 📱 Permissions

The app requires specific permissions to function correctly:

- **Storage/Photos**: Required to select videos for editing and to save the final exported video to your device gallery.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the project.
2. Create your feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

## 📄 License

This project is open-source and available under the standard MIT License.

---

_Created with ❤️ using Flutter by Priyanshu Mallick._
