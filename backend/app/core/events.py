import asyncio
from typing import Any, Callable, Dict, List
from pydantic import BaseModel
from enum import Enum

class EventType(str, Enum):
    APPLICATION_SUBMITTED = "APPLICATION_SUBMITTED"
    TASK_ASSIGNED = "TASK_ASSIGNED"
    TASK_COMPLETED = "TASK_COMPLETED"
    TASK_FAILED = "TASK_FAILED"
    WORKFLOW_PAUSED = "WORKFLOW_PAUSED"
    WORKFLOW_COMPLETED = "WORKFLOW_COMPLETED"

class Event(BaseModel):
    type: EventType
    application_id: str
    payload: Dict[str, Any]
    source_agent: str

class EventBus:
    def __init__(self):
        self._subscribers: Dict[EventType, List[Callable]] = {
            event_type: [] for event_type in EventType
        }
        self._queue: asyncio.Queue = asyncio.Queue()

    def subscribe(self, event_type: EventType, callback: Callable):
        self._subscribers[event_type].append(callback)

    async def publish(self, event: Event):
        await self._queue.put(event)

    async def _process_events(self):
        while True:
            event = await self._queue.get()
            callbacks = self._subscribers.get(event.type, [])
            for callback in callbacks:
                # Dispatch concurrently
                asyncio.create_task(callback(event))
            self._queue.task_done()

    def start(self):
        asyncio.create_task(self._process_events())

# Global event bus instance
event_bus = EventBus()
