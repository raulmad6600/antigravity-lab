from pydantic import BaseModel
from typing import Optional, Dict, Any


class Task(BaseModel):
    prompt: str
    metadata: Optional[Dict[str, Any]] = None


class AgentContext(BaseModel):
    task: Task
    memory: Optional[Dict[str, Any]] = None
    intermediate: Optional[Dict[str, Any]] = None


class AgentResult(BaseModel):
    output: str
    status: str  # "PASS" | "FAIL" | "CONTINUE"
    metadata: Optional[Dict[str, Any]] = None