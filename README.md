# Audoria 📚🎙️

**An educational and accessibility-focused mobile application for visually impaired children**

Audoria transforms traditional learning materials into accessible, interactive experiences through AI-powered text-to-speech, voice navigation, and intelligent content processing.

---

## 🌟 Overview

Audoria bridges the gap between standard educational content and accessible learning for visually impaired children. The app converts documents, images, and PDFs into audio-friendly formats, enables hands-free navigation through voice commands, and provides AI-powered learning tools including summarization, quiz generation, and conversational Q&A.

---

## ✨ Key Features

### For Children 👶
- **🎤 Voice-First Navigation**: Control the entire app using voice commands
- **📖 Audio Learning**: Listen to lessons, summaries, and quiz questions
- **📷 Camera Capture**: Take photos of documents and convert them to accessible text
- **🤖 AI Assistant**: Ask questions and get instant answers
- **📝 Interactive Quizzes**: Practice with AI-generated quizzes from lesson content
- **📚 Saved Lessons**: Access all materials shared by parents in one place

### For Parents 👨‍👩‍👧
- **📤 File Management**: Upload and share lesson files (PDF, DOC, PPT, images, audio, video)
- **👥 Child Accounts**: Create and manage multiple child profiles
- **📊 Progress Insights**: Track quiz performance and learning progress
- **🔐 Secure Login**: QR code-based authentication for easy child access
- **📈 Analytics Dashboard**: View aggregated statistics and recent activity

---

## 🛠️ Technology Stack

### Frontend
- **Flutter** (Dart SDK ^3.9.2)
- **Material Design** with custom accessibility-focused UI components

### Backend & Services
- **Firebase Authentication** - Email/password and custom token authentication
- **Cloud Firestore** - Real-time database for files, insights, and user data
- **Firebase Cloud Functions** - Secure child account creation and QR token management

### AI & ML
- **Google Gemini API** (gemini-2.5-flash) - Summarization, quiz generation, Q&A
- **Google ML Kit Text Recognition** - On-device OCR for images and PDFs

### Voice & Audio
- **Flutter TTS** - Text-to-speech for all content
- **Speech to Text** - Voice command recognition and Q&A input

### Key Packages
- `camera` - Document capture
- `file_picker` - File upload
- `pdfx` - PDF processing
- `mobile_scanner` - QR code scanning
- `lottie` - Animations
- `permission_handler` - Camera and microphone permissions

---

## 📋 Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK (3.9.2 or higher)
- Firebase project with:
  - Authentication enabled
  - Firestore database configured
  - Cloud Functions deployed (for child account management)
- Google Gemini API key
- Android Studio / Xcode (for mobile development)
- Physical device or emulator for testing

---

## 🚀 Installation

### 1. Clone the Repository
```bash
git clone <repository-url>
cd Audoria
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup

#### Android
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/`

#### iOS
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place it in `ios/Runner/`

### 4. Environment Configuration

Create a `.env` file in the root directory:
```env
GEMINI_API_KEY=your_gemini_api_key_here
```

### 5. Firebase Cloud Functions

Deploy the required Cloud Functions:
- `createChildAccount` - Creates child accounts securely
- `generateChildLoginToken` - Generates QR login tokens
- `validateQRToken` - Validates QR tokens for child login

### 6. Run the App
```bash
flutter run
```

---

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── routes.dart               # Navigation routes
├── constants.dart            # App constants (colors, etc.)
│
├── screens/
│   ├── child_screens/        # Child user interface
│   │   ├── child_home_screen.dart
│   │   ├── saved_files_screen.dart
│   │   ├── single_file_screen.dart
│   │   ├── camera_capture_screen.dart
│   │   ├── captured_image_screen.dart
│   │   ├── questions_screen.dart
│   │   ├── quizzes_screen.dart
│   │   └── summarization_screen.dart
│   │
│   ├── parent_screens/       # Parent user interface
│   │   ├── parent_home_screen.dart
│   │   ├── all_lessons_screen.dart
│   │   ├── insights_screen.dart
│   │   ├── add_child_screen.dart
│   │   └── parent_qr_screen.dart
│   │
│   ├── login_screen.dart
│   ├── register_screen.dart
│   └── splash_screen.dart
│
├── models/                   # Data models
│   ├── lesson_file_model.dart
│   ├── quiz_question_model.dart
│   ├── insights_model.dart
│   └── commands_model.dart
│
├── utils/
│   ├── ai_services/         # AI integration
│   │   ├── gemini.dart
│   │   └── text_extraction.dart
│   │
│   ├── backend_services/    # Firebase services
│   │   ├── firebase_helpers.dart
│   │   ├── firestore_file_service.dart
│   │   └── child_signup_helper.dart
│   │
│   ├── navigation_services/  # Voice navigation
│   │   ├── navigation_helper.dart
│   │   └── voice_navigation/
│   │
│   ├── voice_services/       # Voice processing
│   │   └── voice.dart
│   │
│   └── insights_service.dart
│
├── widgets/                  # Reusable UI components
│   ├── custom_appbar.dart
│   ├── custom_button.dart
│   ├── custom_card.dart
│   └── ...
│
└── data/                     # Static data
    ├── commands_data.dart
    └── parent_home_list.dart
```

---

## 🎯 Usage Guide

### For Parents

1. **Registration & Setup**
   - Register with email and password
   - Verify email address
   - Create child account(s) with basic information
   - Generate QR code for child login

2. **Uploading Lessons**
   - Navigate to "Files" from home screen
   - Tap the "+" button to upload files
   - Select file(s) from device (PDF, DOC, PPT, images, audio, video)
   - Choose which children to share with
   - Files are automatically processed for text extraction

3. **Viewing Insights**
   - Access "Insights" from home screen
   - View aggregated statistics (total quizzes, accuracy, etc.)
   - Review recent quiz sessions with scores and dates

### For Children

1. **Login**
   - Scan QR code displayed on parent's device
   - Automatic authentication and navigation to home

2. **Learning Flow**
   - **Access Lessons**: Say "saved files" or tap "LESSON" card
   - **Choose Action**: Select a lesson, then choose:
     - **Read File**: Listen to full content
     - **Summarization**: Get a concise summary
     - **Quizzes**: Practice with generated questions
   - **Ask Questions**: Use "ASK QUESTION" for AI assistance
   - **Capture Documents**: Use camera to convert physical materials

3. **Voice Commands**
   - "camera" → Open camera
   - "saved files" → View lessons
   - "questions" → Ask AI assistant
   - "summarize" → Generate summary
   - "quiz" → Create quiz

---

## 🔐 Security & Privacy

- **On-Device OCR**: Text recognition happens locally, images never leave the device
- **Secure Authentication**: Firebase Auth with email verification
- **QR Token System**: Time-limited tokens for child login
- **Parent-Child Linking**: Secure relationship management via Firestore
- **Data Privacy**: All user data stored securely in Firebase with proper access controls

---

## 🎨 Accessibility Features

- **Text-to-Speech**: All content read aloud with adjustable settings
- **Voice Navigation**: Complete app control via voice commands
- **High Contrast UI**: Large buttons, clear icons, readable fonts
- **Semantic Labels**: Screen reader compatibility
- **Audio Feedback**: Spoken guidance for all actions
- **Hands-Free Operation**: Minimal touch interaction required

---

## 📊 Data Flow

1. **File Upload**: Parent uploads → Text extraction → Storage in Firestore
2. **Child Access**: Child selects lesson → Options presented → Action chosen
3. **AI Processing**: Content sent to Gemini → Response generated → Audio output
4. **Progress Tracking**: Quiz completion → Insights saved → Parent dashboard updated

---

## 🐛 Known Limitations

- Firestore queries may require composite indexes (fallback sorting implemented)
- Large PDFs may take time to process
- Requires internet connection for AI features (Gemini API)
- Child account lookup scans all parents (optimization needed for scale)

---

## 🔮 Future Enhancements

- [ ] Offline mode for reading saved content
- [ ] Adjustable TTS speed and voice settings
- [ ] Multi-language support
- [ ] Advanced analytics and progress charts
- [ ] Teacher/school account types
- [ ] Topic extraction feature
- [ ] Adaptive quiz difficulty
- [ ] Haptic feedback for interactions

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 👥 Authors

- **Development Team** - *Malak Osama, Salma Mehrez, Rahma Ragab, Omar Mahmoud*

---

**Made with ❤️ for accessible education**
