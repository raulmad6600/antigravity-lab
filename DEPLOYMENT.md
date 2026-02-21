# 📋 Workflow de Deployment - Antigravity-Lab

## Resumen del Proyecto

**Antigravity-Lab** es un sistema de orquestación de agentes IA que implementa un flujo multi-etapa:

```
Prompt (Tarea) 
    ↓
[PLANNER AGENT] → Crea un plan técnico
    ↓
[CODER AGENT] → Implementa basado en el plan
    ↓
[REVIEWER AGENT] → Revisa el código
    ↓
¿PASS? → SI → Retorna resultado final
        → NO → Reintentar (máx 3 iteraciones)
```

### Tecnología
- **API**: FastAPI (Python web framework)
- **LLM**: Ollama (modelos locales de IA)
- **Async**: asyncio para ejecución asincrónica
- **Validación**: Pydantic para modelos de datos

---

## 🔄 Flujo de Desarrollo: Local → GitHub → Remoto

### 1️⃣ **En tu máquina local** (donde estás ahora)

```bash
# Hacer cambios en el código
nano core/agents/coder.py  # Por ejemplo

# Verificar que no hay errores
./venv/bin/python verify.py

# Probar sin Ollama (mock)
./venv/bin/python test_mock.py

# Hacer commit
git add .
git commit -m "✨ Mi cambio descriptivo"

# Hacer push a GitHub
git push origin main
```

---

### 2️⃣ **En la máquina remota** (via SSH)

#### Primera vez (Setup inicial):

```bash
# SSH a la máquina remota
ssh user@remote-host

# Clonar repositorio
git clone https://github.com/raulmad6600/antigravity-lab.git
cd antigravity-lab

# O usar el script de deployment
bash deploy.sh localhost  # Si usas en local

# O para remoto:
bash deploy.sh remote-host user 22
```

#### Setup manual (si no usas deploy.sh):

```bash
# En la máquina remota

# 1. Crear entorno virtual
python3 -m venv venv
source venv/bin/activate

# 2. Instalar dependencias
pip install -r requirements.txt

# 3. Configurar Ollama (en el mismo host o diferente)
# Si Ollama está en otra máquina, actualizar .env:
nano .env
# Cambiar: OLLAMA_BASE_URL=http://otra-maquina:11434

# 4. Para pruebas sin Ollama:
python test_mock.py
```

#### Actualizaciones posteriores:

```bash
# En la máquina remota, simplemente:
cd ~/antigravity-lab
git pull origin main
source venv/bin/activate

# Si hay cambios en requirements.txt:
pip install -r requirements.txt

# Luego reiniciar la API si está corriendo
```

---

### 3️⃣ **Ejecutar la API**

#### Opción A: Ejecución manual

```bash
# En la máquina remota
cd ~/antigravity-lab
source venv/bin/activate
python run.py

# La API estará en http://0.0.0.0:8000
```

#### Opción B: Como servicio systemd

```bash
# Crear archivo de servicio
sudo nano /etc/systemd/system/antigravity.service
```

```ini
[Unit]
Description=Antigravity Lab API
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/antigravity-lab
ExecStart=/home/ubuntu/antigravity-lab/venv/bin/python /home/ubuntu/antigravity-lab/run.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
# Activar servicio
sudo systemctl daemon-reload
sudo systemctl enable antigravity
sudo systemctl start antigravity

# Ver logs
sudo systemctl status antigravity
sudo journalctl -u antigravity -f
```

---

## 🧪 Pruebas

### Test 1: Verificación básica
```bash
cd ~/antigravity-lab
source venv/bin/activate
python verify.py
```

### Test 2: Mock (sin Ollama)
```bash
python test_mock.py
```

### Test 3: Health check de la API
```bash
curl http://localhost:8000/health
```

### Test 4: Ejecutar tarea real

```bash
curl -X POST http://localhost:8000/run \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Write a Python function that sorts a list"
  }'
```

---

## ⚙️ Configuración

Archivo: `.env`

```env
# DEBUG Mode
DEBUG=True

# Ollama
OLLAMA_BASE_URL=http://localhost:11434    # Cambiar si Ollama está remoto
OLLAMA_MODEL=llama3

# API
HOST=0.0.0.0
PORT=8000
MAX_ITERATIONS=3
```

**⚠️ IMPORTANTE**: Si Ollama está en otra máquina:

```env
# Ejemplo: Ollama en máquina 192.168.1.100
OLLAMA_BASE_URL=http://192.168.1.100:11434
```

---

## 🐛 Troubleshooting

### Error: "Connection refused" a Ollama

```bash
# Verificar que Ollama está corriendo
curl http://OLLAMA_HOST:11434/api/tags

# Si usa Docker:
docker ps | grep ollama
docker logs ollama

# Si es local, asegurar que se ejecuta:
ollama serve
```

### Error: "Model not found"

```bash
# Bajar el modelo
ollama pull llama3
ollama list
```

### Puerto 8000 ya está en uso

```bash
# Cambiar puerto en .env
PORT=8001

# O matar proceso existente
lsof -i :8000
kill -9 <PID>
```

### Errores de permisos en SSH

```bash
# Asegurar permisos del script deploy.sh
chmod +x deploy.sh

# Asegurar permisos de archivos
chmod 755 ~/antigravity-lab
chmod 644 ~/antigravity-lab/*.py
```

---

## 📊 Estructura de archivos importante

```
antigravity-lab/
├── api/
│   ├── main.py          # Aplicación FastAPI
│   ├── routes.py        # Endpoints
│   ├── config.py        # Configuración (lee .env)
│   └── deps.py          # Inyección de dependencias
├── core/
│   ├── models.py        # Modelos Pydantic
│   ├── agents/          # Agentes especializados
│   ├── llm/             # Adaptor Ollama
│   └── orchestrator/    # Motor orquestador
├── .env                 # Configuración (NO commitear)
├── requirements.txt     # Dependencias
├── run.py              # Entry point
├── verify.py           # Test de verificación
├── test_mock.py        # Test con mocks
└── deploy.sh           # Script de deployment
```

---

## 🚀 Ejemplo de Workflow Completo

### En Local:

```bash
# 1. Hacer cambio
nano core/agents/coder.py

# 2. Probar
./venv/bin/python test_mock.py

# 3. Commit y push
git add core/agents/coder.py
git commit -m "✨ Mejorar prompt del coder"
git push origin main
```

### En Remoto:

```bash
# Via SSH
ssh user@remote-host

# Actualizar
cd ~/antigravity-lab
git pull origin main

# Probar cambios
source venv/bin/activate
python test_mock.py

# Si servicio está corriendo, reiniciar
sudo systemctl restart antigravity

# Ver logs
sudo journalctl -u antigravity -f -n 50
```

---

## 📞 Comandos útiles

```bash
# Ver estado de la API
curl http://localhost:8000/health

# Ver documentación interactiva
# Visita: http://localhost:8000/docs (Swagger UI)
#    o:  http://localhost:8000/redoc (ReDoc)

# Limpiar cache Python
find . -type d -name __pycache__ -exec rm -rf {} +
find . -type f -name "*.pyc" -delete

# Actualizar solo dependencias
pip install --upgrade -r requirements.txt

# Ver versión de Python
python --version

# Ver paquetes instalados
pip list
```

---

## ✅ Checklist para Production

- [ ] `.env` configurado con credenciales correctas
- [ ] Ollama instalado y corriendo en la maquina destino
- [ ] Puertos abiertos (8000 para API, 11434 para Ollama)
- [ ] Firewall configurado si es necesario
- [ ] Servicio systemd configurado (opcional pero recomendado)
- [ ] Logs siendo monitoreados
- [ ] Backup del `.env` en lugar seguro
- [ ] Testeo completo de API endpoints
- [ ] SSL/HTTPS configurado si es exposición pública

