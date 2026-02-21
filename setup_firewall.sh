#!/bin/bash
#
# Firewall Setup Script para Antigravity-Lab
# Abre puertos necesarios en diferentes firewalls
#
# Uso:
#   sudo ./setup_firewall.sh
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Verificar que es root (en Linux)
if [ "$(uname -s)" = "Linux" ] && [ "$EUID" -ne 0 ]; then
    log_error "Este script debe ejecutarse como root en Linux. Usa: sudo $0"
    exit 1
fi

UNAME_S=$(uname -s)
API_PORT=8000
OLLAMA_PORT=11434

log_info "Sistema detectado: $UNAME_S"
echo ""

if [ "$UNAME_S" = "Linux" ]; then
    
    # ========== UFW (Ubuntu/Debian) ==========
    if command -v ufw &> /dev/null; then
        echo "🔧 Configurando UFW (Ubuntu/Debian Firewall)..."
        
        ufw allow $API_PORT/tcp
        log_success "Puerto $API_PORT TCP permitido en UFW"
        
        ufw allow $OLLAMA_PORT/tcp
        log_success "Puerto $OLLAMA_PORT TCP permitido en UFW"
        
        ufw allow $OLLAMA_PORT/udp
        log_success "Puerto $OLLAMA_PORT UDP permitido en UFW"
        
        if ufw status | grep -q "Status: active"; then
            ufw reload
            log_success "UFW reloadado"
        fi
    fi
    
    # ========== FirewallD (RHEL/CentOS) ==========
    if command -v firewall-cmd &> /dev/null; then
        echo ""
        echo "🔧 Configurando FirewallD (RedHat/CentOS Firewall)..."
        
        firewall-cmd --permanent --add-port=$API_PORT/tcp
        log_success "Puerto $API_PORT TCP permitido en FirewallD"
        
        firewall-cmd --permanent --add-port=$OLLAMA_PORT/tcp
        log_success "Puerto $OLLAMA_PORT TCP permitido en FirewallD"
        
        firewall-cmd --permanent --add-port=$OLLAMA_PORT/udp
        log_success "Puerto $OLLAMA_PORT UDP permitido en FirewallD"
        
        firewall-cmd --reload
        log_success "FirewallD reloadado"
    fi

elif [ "$UNAME_S" = "Darwin" ]; then
    
    # ========== macOS ==========
    echo "🔧 Configurando Firewall de macOS..."
    
    # Verificar si el firewall está activo
    FW_STATUS=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | grep -o "enabled\|disabled")
    
    if [ "$FW_STATUS" = "enabled" ]; then
        log_warning "Firewall de macOS está ACTIVO"
        
        log_info "Opción 1: Desactivar el firewall (menos seguro)"
        log_info "  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off"
        
        log_info "Opción 2: Desactivar Firewall solo para puertos específicos"
        log_info "  System Preferences → Security & Privacy → Firewall → Firewall Options"
        log_info "  Añadir 'python' a la lista de aplicaciones permitidas"
        
        log_warning "El firewall de macOS bloquea automáticamente aplicaciones desconocidas"
        log_info "Cuando ejecutes la API por primera vez, te pedirá permiso"
    else
        log_success "Firewall de macOS está DESACTIVADO"
    fi

else
    log_warning "Sistema operativo no reconocido: $UNAME_S"
    log_info "Verifica manualmente la configuración de firewall"
fi

echo ""
echo "=========================================="
log_success "Firewall configurado correctamente"
echo "=========================================="
echo ""

log_info "Puertos requeridos:"
log_info "  • API FastAPI: puerto $API_PORT (TCP)"
log_info "  • Ollama:      puerto $OLLAMA_PORT (TCP/UDP)"
echo ""

log_info "Para verificar que los puertos están abiertos:"
log_info "  Localmente:"
log_info "    netstat -tuln | grep -E '($API_PORT|$OLLAMA_PORT)'"
log_info "  O:"
log_info "    ss -tuln | grep -E '($API_PORT|$OLLAMA_PORT)'"
echo ""

log_info "Para probrar conectividad remota:"
log_info "  # Desde otra máquina:"
log_info "  telnet <IP_SERVIDOR> $API_PORT"
log_info "  telnet <IP_SERVIDOR> $OLLAMA_PORT"
echo ""
