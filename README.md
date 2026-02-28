MINDTRACK
# 🧠 MindTrack
### A Flutter Mood & Study Tracker App

> Track your mood, log your study hours, and build better habits — one day at a time.


https://github.com/user-attachments/assets/e12b4d77-ea3f-4c52-a631-c55ef757e76d


## 📱 Features

- **Daily Mood Logging** — Log how you're feeling (Happy 😊 / Neutral 😐 / Sad 😔)
- **Study Hour Tracking** — Record hours studied with optional journal notes
- **Daily Goal Progress** — Set a personal study goal and track real-time progress
- **Analytics Dashboard** — Weekly bar chart, mood pie chart & 35-day heatmap calendar
- **Smart Suggestions** — Personalized tips based on your mood and study performance
- **Achievement Badges** — 10 unlockable badges to reward consistency
- **Quote of the Day** — Rotating motivational quotes to keep you going
- **Edit & Delete Entries** — Full control over your logged history
- **100% Offline** — All data stored locally on your device

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **3.10.0 or higher**
- Dart **3.10.0+** (bundled with Flutter)
- Android Studio / VS Code with Flutter extension
- Android/iOS emulator or a physical device

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/mindtrack.git
   cd mindtrack
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

---

## 🗂️ Project Structure

```
mindtrack/
├── lib/
│   └── main.dart          # All application code
├── pubspec.yaml           # Dependencies & SDK constraints
├── android/               # Android platform files
├── ios/                   # iOS platform files
└── web/                   # Web platform files
```

---

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `shared_preferences` | ^2.2.2 | Local data persistence |
| `fl_chart` | ^0.68.0 | Bar charts & pie charts |

---

## 🏅 Achievement Badges

| Badge | Title | Unlock Condition |
|-------|-------|-----------------|
| 🌱 | First Step | Log your first entry |
| 🔥 | On Fire | Log 3 entries |
| ⭐ | Week Warrior | Log 7 entries |
| 🏆 | Champion | Log 20 entries |
| 📚 | Bookworm | Study 10 total hours |
| 🎓 | Scholar | Study 50 total hours |
| 😊 | Good Vibes | Log Happy mood 5 times |
| 🎯 | Goal Crusher | Meet daily goal 3 times |
| 🦉 | Night Owl | Log an entry after 9 PM |
| 🌅 | Early Bird | Log an entry before 7 AM |

---

## 🛠️ Troubleshooting

**`SharedPreferences` type not found**
```bash
flutter pub get
```

**`pubspec.yaml` has no SDK constraint**
```yaml
environment:
  sdk: '^3.10.0'
```

**Dart compiler exited unexpectedly**
```bash
flutter clean
flutter pub get
flutter run
```

---

## 🔮 Roadmap

- [ ] Dark mode support
- [ ] Cloud sync (Firebase)
- [ ] Push notification reminders
- [ ] Streak counter
- [ ] Export data as PDF
- [ ] Subject/tag-based logging
- [ ] Widget for home screen quick-logging

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

