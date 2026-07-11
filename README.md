# KYC Flow AI

An end-to-end autonomous AI Know Your Customer (KYC) system featuring a Flutter mobile frontend for capturing user data and a FastAPI backend powered by specialized AI agents.

## Features
- **Frontend (Flutter)**: 
  - Customer onboarding flow with ID upload and live selfie capture.
  - On-device ML Kit integration for real-time facial liveness checks (head tracking, smile detection).
  - Branch manager dashboard for manual reviews.
- **Backend (FastAPI)**:
  - Agentic workflow orchestration.
  - **OCRAgent**: Extracts details from government IDs using Google Gemini Vision.
  - **SelfieAgent**: Verifies single face presence in selfies.
  - **FaceMatchAgent**: Compares ID face against selfie.
  - **Compliance Agents**: Runs AML, Sanctions, and PEP checks.
  - **RiskAssessmentAgent**: Aggregates risk scores.
  - **DecisionAgent**: Makes automated approve/reject decisions or escalates for manual review.

## Setup Instructions

### Backend
1. Navigate to the `backend/` directory.
2. Create a virtual environment: `python -m venv venv`
3. Activate the environment: `source venv/bin/activate`
4. Install dependencies: `pip install -r requirements.txt`
5. Copy `.env.example` to `.env` and configure your API keys (e.g., `GEMINI_API_KEY`).
6. Run the server: `uvicorn app.main:app --port 8000 --reload`

### Frontend
1. Navigate to the `frontend/` directory.
2. Install dependencies: `flutter pub get`
3. Run the app: `flutter run`
