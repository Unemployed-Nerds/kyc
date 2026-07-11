import logging
from typing import Dict, Any, List
import asyncio

from app.core.events import event_bus, Event, EventType

logger = logging.getLogger(__name__)

class CoordinatorAgent:
    def __init__(self):
        self.name = "Coordinator"
        # In-memory store for active applications. 
        # In a real app, this goes to DB/Redis.
        self.active_workflows: Dict[str, Dict[str, Any]] = {}

    def _add_log(self, app_id: str, msg: str):
        if app_id in self.active_workflows:
            import datetime
            ts = datetime.datetime.now().strftime("%H:%M:%S")
            self.active_workflows[app_id].setdefault("system_logs", []).append(f"[{ts}] {msg}")

    async def initialize(self):
        event_bus.subscribe(EventType.APPLICATION_SUBMITTED, self._handle_application_submitted)
        event_bus.subscribe(EventType.TASK_COMPLETED, self._handle_task_completed)
        event_bus.subscribe(EventType.TASK_FAILED, self._handle_task_failed)
        logger.info("Coordinator Agent initialized.")

    async def _handle_application_submitted(self, event: Event):
        app_id = event.application_id
        logger.info(f"[Coordinator] Starting workflow for application {app_id}")
        
        self.active_workflows[app_id] = {
            "status": "IN_PROGRESS",
            "completed_agents": [],
            "failed_agents": [],
            "context": event.payload,
            "system_logs": []
        }
        self._add_log(app_id, f"Started workflow for application {app_id}")
        
        # Determine the execution plan (e.g., run DocumentAgent first)
        await asyncio.gather(
            self._dispatch_task(app_id, "DocumentAgent", {"action": "verify_quality"}),
            self._dispatch_task(app_id, "SelfieAgent", {"action": "verify_selfie"})
        )

    async def _handle_task_completed(self, event: Event):
        app_id = event.application_id
        agent_name = event.payload.get("agent")
        result = event.payload.get("result")
        
        logger.info(f"[Coordinator] Agent {agent_name} completed task for app {app_id}")
        
        if app_id not in self.active_workflows:
            logger.warning(f"[Coordinator] App {app_id} not found in active workflows.")
            return

        workflow = self.active_workflows[app_id]
        workflow["completed_agents"].append(agent_name)
        self._add_log(app_id, f"Agent {agent_name} completed task.")
        
        # Merge result into context
        workflow["context"].update({agent_name: result})

        # Simple orchestration logic
        if agent_name in ["DocumentAgent", "SelfieAgent"]:
            if result.get("status") == "REJECTED":
                logger.warning(f"[Coordinator] {agent_name} rejected. Pausing workflow.")
                self._add_log(app_id, f"Workflow paused: {agent_name} rejected.")
                workflow["status"] = "PAUSED_AWAITING_USER"
                await event_bus.publish(Event(
                    type=EventType.WORKFLOW_PAUSED,
                    application_id=app_id,
                    payload={"reason": result.get("reason")},
                    source_agent=self.name
                ))
            else:
                completed = set(workflow["completed_agents"])
                if "DocumentAgent" in completed and "SelfieAgent" in completed:
                    if "OCRAgent" not in completed:
                        await self._dispatch_task(app_id, "OCRAgent", {"action": "extract"})
                    if "FaceMatchAgent" not in completed:
                        await self._dispatch_task(app_id, "FaceMatchAgent", {"action": "verify_match"})
                
        elif agent_name == "FaceMatchAgent":
            if result.get("status") == "MISMATCH":
                logger.warning(f"[Coordinator] Face match failed. Pausing workflow.")
                self._add_log(app_id, f"Workflow paused: Face match failed.")
                workflow["status"] = "PAUSED_AWAITING_USER"
                await event_bus.publish(Event(
                    type=EventType.WORKFLOW_PAUSED,
                    application_id=app_id,
                    payload={"reason": result.get("reason")},
                    source_agent=self.name
                ))
            else:
                # Same check as above in case FaceMatch finishes before OCR
                completed = set(workflow["completed_agents"])
                if "OCRAgent" in completed and "ValidationAgent" in completed:
                     await asyncio.gather(
                        self._dispatch_task(app_id, "AMLAgent", {"action": "check"}),
                        self._dispatch_task(app_id, "SanctionsAgent", {"action": "check"}),
                        self._dispatch_task(app_id, "PEPAgent", {"action": "check"})
                     )

        elif agent_name == "OCRAgent":
            # Trigger validation
            await self._dispatch_task(app_id, "ValidationAgent", {"action": "validate"})
            
        elif agent_name == "ValidationAgent":
            completed = set(workflow["completed_agents"])
            if "FaceMatchAgent" in completed:
                # Trigger parallel compliance agents
                await asyncio.gather(
                    self._dispatch_task(app_id, "AMLAgent", {"action": "check"}),
                    self._dispatch_task(app_id, "SanctionsAgent", {"action": "check"}),
                    self._dispatch_task(app_id, "PEPAgent", {"action": "check"})
                )
            
        elif agent_name in ["AMLAgent", "SanctionsAgent", "PEPAgent"]:
            # Check if all parallel agents finished
            required = {"AMLAgent", "SanctionsAgent", "PEPAgent"}
            completed = set(workflow["completed_agents"])
            
            if required.issubset(completed) and "ValidationAgent" in completed:
                await self._dispatch_task(app_id, "RiskAssessmentAgent", {"action": "calculate_risk"})
            
        elif agent_name == "RiskAssessmentAgent":
            await self._dispatch_task(app_id, "DecisionAgent", {"action": "make_decision"})
            
        elif agent_name == "DecisionAgent":
            workflow["status"] = "COMPLETED"
            self._add_log(app_id, f"Workflow completed. Final decision: {result.get('decision')}")
            logger.info(f"[Coordinator] Workflow completed for app {app_id}. Final decision: {result.get('decision')}")
            await event_bus.publish(Event(
                type=EventType.WORKFLOW_COMPLETED,
                application_id=app_id,
                payload={"decision": result},
                source_agent=self.name
            ))

    async def _handle_task_failed(self, event: Event):
        app_id = event.application_id
        agent_name = event.payload.get("agent")
        error = event.payload.get("error")
        logger.error(f"[Coordinator] Agent {agent_name} failed for app {app_id}: {error}")
        self._add_log(app_id, f"Agent {agent_name} failed: {error}")
        
        if app_id in self.active_workflows:
            self.active_workflows[app_id]["failed_agents"].append(agent_name)
            self.active_workflows[app_id]["status"] = "FAILED"

    async def _dispatch_task(self, application_id: str, target_agent: str, task_data: Dict[str, Any]):
        logger.info(f"[Coordinator] Dispatching task to {target_agent} for app {application_id}")
        self._add_log(application_id, f"Dispatching task to {target_agent}...")
        
        # Add workflow context to task_data
        context = self.active_workflows.get(application_id, {}).get("context", {})
        task_data["context"] = context
        
        await event_bus.publish(Event(
            type=EventType.TASK_ASSIGNED,
            application_id=application_id,
            payload={
                "target_agent": target_agent,
                "task_data": task_data
            },
            source_agent=self.name
        ))

coordinator = CoordinatorAgent()
