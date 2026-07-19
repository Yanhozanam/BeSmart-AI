# BeSmart-AI

An offline AI tutor for Android — a private, on-device study companion that works with no internet connection required.

## What It Does

BeSmart-AI runs a quantized language model directly on a student's phone, giving instant AI tutoring support with no dependency on mobile data or Wi-Fi. It's built for students in low-connectivity or high-cost-data environments who still deserve access to AI-powered learning help.

## How It Works

- **Local AI Model:** Gemma 4 (E2B, ~2B effective parameters), quantized to GGUF format, chosen to balance capability with mobile hardware constraints.
- **Inference Engine:** The `llamafu` package runs the model entirely on-device — no network calls, no data leaving the phone.
- **Platform:** Flutter / Dart for the app, with native Android integration.

## Built With

Flutter · Dart · Android · Gemma 4 · GGUF · llamafu · On-device inference · GitHub Actions

## AI Tooling Used in Development

This project was built solo, using AI-assisted development tools to work efficiently around hardware constraints (development was done on a laptop with very limited usable RAM, relying on cloud CI for builds):

- **Codex** was used to review the Flutter/Dart code — helping catch issues and suggest improvements throughout development.
- Other AI-assisted tools (OpenCode) were used to help execute and iterate on code changes based on research and debugging done in parallel.

## Getting Started

```bash
flutter pub get
flutter run
```

## License

TBD
