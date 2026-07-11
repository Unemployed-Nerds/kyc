# KYCFlow — Flutter app

Customer onboarding flow and branch manager review dashboard for the KYCFlow AI backend.

## Screens

**Customer flow** (welcome → 4 steps):
1. Personal details (name, date of birth)
2. ID document capture (camera or gallery)
3. Live selfie with on-device ML Kit liveness challenges (center, head turns, smile)
4. Review and submit → live agent-pipeline progress → verdict (approved / manual review / rejected)

**Branch manager**: review queue with status and risk filters, application detail with evidence (document + selfie images, OCR data, compliance checks, risk score), and approve/reject override for escalated cases. Entry point is the "Branch staff" link on the welcome screen.

## Run

```bash
flutter pub get
flutter run
```

The API base URL defaults to `http://10.0.2.2:8000` on Android emulators and `http://localhost:8000` elsewhere. Point at a real device or server with:

```bash
flutter run --dart-define=API_BASE=http://192.168.1.10:8000
```

The backend must be running (see the repo root README). Cleartext HTTP is enabled on Android and local networking on iOS for development against the local server.

## Design

Tokens and rationale live in `DESIGN.md` and `PRODUCT.md` at the repo root. Colors are defined in `lib/theme/palette.dart`; typography (Instrument Sans + Instrument Serif) is bundled under `assets/fonts/`.

## Tests

```bash
flutter test                                        # widget + golden tests
flutter test --update-goldens test/screenshots_test.dart   # regenerate screen PNGs
```

Screen renders for design review are in `test/goldens/`.
