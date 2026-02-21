from fastapi import APIRouter, Depends
from core.models import Task
from .deps import get_orchestrator

router = APIRouter()


@router.post("/run")
async def run_task(task: Task, orchestrator=Depends(get_orchestrator)):
    result = await orchestrator.run(
        task,
        max_iterations=3
    )
    return result


@router.get("/health")
async def health():
    return {"status": "ok"}