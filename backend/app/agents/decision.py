from typing import Any, Dict
import asyncio

from app.agents.base import BaseAgent
from app.core.coordinator import coordinator

class RiskAssessmentAgent(BaseAgent):
    def __init__(self):
        super().__init__("RiskAssessmentAgent")

    async def process(self, application_id: str, task_data: Dict[str, Any]) -> Dict[str, Any]:
        await asyncio.sleep(1)
        
        # Read the context from the coordinator to calculate risk
        workflow = coordinator.active_workflows.get(application_id, {})
        context = workflow.get("context", {})
        
        risk_score = 0
        
        aml_status = context.get("AMLAgent", {}).get("status")
        sanctions_status = context.get("SanctionsAgent", {}).get("status")
        pep_status = context.get("PEPAgent", {}).get("status")
        validation_status = context.get("ValidationAgent", {}).get("status")
        
        if aml_status == "POTENTIAL_MATCH": risk_score += 40
        if sanctions_status == "POTENTIAL_MATCH": risk_score += 50
        if validation_status == "MISMATCH": risk_score += 60
        
        if pep_status == "MATCH":
            classification = context.get("PEPAgent", {}).get("classification")
            if classification == "HIGH": risk_score += 30
            elif classification == "MEDIUM": risk_score += 20
            else: risk_score += 10
            
        return {
            "risk_score": min(risk_score, 100),
            "risk_level": "HIGH" if risk_score >= 50 else ("MEDIUM" if risk_score >= 20 else "LOW")
        }

class DecisionAgent(BaseAgent):
    def __init__(self):
        super().__init__("DecisionAgent")

    async def process(self, application_id: str, task_data: Dict[str, Any]) -> Dict[str, Any]:
        await asyncio.sleep(1)
        
        workflow = coordinator.active_workflows.get(application_id, {})
        context = workflow.get("context", {})
        
        risk_level = context.get("RiskAssessmentAgent", {}).get("risk_level", "UNKNOWN")
        
        if risk_level == "LOW":
            decision = "APPROVE"
            explanation = "Automated approval due to low risk score and all checks passing."
        elif risk_level == "MEDIUM":
            decision = "ESCALATE"
            explanation = "Escalated for manual review due to medium risk indicators."
        else:
            decision = "REJECT"
            explanation = "Automated rejection due to high risk score (potential AML/Sanctions hit)."
            
        return {
            "decision": decision,
            "explanation": explanation
        }
