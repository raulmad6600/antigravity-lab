#!/bin/bash
# Script de deployment para Antigravity-Lab
# Uso: ./deploy.sh [host] [user] [port]

set -e

HOST=${1:-"localhost"}
USER=${2:-"user"}
PORT=${3:-"22"}

echo "🚀 Deploy de Antigravity-Lab a $USER@$HOST:$PORT"
echo "=================================================="

# Si es remoto (no localhost)
if [ "$HOST" != "localhost" ] && [ "$HOST" != "127.0.0.1" ]; then
    echo "📡 Conectando a máquina remota..."
    
    ssh -p $PORT $USER@$HOST << 'REMOTE_SCRIPT'
#!/bin/bash
set -e

# Navegar a directorio del proyecto o crear si no existe
if [ ! -d ~/antigravity-lab ]; then
    echo "📂 Clonando repositorio..."
    cd ~
    git clone https://github.com/raulmad6600/antigravity-lab.git
fi

cd ~/antigravity-lab
echo "📥 Actualizando código..."
git pull origin main

# Setup venv si no existe
if [ ! -d venv ]; then
    echo "🔧 Creando entorno virtual..."
    python3 -m venv venv
fi

# Activar y actualizar
source venv/bin/activate
echo "📦 Instalando/actualizando dependencias..."
pip install -q --upgrade pip
pip install -q -r requirements.txt

# Mostrar configuración
echo ""
echo "✅ Deploy completado!"
echo "=================================================="
echo "📋 Configuración actual:"
grep -E '^[^#]' .env
echo ""
echo "🚀 Para iniciar la API, ejecuta:"
echo "   cd ~/antigravity-lab"
echo "   source venv/bin/activate"
echo "   python run.py"
echo ""
echo "🧪 Para pruebas sin Ollama:"
echo "   python test_mock.py"
echo ""

REMOTE_SCRIPT
else
    echo "🖥️  Setup local"
    python3 -m venv venv
    source venv/bin/activate
    pip install -q -r requirements.txt
    echo "✅ Setup local completado!"
    echo "Ejecuta: python run.py"
fi
