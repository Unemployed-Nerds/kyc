import asyncio
from fastapi import FastAPI, BackgroundTasks, HTTPException, File, UploadFile, Form
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
import uuid
import os
import shutil
from dotenv import load_dotenv

load_dotenv()

from app.core.events import event_bus, Event, EventType
from app.core.coordinator import coordinator
from app.agents.document import DocumentAgent, OCRAgent, ValidationAgent, SelfieAgent, FaceMatchAgent
from app.agents.compliance import AMLAgent, SanctionsAgent, PEPAgent
from app.agents.decision import RiskAssessmentAgent, DecisionAgent

app = FastAPI(title="KYCFlow AI API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Initialize Agents
agents = [
    DocumentAgent(),
    SelfieAgent(),
    FaceMatchAgent(),
    OCRAgent(),
    ValidationAgent(),
    AMLAgent(),
    SanctionsAgent(),
    PEPAgent(),
    RiskAssessmentAgent(),
    DecisionAgent()
]

@app.on_event("startup")
async def startup_event():
    event_bus.start()
    await coordinator.initialize()
    for agent in agents:
        await agent.initialize()

@app.post("/api/kyc/apply")
async def submit_application(
    background_tasks: BackgroundTasks,
    first_name: str = Form("John"),
    last_name: str = Form(""),
    dob: str = Form("1990-01-01"),
    document: UploadFile = File(None),
    selfie: UploadFile = File(None)
):
    application_id = str(uuid.uuid4())
    
    payload = {
        "customer_data": {
            "first_name": first_name,
            "last_name": last_name,
            "dob": dob
        },
        "files": {}
    }
    
    if document and selfie:
        os.makedirs(f"uploads/{application_id}", exist_ok=True)
        doc_path = f"uploads/{application_id}/doc_{document.filename}"
        selfie_path = f"uploads/{application_id}/selfie_{selfie.filename}"
        
        with open(doc_path, "wb") as f:
            shutil.copyfileobj(document.file, f)
        with open(selfie_path, "wb") as f:
            shutil.copyfileobj(selfie.file, f)
            
        payload["files"]["document_path"] = doc_path
        payload["files"]["selfie_path"] = selfie_path
    
    # We publish the event and let the coordinator pick it up
    background_tasks.add_task(
        event_bus.publish, 
        Event(
            type=EventType.APPLICATION_SUBMITTED,
            application_id=application_id,
            payload=payload,
            source_agent="API"
        )
    )
    
    return {"application_id": application_id, "status": "SUBMITTED"}

@app.post("/api/kyc/liveness")
async def check_liveness(frame: UploadFile = File(...)):
    # Check liveness using Gemini
    try:
        if os.environ.get("GEMINI_API_KEY"):
            from google import genai
            import json
            client = genai.Client()
            temp_path = f"uploads/temp_{uuid.uuid4()}_{frame.filename}"
            with open(temp_path, "wb") as f:
                shutil.copyfileobj(frame.file, f)
            
            myfile = await client.aio.files.upload(file=temp_path)
            response = await client.aio.models.generate_content(
                model='gemini-3.5-flash',
                contents=[myfile, "Analyze this image. Is there a clear, single, REAL human face visible? Make sure it is a real person and not a photo of a photo, a screen, a drawing, or an AI generated image. Reply with ONLY JSON: {\"is_live\": true/false, \"reason\": \"<reason>\"}"]
            )
            os.remove(temp_path)
            
            cleaned = response.text.replace('```json', '').replace('```', '').strip()
            return json.loads(cleaned)
    except Exception as e:
        print(f"Liveness error: {e}")
        return {"is_live": False, "reason": "Failed to analyze liveness."}

    return {"is_live": False, "reason": "Gemini API key missing."}

@app.get("/api/kyc/{application_id}/status")
async def get_status(application_id: str):
    workflow = coordinator.active_workflows.get(application_id)
    if not workflow:
        raise HTTPException(status_code=404, detail="Application not found")
        
    return {
        "application_id": application_id,
        "status": workflow["status"],
        "completed_agents": workflow["completed_agents"],
        "failed_agents": workflow["failed_agents"],
        "decision": workflow["context"].get("DecisionAgent", {}).get("decision"),
        "context": workflow["context"],
        "system_logs": workflow.get("system_logs", [])
    }

@app.post("/api/kyc/{application_id}/review")
async def review_application(application_id: str, decision: str = Form(...)):
    workflow = coordinator.active_workflows.get(application_id)
    if not workflow:
        raise HTTPException(status_code=404, detail="Application not found")
        
    workflow["status"] = "COMPLETED"
    workflow["context"]["DecisionAgent"] = {
        "decision": decision,
        "explanation": "Manual override by Branch Manager."
    }
    
    return {"status": "success"}

@app.get("/api/kyc/applications")
async def list_applications():
    # For branch manager dashboard
    return [
        {
            "application_id": app_id,
            "status": data["status"],
            "risk_level": data["context"].get("RiskAssessmentAgent", {}).get("risk_level", "PENDING"),
            "document_path": data["context"].get("files", {}).get("document_path")
        }
        for app_id, data in coordinator.active_workflows.items()
    ]
