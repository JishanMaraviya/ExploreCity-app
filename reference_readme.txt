<div align="center">

# 🚀 Resify

### AI-Powered Resume Builder — Built with Flutter & Google Gemini

*A modern, highly responsive Flutter application that leverages Google Gemini AI to help professionals craft perfect, ATS-optimized resumes in minutes.*

<br/>

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![GetX](https://img.shields.io/badge/GetX-8A2BE2?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Google Gemini](https://img.shields.io/badge/Google%20Gemini-4285F4?style=for-the-badge&logo=google&logoColor=white)

![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-blue?style=flat-square)
![Architecture](https://img.shields.io/badge/Architecture-MVC%20(GetX)-orange?style=flat-square)
![Status](https://img.shields.io/badge/Status-Active-brightgreen?style=flat-square)

</div>

---

## 📖 Overview

**Resify** takes a simple text prompt and generates a complete, structured resume with impactful, industry-ready bullet points — powered entirely by **Google Gemini AI**. Users can select from multiple professional templates, preview the output natively inside the app, and export it as a high-quality PDF — all in just a few minutes.

---

## 🌟 Key Features

- **🤖 AI Resume Generation** — Write a brief prompt about your field, and the Gemini AI engine generates a fully structured, industry-standard resume.
- **🎨 Template Variety** — Choose from multiple polished themes (Modern, Classic, Grid, Minimal, Creative, Executive) that automatically adjust layout based on your data.
- **✏️ Dynamic Editor** — A multi-step form editor that allows manual overriding and tweaking of AI-generated content (Personal Info, Experience, Skills, Projects, etc.).
- **📄 Real-time PDF Preview** — Natively rasterizes the generated PDF inside the app for a crisp, real-time preview before exporting.
- **☁️ Dashboard & Cloud Sync** — Firebase integration ensures your resumes and personal data are securely backed up and accessible across devices.
- **🔐 Authentication** — Built-in email verification and secure login flow via Firebase Auth.

---

## 🛠️ Tech Stack

| Layer                         | Technology                                             |
|--------------------------------|---------------------------------------------------------|
| Framework                     | Flutter & Dart                                         |
| Architecture & State Mgmt     | MVC Pattern using **GetX** (Routing, State, DI)        |
| API Integration & Networking  | Custom REST API via `http` (HTTP POST, JSON Parsing)   |
| Backend as a Service (BaaS)   | Firebase (Firestore for DB, Authentication)            |
| AI Engine                     | Google Gemini 2.5 Flash API (Direct REST Integration)  |
| PDF Engine                    | `pdf` (creation) & `printing` (rasterization & export) |
| Security & Environment        | `flutter_dotenv` for secure environment variables      |

---

## 📂 Project Structure

```
lib/
│
├── controllers/          # GetX Controllers (Business logic & State)
│   ├── auth_controller.dart
│   └── resume_controller.dart
│
├── core/                 # Core utilities, constants, and external services
│   ├── constants/        # AppColors, AppTextStyles
│   └── services/         # GeminiService, PdfService
│
├── models/               # Data structures (ResumeModel, ChatMessage)
│
├── views/                # UI Screens grouped by feature
│   ├── auth/             # Login, Register, Verify Email
│   ├── create_resume/    # AI Input chat, Multi-step manual form editor
│   ├── dashboard/        # Main hub, saved resumes list
│   ├── preview/          # PDF visual preview
│   ├── settings/         # Profile, Edit Profile, Privacy Policy
│   └── templates/        # Resume template selector
│
└── widgets/              # Reusable customized UI components
    ├── custom_button.dart
    ├── custom_textfield.dart
    └── resume_card.dart
```

---

## 🖼️ App Screenshots

### Splash Screen & Authentication

<table>
  <tr>
    <td align="center"><b>Splash Screen</b></td>
    <td align="center"><b>Login</b></td>
    <td align="center"><b>Sign Up</b></td>
  </tr>
  <tr>
    <td><img src="Resify Screenshots/SpleshScreen.png" width="260"/></td>
    <td><img src="Resify Screenshots/login.png" width="260"/></td>
    <td><img src="Resify Screenshots/Signup.png" width="260"/></td>
  </tr>
  <tr>
    <td align="center"><b>Email Verification</b></td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td><img src="Resify Screenshots/verify.png" width="260"/></td>
    <td></td>
    <td></td>
  </tr>
</table>

### Dashboard & Templates

<table>
  <tr>
    <td align="center"><b>Home / Dashboard</b></td>
    <td align="center"><b>Select Template</b></td>
    <td align="center"><b>User Profile</b></td>
  </tr>
  <tr>
    <td><img src="Resify Screenshots/HomePage.png" width="260"/></td>
    <td><img src="Resify Screenshots/SelectTemplate.png" width="260"/></td>
    <td><img src="Resify Screenshots/userProfile.png" width="260"/></td>
  </tr>
</table>

### AI Generation & Resume Editing

<table>
  <tr>
    <td align="center"><b>AI Prompt Page</b></td>
    <td align="center"><b>Input Process</b></td>
    <td align="center"><b>Generated Resume</b></td>
  </tr>
  <tr>
    <td><img src="Resify Screenshots/proptPage.png" width="260"/></td>
    <td><img src="Resify Screenshots/inputProcess.png" width="260"/></td>
    <td><img src="Resify Screenshots/GenerateResume.png" width="260"/></td>
  </tr>
  <tr>
    <td align="center"><b>Edit Resume — Step 1</b></td>
    <td align="center"><b>Edit Resume — Step 2</b></td>
    <td></td>
  </tr>
  <tr>
    <td><img src="Resify Screenshots/EditResume1.png" width="260"/></td>
    <td><img src="Resify Screenshots/EditResume2.png" width="260"/></td>
    <td></td>
  </tr>
</table>

> 💡 **Note:** Screenshots are loaded from the `Resify Screenshots/` folder in this repository. Ensure the folder is committed at the repo root for images to render correctly on GitHub.

---

## 🚀 Installation & Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/MohibKhorajiya01/Resify-App.git
   cd Resify-App
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment Setup**

   Create a `.env` file in the root directory and add your Google Gemini API key:
   ```env
   GEMINI_API_KEY=your_gemini_api_key_here
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

---

## 🗺️ Roadmap

- [ ] Multi-language resume generation support
- [ ] Cover letter generator using Gemini AI
- [ ] More resume templates (Industry-specific designs)
- [ ] Resume scoring & ATS compatibility checker
- [ ] Offline draft saving

---

<div align="center">

### 💜 Built with passion using Flutter & Google Gemini AI

**Resify** — *Your career story, written by AI, perfected by you.*

</div>
