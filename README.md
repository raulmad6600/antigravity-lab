# 🚀 Antigravity-Lab

Sistema de orquestación de agentes IA multi-etapa. Utiliza una cadena de agentes especializados (Planner → Coder → Reviewer) para transformar prompts en código revisado.

## 📦 Arquitectura

- **API**: FastAPI para receptar tareas
- **Orquestador**: Ejecuta workflow de 3 agentes
- **Agentes**: PlannerAgent, CoderAgent, ReviewerAgent
- **LLM**: Ollama (modelos locales de IA)

## 🛠️ Instalación

### Prerequisitos
- Python 3.11+
- Ollama instalado y corriendo localmente o en una máquina accesible

### Setup Local

1. **Clonar y entrar a directorio**
```bash
git clone https://github.com/raulmad6600/antigravity-lab.git
cd antigravity-lab
```

2. **Crear entorno virtual**
```bash
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate
```

3. **Instalar dependencias**
```bash
pip install -r requirements.txt
```

4. **Configurar variables de entorno**
```bash
cp .env.example .env
# Editar .env con la URL de Ollama si no es localhost
```

5. **Asegurar que Ollama esté corriendo**
```bash
# En otra terminal/máquina
ollama serve
# Y en otra terminal del mismo host
ollama pull llama3
```

6. **Ejecutar la API**
```bash
python run.py
```

La API estará disponible en `http://localhost:8000`

## 📡 Endpoints

### Health Check
```bash
curl http://localhost:8000/health
```

### Ejecutar tarea
```bash
curl -X POST http://localhost:8000/run \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Escribe una función Python que ordene un array"
  }'
```

## 🔄 Flujo de Trabajo Remoto (SSH)

1. **En tu máquina local**:
```bash
# Hacer cambios, commit y push
git add .
git commit -m "mejoras"
git push origin main
```

2. **En la máquina remota (via SSH)**:
```bash
ssh user@remote-host
cd ~/antigravity-lab
git pull origin main
# Reiniciar si estaba corriendo
# sudo systemctl restart antigravity-lab  (si está como servicio)
# O: python run.py  (si es manual)
```

3. **Pruebas**:
```bash
# Test endpoint
curl http://localhost:8000/health

# Test completo
curl -X POST http://localhost:8000/run \
  -H "Content-Type: application/json" \
  -d '{"prompt": "test"}'
```

## ⚙️ Configuración

Variables en `.env`:

| Variable | Default | Descripción |
|----------|---------|-------------|
| `DEBUG` | True | Modo debug |
| `OLLAMA_BASE_URL` | http://localhost:11434 | URL del servidor Ollama |
| `OLLAMA_MODEL` | llama3 | Modelo a usar |
| `HOST` | 0.0.0.0 | Host para la API |
| `PORT` | 8000 | Puerto de la API |
| `MAX_ITERATIONS` | 3 | Máximos intentos del reviewer |

## 🧪 Desarrollo

```bash
# Activar entorno
source venv/bin/activate

# Instalar en modo desarrollo
pip install -e .

# Correr con auto-reload
python run.py

# O directamente con uvicorn
uvicorn api.main:app --reload --host 0.0.0.0 --port 8000
```

## 📝 Estructura

```
api/
  ├── main.py          # Aplicación FastAPI
  ├── routes.py        # Rutas/endpoints
  ├── config.py        # Configuración
  └── deps.py          # Inyección de dependencias
core/
  ├── models.py        # Modelos Pydantic
  ├── agents/          # Agentes especializados
  │  ├── base.py
  │  ├── planner.py
  │  ├── coder.py
  │  └── reviewer.py
  └── llm/             # Adaptadores LLM
     ├── base.py
     └── ollama_adapter.py
```

## 🐛 Troubleshooting

**Error: Connection refused to Ollama**
- Verificar que Ollama está corriendo: `curl http://OLLAMA_HOST:11434`
- Actualizar `OLLAMA_BASE_URL` en `.env` con la URL correcta

**Error: Modelo no encontrado**
- Descargar el modelo: `ollama pull llama3`

**API no responde**
- Verificar logs: `python run.py` y revisar stderr
- Asegurar puerto 8000 no está en uso: `lsof -i :8000`
