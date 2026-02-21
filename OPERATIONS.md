# 🚀 OPERATIONS GUIDE - Antigravity-Lab

Guía completa para operación, mantenimiento y escalamiento del sistema en producción.

---

## 📋 Índice

1. [Setup Inicial](#setup-inicial)
2. [Actualización Automática](#actualización-automática)
3. [Gestión de Servicios](#gestión-de-servicios)
4. [Monitoreo](#monitoreo)
5. [Firewall](#firewall)
6. [Versionado](#versionado)
7. [Troubleshooting](#troubleshooting)

---

## Setup Inicial

### Instalación en máquina remota

```bash
# 1. Conectar vía SSH
ssh user@192.168.1.5

# 2. Clonar repositorio
git clone https://github.com/raulmad6600/antigravity-lab.git
cd antigravity-lab

# 3. Ejecutar script de deployment
bash deploy.sh
```

### Variables de entorno críticas

Archivo: `.env`

```env
# Credentials - NUNCA commitear este archivo
DEBUG=False                          # CAMBIAR a False en producción
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama3
HOST=0.0.0.0
PORT=8000
MAX_ITERATIONS=3
```

⚠️ **IMPORTANTE**: El archivo `.env` está en `.gitignore` y NO se debe subir a GitHub.

---

## 🔄 Actualización Automática

Script: `update_and_restart.sh`

### Uso básico

```bash
# Actualizar código, para API si está corriendo y la reinicia
bash update_and_restart.sh

# Opción: Omitir tests (más rápido)
bash update_and_restart.sh --skip-tests

# Opción: Instalar como servicio systemd (Linux)
sudo bash update_and_restart.sh --setup-service

# Opción: Configurar firewall
bash update_and_restart.sh --setup-firewall
```

### Qué hace el script

1. ✅ Verifica sistema (Python, Git)
2. ✅ Git pull de últimos cambios
3. ✅ Para API si está corriendo
4. ✅ Instala/actualiza dependencias
5. ✅ Inicia API
6. ✅ Ejecuta tests (verify.py, test_mock.py, health check)
7. ✅ Configura firewall (opcional)
8. ✅ Instala servicio systemd (opcional)

### Ejemplo de salida

```
===========================================
   Antigravity-Lab Update and Restart Script
===========================================

ℹ️  Project directory: /Users/smartlab/antigravity-lab
ℹ️  Python executable: python3

==========================================
Step 1/9: Verificando Sistema
==========================================

✅ Directorio del proyecto encontrado: /Users/smartlab/antigravity-lab
✅ Python disponible: Python 3.11.5
✅ Git disponible

...

==========================================
Step 9/9: Resumen Final
==========================================

✅ Todos los pasos completados exitosamente!

ℹ️  Estado actual:
✅ API Status: ✅ Running (Version: 1.0.0)
```

---

## 🛠️ Gestión de Servicios

### Opción 1: Autostart con systemd (Linux)

#### Setup

```bash
# Crear archivo de servicio
sudo cp antigravity.service /etc/systemd/system/antigravity.service

# Editar configuración del usuario/directorio
sudo nano /etc/systemd/system/antigravity.service

# Recargar systemd
sudo systemctl daemon-reload

# Habilitar para autostart
sudo systemctl enable antigravity

# Iniciar servicio
sudo systemctl start antigravity
```

#### Comandos de control

```bash
# Ver estado
sudo systemctl status antigravity

# Ver logs en tiempo real
sudo journalctl -u antigravity -f

# Últimas 50 líneas
sudo journalctl -u antigravity -n 50

# Reiniciar
sudo systemctl restart antigravity

# Parar
sudo systemctl stop antigravity

# Deshabilitar autostart
sudo systemctl disable antigravity
```

### Opción 2: Ejecución manual

```bash
# En terminal
cd ~/antigravity-lab
source venv/bin/activate
python run.py

# O en background con logs
nohup python run.py > api.log 2>&1 &
echo $! > antigravity.pid
```

### Opción 3: Screen/tmux

```bash
# Con screen
screen -S antigravity
cd ~/antigravity-lab
source venv/bin/activate
python run.py

# Desprenderse: Ctrl+A, D
# Reconectar: screen -r antigravity
```

---

## 📊 Monitoreo

### Health Check

```bash
# Local
curl http://localhost:8000/health

# Remoto
curl http://192.168.1.5:8000/health

# Respuesta esperada
{
  "status": "ok",
  "version": "1.0.0",
  "app": "Antigravity-Lab",
  "debug": false
}
```

### Logs

```bash
# Ver logs en tiempo real
tail -f ~/antigravity-lab/api.log

# Últimas 100 líneas
tail -100 ~/antigravity-lab/api.log

# Buscar errores
grep ERROR ~/antigravity-lab/api.log

# Con timestamp
tail -f ~/antigravity-lab/api.log | sed 's/^/[$(date)]: /'
```

### Procesos

```bash
# Ver procesos activos
ps aux | grep -E '(ollama|python run)'

# Ver solo PID
pgrep -f "python.*run.py"

# Monitor en tiempo real
watch -n 1 "ps aux | grep -E '(ollama|python run)' | grep -v grep"
```

### Puertos

```bash
# Verificar puertos escuchando
netstat -tulpn | grep -E "(8000|11434)"

# O con ss
ss -tulpn | grep -E "(8000|11434)"

# Conectividad remota
telnet 192.168.1.5 8000
telnet 192.168.1.5 11434
```

---

## 🔥 Firewall

Script: `setup_firewall.sh`

### Configuración automática

```bash
# Linux (UFW o FirewallD)
sudo bash setup_firewall.sh

# macOS
bash setup_firewall.sh
```

### Manual

#### Linux - UFW

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp      # SSH para administración
sudo ufw allow 8000/tcp    # API
sudo ufw allow 11434/tcp   # Ollama TCP
sudo ufw allow 11434/udp   # Ollama UDP
sudo ufw enable
sudo ufw status
```

#### Linux - FirewallD

```bash
sudo firewall-cmd --permanent --add-port=22/tcp
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --permanent --add-port=11434/tcp
sudo firewall-cmd --permanent --add-port=11434/udp
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

#### macOS

```bash
# El firewall de macOS bloquea aplicaciones desconocidas automáticamente
# Opción 1: Desactivar (menos seguro)
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off

# Opción 2: Permitir app específica desde interfaz gráfica
# System Preferences → Security & Privacy → Firewall → Firewall Options
# Añadir python/FastAPI a la lista
```

---

## 📌 Versionado

### Archivo VERSION

```
1.0.0
```

**Formato**: MAJOR.MINOR.PATCH

### Actualizar versión

```bash
# Editar el archivo
echo "1.1.0" > VERSION

# Respuesta del API mostrará la nueva versión
curl http://localhost:8000/health
# {
#   "version": "1.1.0",
#   ...
# }

# Crear tag en git
git tag v1.1.0
git push origin v1.1.0
```

### Cómo implementar versionado

La versión se usa en:
1. **VERSION** - Archivo fuente de verdad
2. **config.py** - Leída por FastAPI en iniciación
3. **/health** - Endpoint retorna versión actual
4. **OpenAPI/Swagger** - Documentación muestra versión

---

## 🐛 Troubleshooting

### API no inicia

```bash
# Ver logs
tail -50 ~/antigravity-lab/api.log

# Verificar que puerto 8000 no está en uso
lsof -i :8000

# Matar proceso si es necesario
pkill -f "python.*run.py"

# Verificar permisos
ls -la ~/antigravity-lab/api.log
```

### Error "Connection refused" a Ollama

```bash
# Verificar que Ollama está corriendo
ps aux | grep ollama

# Probar conectividad
curl http://localhost:11434/api/tags

# Si Ollama está en otra máquina, editar .env
OLLAMA_BASE_URL=http://192.168.1.100:11434
```

### Permisos SSH

```bash
# Permisos correctos para el repo
chmod 755 ~/antigravity-lab
chmod 644 ~/antigravity-lab/*.py
chmod 644 ~/antigravity-lab/requirements.txt
chmod 755 ~/antigravity-lab/update_and_restart.sh
```

### Firewall bloqueando

```bash
# Verificar puertos están abiertos
sudo ufw show added

# Verificar conexión localmente
telnet localhost 8000

# Si funciona local pero no remoto, es firewall
telnet 192.168.1.5 8000  # Desde otra máquina
```

### API lenta

```bash
# Ver uso de recursos
top -p $(pgrep -f "python.*run.py")

# Verificar logs de errores
grep -i error ~/antigravity-lab/api.log | tail -20

# Limitar recursos en systemd
# Editar: /etc/systemd/system/antigravity.service
# Cambiar:
# MemoryLimit=1G
# CPUQuota=80%
```

---

## 📋 Checklist de Deployments

- [ ] Código actualizado en GitHub
- [ ] .env configurado localmente (NO en git)
- [ ] test_mock.py ejecutado exitosamente
- [ ] verify.py ejecutado exitosamente
- [ ] Health check respondiendo
- [ ] Firewall configurado
- [ ] Servicio systemd activo (si es Linux)
- [ ] Logs monitoreados
- [ ] Monitoreo automático habilitado
- [ ] Backups del .env en lugar seguro
- [ ] Versión actualizada

---

## 🔐 Seguridad

### Archivos sensibles (no commitear)

```
.env                 # Credenciales
.env.*               # Archivos de entorno
*.key / *.pem        # Claves privadas
credentials/         # Cualquier carpeta de credenciales
secrets/             # Archivos secretos
api.log              # Logs pueden contener info sensible
```

Todos estos están en `.gitignore`.

### Verificar antes de hacer push

```bash
# Buscar credenciales antes de commit
git diff HEAD -- | grep -E "(password|secret|key|token)"

# Ver qué se va a commitear
git diff --cached --name-only

# Ver contenido del commit
git diff --cached

# Si hay algo que no debería estar:
git reset HEAD archivo_sensible.txt
# Y añadirlo a .gitignore
```

---

## 📞 Referencias

- GitHub: https://github.com/raulmad6600/antigravity-lab
- Documentación API: http://localhost:8000/docs
- Ollama: https://ollama.ai

