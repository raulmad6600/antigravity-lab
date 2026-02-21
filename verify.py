#!/usr/bin/env python3
"""Script de verificación del proyecto"""
import sys

print("✅ Verificando imports...")

# Verificar que todos los módulos se importan correctamente
from api.config import settings
from api.main import app
from api.routes import router
from api.deps import get_orchestrator

from core.models import Task, AgentContext, AgentResult
from core.agents.base import BaseAgent
from core.agents.planner import PlannerAgent
from core.agents.coder import CoderAgent
from core.agents.reviewer import ReviewerAgent

from core.llm.base import BaseLLM
from core.llm.ollama_adapter import OllamaAdapter

from core.orchestrator.engine import Orchestrator

print("✅ Todos los módulos importados correctamente!")
print(f"   - App name: {settings.app_name}")
print(f"   - Debug: {settings.debug}")
print(f"   - Ollama URL: {settings.ollama_base_url}")
print(f"   - Ollama Model: {settings.ollama_model}")
print(f"   - API Host: {settings.host}:{settings.port}")

# Verificar que FastAPI app está configurada  
print(f"\n✅ FastAPI app configurada con {len(app.routes)} rutas")
for route in app.routes:
    print(f"   - {route.path} ({route.methods if hasattr(route, 'methods') else 'N/A'})")
