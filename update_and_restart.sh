#!/bin/bash
#
# Antigravity-Lab Update and Restart Script
# Descarga última versión, para API si está corriendo, la reinicia y hace tests
# También verifica firewall y servicios
#
# Uso:
#   ./update_and_restart.sh              # Usar valores por defecto
#   ./update_and_restart.sh --skip-tests # Saltar tests
#   ./update_and_restart.sh --setup-service # Instalar como servicio systemd
#

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
PYTHON_EXEC="${PYTHON_EXEC:-python3}"
PID_FILE="$PROJECT_DIR/antigravity.pid"
LOG_FILE="$PROJECT_DIR/api.log"
SERVICE_NAME="antigravity"

# Flags
SKIP_TESTS=0
SETUP_SERVICE=0
SETUP_FIREWALL=0

# Parse argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-tests)
            SKIP_TESTS=1
            shift
            ;;
        --setup-service)
            SETUP_SERVICE=1
            shift
            ;;
        --setup-firewall)
            SETUP_FIREWALL=1
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ============================================================
# FUNCIONES
# ============================================================

log_section() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# ============================================================
# PASO 1: VERIFICAR SISTEMA
# ============================================================

step_verify_system() {
    log_section "Step 1/9: Verificando Sistema"
    
    if [ ! -d "$PROJECT_DIR/.git" ]; then
        log_error "No se encontró directorio .git en $PROJECT_DIR"
        exit 1
    fi
    log_success "Directorio del proyecto encontrado: $PROJECT_DIR"
    
    if ! command -v $PYTHON_EXEC &> /dev/null; then
        log_error "$PYTHON_EXEC no está instalado"
        exit 1
    fi
    PYTHON_VERSION=$($PYTHON_EXEC --version)
    log_success "Python disponible: $PYTHON_VERSION"
    
    if ! command -v git &> /dev/null; then
        log_error "Git no está instalado"
        exit 1
    fi
    log_success "Git disponible"
}

# ============================================================
# PASO 2: ACTUALIZAR CÓDIGO
# ============================================================

step_git_update() {
    log_section "Step 2/9: Descargando Última Versión"
    
    cd "$PROJECT_DIR"
    
    CURRENT_COMMIT=$(git rev-parse --short HEAD)
    log_info "Commit actual: $CURRENT_COMMIT"
    
    log_info "Ejecutando: git fetch origin"
    git fetch origin
    
    log_info "Ejecutando: git pull origin main"
    git pull origin main
    
    NEW_COMMIT=$(git rev-parse --short HEAD)
    
    if [ "$CURRENT_COMMIT" != "$NEW_COMMIT" ]; then
        log_success "Código actualizado: $CURRENT_COMMIT → $NEW_COMMIT"
    else
        log_info "Código ya estaba actualizado ($NEW_COMMIT)"
    fi
    
    # Leer versión
    if [ -f VERSION ]; then
        APP_VERSION=$(cat VERSION)
        log_success "Versión de app: $APP_VERSION"
    fi
}

# ============================================================
# PASO 3: PARAR API SI ESTÁ CORRIENDO
# ============================================================

step_stop_api() {
    log_section "Step 3/9: Parando API (si está corriendo)"
    
    # Buscar procesos Python corriendo la API
    if pgrep -f "python.*run.py" > /dev/null; then
        log_warning "API está corriendo. Intentando parar..."
        
        # Buscar PID
        API_PID=$(pgrep -f "python.*run.py" | head -1)
        log_info "Proceso encontrado: PID $API_PID"
        
        # Intentar kill graceful
        kill -TERM $API_PID 2>/dev/null || true
        
        # Esperar a que termine
        for i in {1..10}; do
            if ! kill -0 $API_PID 2>/dev/null; then
                log_success "API detenida gracefully"
                break
            fi
            if [ $i -eq 10 ]; then
                log_warning "Fuerza deteniendo API (SIGKILL)"
                kill -9 $API_PID 2>/dev/null || true
            fi
            sleep 1
        done
    else
        log_info "API no estaba corriendo"
    fi
}

# ============================================================
# PASO 4: INSTALAR DEPENDENCIAS
# ============================================================

step_install_deps() {
    log_section "Step 4/9: Instalando Dependencias"
    
    # Crear venv si no existe
    if [ ! -d "$PROJECT_DIR/venv" ]; then
        log_info "Creando virtual environment..."
        $PYTHON_EXEC -m venv "$PROJECT_DIR/venv"
    fi
    
    # Activar venv
    source "$PROJECT_DIR/venv/bin/activate"
    
    # Upgrade tools
    log_info "Actualizando pip, setuptools, wheel..."
    pip install -q --upgrade pip setuptools wheel
    
    # Install requirements
    log_info "Instalando dependencias desde requirements.txt..."
    pip install -q -r "$PROJECT_DIR/requirements.txt"
    
    log_success "Dependencias instaladas"
}

# ============================================================
# PASO 5: INICIAR API
# ============================================================

step_start_api() {
    log_section "Step 5/9: Iniciando API"
    
    cd "$PROJECT_DIR"
    source "$PROJECT_DIR/venv/bin/activate"
    
    log_info "Iniciando FastAPI en background..."
    
    # Iniciar API en background con nohup
    nohup $PYTHON_EXEC run.py > "$LOG_FILE" 2>&1 &
    API_PID=$!
    
    # Guardar PID
    echo $API_PID > "$PID_FILE"
    
    log_info "API iniciada con PID: $API_PID"
    
    # Esperar a que esté lista
    log_info "Esperando a que API esté lista..."
    READY=0
    for i in {1..30}; do
        if curl -s http://localhost:8000/health > /dev/null 2>&1; then
            READY=1
            break
        fi
        echo -n "."
        sleep 1
    done
    echo ""
    
    if [ $READY -eq 1 ]; then
        log_success "API está respondiendo"
    else
        log_error "API no respondió después de 30 segundos"
        log_error "Últimas líneas del log:"
        tail -10 "$LOG_FILE" | sed 's/^/   /'
        exit 1
    fi
}

# ============================================================
# PASO 6: EJECUTAR TESTS
# ============================================================

step_run_tests() {
    log_section "Step 6/9: Ejecutando Tests"
    
    if [ $SKIP_TESTS -eq 1 ]; then
        log_warning "Tests omitidos (--skip-tests)"
        return
    fi
    
    cd "$PROJECT_DIR"
    source "$PROJECT_DIR/venv/bin/activate"
    
    # Test 1: Verify system
    log_info "Test 1: Verificación de configuración..."
    if $PYTHON_EXEC verify.py > /dev/null 2>&1; then
        log_success "Test 1 pasó: Config OK"
    else
        log_error "Test 1 falló: Config verificación"
        exit 1
    fi
    
    # Test 2: Mock test
    log_info "Test 2: Mock LLM test..."
    if $PYTHON_EXEC test_mock.py > /dev/null 2>&1; then
        log_success "Test 2 pasó: Mock orchestrator OK"
    else
        log_error "Test 2 falló: Mock test"
        exit 1
    fi
    
    # Test 3: Health check
    log_info "Test 3: Health check endpoint..."
    HEALTH=$(curl -s http://localhost:8000/health)
    if echo "$HEALTH" | grep -q "ok"; then
        VERSION=$(echo "$HEALTH" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
        log_success "Test 3 pasó: Health check OK (Version: $VERSION)"
    else
        log_error "Test 3 falló: Health check"
        exit 1
    fi
    
    log_success "Todos los tests pasaron ✅"
}

# ============================================================
# PASO 7: FIREWALL
# ============================================================

step_setup_firewall() {
    log_section "Step 7/9: Configuración de Firewall"
    
    if [ $SETUP_FIREWALL -ne 1 ]; then
        log_warning "Firewall setup omitido. Usa --setup-firewall para habilitarlo"
        return
    fi
    
    UNAME_S=$(uname -s)
    
    if [ "$UNAME_S" = "Linux" ]; then
        log_info "Detectado Linux. Configurando ufw..."
        
        if command -v ufw &> /dev/null; then
            sudo ufw allow 8000/tcp
            sudo ufw allow 11434/tcp
            log_success "Puertos 8000 y 11434 permitidos en ufw"
        else
            log_warning "ufw no está instalado. Saltando..."
        fi
    
    elif [ "$UNAME_S" = "Darwin" ]; then
        log_info "Detectado macOS..."
        log_warning "En macOS, prueba abrir System Preferences → Security & Privacy → Firewall"
        log_warning "O ejecuta: sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off"
        
    else
        log_warning "Sistema operativo desconocido. Verifica manualmente el firewall."
    fi
}

# ============================================================
# PASO 8: SERVICIO SYSTEMD
# ============================================================

step_setup_service() {
    log_section "Step 8/9: Configuración de Servicio Systemd"
    
    if [ $SETUP_SERVICE -ne 1 ]; then
        log_warning "Setup de servicio omitido. Usa --setup-service para habilitarlo"
        log_info "Para instalar como servicio, ejecuta:"
        log_info "  sudo $0 --setup-service"
        return
    fi
    
    UNAME_S=$(uname -s)
    
    if [ "$UNAME_S" != "Linux" ]; then
        log_warning "Servicio systemd solo disponible en Linux. Saltando..."
        return
    fi
    
    # Crear archivo de servicio
    SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
    VENV_PYTHON="$PROJECT_DIR/venv/bin/python"
    RUN_SCRIPT="$PROJECT_DIR/run.py"
    
    log_info "Creando archivo de servicio: $SERVICE_FILE"
    
    SERVICE_CONTENT="[Unit]
Description=Antigravity Lab API Server
After=network.target

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=$PROJECT_DIR
ExecStart=$VENV_PYTHON $RUN_SCRIPT
Restart=always
RestartSec=10
StandardOutput=append:$LOG_FILE
StandardError=append:$LOG_FILE

[Install]
WantedBy=multi-user.target
"
    
    echo "$SERVICE_CONTENT" | sudo tee "$SERVICE_FILE" > /dev/null
    
    log_info "Reloadiendo systemd daemon..."
    sudo systemctl daemon-reload
    
    log_info "Activando servicio para autostart..."
    sudo systemctl enable $SERVICE_NAME
    
    log_success "Servicio instalado: $SERVICE_NAME"
    log_info "Para controlar el servicio:"
    log_info "  sudo systemctl start $SERVICE_NAME"
    log_info "  sudo systemctl stop $SERVICE_NAME"
    log_info "  sudo systemctl restart $SERVICE_NAME"
    log_info "  sudo systemctl status $SERVICE_NAME"
}

# ============================================================
# PASO 9: RESUMEN FINAL
# ============================================================

step_final_summary() {
    log_section "Step 9/9: Resumen Final"
    
    log_success "✅ Todos los pasos completados exitosamente!"
    echo ""
    
    log_info "Estado actual:"
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        HEALTH_JSON=$(curl -s http://localhost:8000/health)
        VERSION=$(echo "$HEALTH_JSON" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
        log_success "API Status: ✅ Running (Version: $VERSION)"
        log_success "Health Check: $(echo "$HEALTH_JSON" | grep -o '"status":"[^"]*"')"
    else
        log_error "API Status: ❌ Not responding"
    fi
    
    echo ""
    log_info "URLs disponibles:"
    log_info "  API Health: http://localhost:8000/health"
    log_info "  API Docs:   http://localhost:8000/docs"
    log_info "  API Redoc:  http://localhost:8000/redoc"
    
    echo ""
    log_info "Logs:"
    log_info "  $LOG_FILE"
    
    echo ""
    log_info "Para ver logs en tiempo real:"
    log_info "  tail -f $LOG_FILE"
    
    echo ""
}

# ============================================================
# MAIN
# ============================================================

main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Antigravity-Lab Update and Restart Script                ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    log_info "Directorio del proyecto: $PROJECT_DIR"
    log_info "Ejecutable Python: $PYTHON_EXEC"
    echo ""
    
    step_verify_system
    step_git_update
    step_stop_api
    step_install_deps
    step_start_api
    step_run_tests
    step_setup_firewall
    step_setup_service
    step_final_summary
    
    echo -e "${GREEN}✨ Script completado exitosamente ✨${NC}\n"
}

main "$@"
