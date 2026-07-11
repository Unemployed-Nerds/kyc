from abc import ABC, abstractmethod
from typing import Any, Dict
import logging

from app.core.events import event_bus, Event, EventType

logger = logging.getLogger(__name__)

class BaseAgent(ABC):
    def __init__(self, name: str):
        self.name = name

    async def initialize(self):
        """Called to setup the agent and subscribe to relevant events."""
        event_bus.subscribe(EventType.TASK_ASSIGNED, self._handle_task_assignment)
        logger.info(f"Agent {self.name} initialized.")

    async def _handle_task_assignment(self, event: Event):
        if event.payload.get("target_agent") != self.name:
            return
        
        logger.info(f"[{self.name}] Received task for application {event.application_id}")
        try:
            result = await self.process(event.application_id, event.payload.get("task_data", {}))
            
            await event_bus.publish(Event(
                type=EventType.TASK_COMPLETED,
                application_id=event.application_id,
                payload={"result": result, "agent": self.name},
                source_agent=self.name
            ))
            logger.info(f"[{self.name}] Completed task for application {event.application_id}")

        except Exception as e:
            logger.error(f"[{self.name}] Failed task for application {event.application_id}: {str(e)}")
            await event_bus.publish(Event(
                type=EventType.TASK_FAILED,
                application_id=event.application_id,
                payload={"error": str(e), "agent": self.name},
                source_agent=self.name
            ))

    @abstractmethod
    async def process(self, application_id: str, task_data: Dict[str, Any]) -> Dict[str, Any]:
        """The core logic of the specific agent."""
        pass
