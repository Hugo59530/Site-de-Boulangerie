#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

echo "========================================"
echo "   Deployment La Rhônelle (Linux)"
echo "========================================"

install_node_if_needed() {
  if command -v node >/dev/null 2>&1; then
    echo "Node.js déjà installé : $(node -v)"
    return
  fi

  echo "Node.js introuvable. Installation en cours..."

  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y gcc-c++ make
    curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash
    sudo yum install -y nodejs
  elif command -v apk >/dev/null 2>&1; then
    sudo apk add --no-cache nodejs npm
  else
    echo "Aucun gestionnaire de paquets compatible détecté pour installer Node.js." >&2
    exit 1
  fi

  if ! command -v node >/dev/null 2>&1; then
    echo "L'installation de Node.js a échoué." >&2
    exit 1
  fi

  echo "Node.js installé avec succès : $(node -v)"
}

stop_stale_node_processes() {
  if pgrep -x node >/dev/null 2>&1; then
    echo "Fermeture des processus Node actifs pour libérer les ressources..."
    pkill -x node || true
  fi
}

ensure_dependencies() {
  if [ ! -f "$PROJECT_ROOT/package.json" ]; then
    echo "package.json introuvable : $PROJECT_ROOT" >&2
    exit 1
  fi

  stop_stale_node_processes

  if [ -d "$PROJECT_ROOT/node_modules" ]; then
    echo "Nettoyage des dépendances existantes..."
    rm -rf "$PROJECT_ROOT/node_modules"
  fi

  echo "Installation des dépendances du projet..."
  npm install --no-audit --no-fund
}

start_app() {
  if [ "${1:-}" = "--skip-start" ]; then
    echo "Le démarrage automatique est désactivé via --skip-start."
    return
  fi

  echo "Démarrage de l'application sur http://localhost:3000 ..."
  nohup npm start > "$PROJECT_ROOT/app.log" 2>&1 &
  echo $! > "$PROJECT_ROOT/.app.pid"
  echo "Le serveur est lancé en arrière-plan."
  echo "Log : $PROJECT_ROOT/app.log"
}

install_node_if_needed
ensure_dependencies
start_app "$@"

echo "Deploiement terminé avec succès."
