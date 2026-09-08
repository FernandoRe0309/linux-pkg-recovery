#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IN_DIR="$SCRIPT_DIR/manifests"
FAILURES=()

log() { echo -e "\n==> $1"; }
fail() { FAILURES+=("$1"); echo "   [FALLÓ] $1"; }

if [ ! -d "$IN_DIR" ]; then
  echo "No existe la carpeta de manifiestos ($IN_DIR). Corre backup.sh primero en el sistema original." >&2
  exit 1
fi

log "Actualizando índices de apt..."
sudo apt-get update -y || fail "apt-get update"

if [ -s "$IN_DIR/apt-packages.txt" ]; then
  log "Instalando paquetes apt..."
  while read -r pkg; do
    [ -z "$pkg" ] && continue
    sudo apt-get install -y "$pkg" || fail "apt: $pkg"
  done < "$IN_DIR/apt-packages.txt"
fi

if [ -s "$IN_DIR/snap-packages.txt" ]; then
  log "Instalando snaps..."
  if ! command -v snap &>/dev/null; then
    sudo apt-get install -y snapd || fail "instalar snapd"
  fi
  while read -r pkg; do
    [ -z "$pkg" ] && continue
    sudo snap install "$pkg" || fail "snap: $pkg (puede requerir --classic, revisa manualmente)"
  done < "$IN_DIR/snap-packages.txt"
fi

if [ -s "$IN_DIR/flatpak-packages.txt" ]; then
  log "Instalando flatpaks..."
  if ! command -v flatpak &>/dev/null; then
    sudo apt-get install -y flatpak || fail "instalar flatpak"
  fi
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || fail "agregar remoto flathub"
  while read -r app; do
    [ -z "$app" ] && continue
    flatpak install -y flathub "$app" || fail "flatpak: $app"
  done < "$IN_DIR/flatpak-packages.txt"
fi

if [ -s "$IN_DIR/pip-packages.txt" ]; then
  log "Instalando paquetes pip (usuario)..."
  command -v pip3 &>/dev/null || sudo apt-get install -y python3-pip || fail "instalar pip3"
  while read -r pkg; do
    [ -z "$pkg" ] && continue
    pip3 install --user "$pkg" || fail "pip: $pkg"
  done < "$IN_DIR/pip-packages.txt"
fi

if [ -s "$IN_DIR/pipx-packages.txt" ]; then
  log "Instalando herramientas pipx..."
  command -v pipx &>/dev/null || { sudo apt-get install -y pipx || fail "instalar pipx"; }
  while read -r pkg; do
    [ -z "$pkg" ] && continue
    pipx install "$pkg" || fail "pipx: $pkg"
  done < "$IN_DIR/pipx-packages.txt"
fi

if [ -s "$IN_DIR/npm-global-packages.txt" ]; then
  log "Instalando paquetes npm globales..."
  if ! command -v npm &>/dev/null; then
    fail "npm no está instalado; instala Node.js primero y vuelve a correr esta sección"
  else
    while read -r pkg; do
      [ -z "$pkg" ] && continue
      sudo npm install -g "$pkg" || fail "npm: $pkg"
    done < "$IN_DIR/npm-global-packages.txt"
  fi
fi

log "Verificando Claude Code..."
if command -v claude &>/dev/null; then
  echo "   Ya está instalado: $(claude --version 2>&1)"
elif command -v npm &>/dev/null; then
  sudo npm install -g @anthropic-ai/claude-code || fail "instalar Claude Code"
else
  fail "Claude Code no instalado (falta npm)"
fi

if [ -s "$IN_DIR/vscode-extensions.txt" ]; then
  log "Instalando extensiones de VS Code..."
  if ! command -v code &>/dev/null; then
    fail "VS Code no está instalado; instálalo manualmente y vuelve a correr esta sección"
  else
    while read -r ext; do
      [ -z "$ext" ] && continue
      code --install-extension "$ext" || fail "vscode ext: $ext"
    done < "$IN_DIR/vscode-extensions.txt"
  fi
fi

log "Restaurando configuración de Git..."
if [ -s "$IN_DIR/gitconfig" ]; then
  cp "$IN_DIR/gitconfig" "$HOME/.gitconfig"
  echo "   .gitconfig restaurado. Si omitiste el email en el backup, configúralo con:"
  echo "   git config --global user.email \"tu-email@ejemplo.com\""
fi

log "Configurando acceso SSH a GitHub..."
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -C "$(hostname)-$(date +%Y%m%d)" -f "$HOME/.ssh/id_ed25519" -N ""
  eval "$(ssh-agent -s)" && ssh-add "$HOME/.ssh/id_ed25519"
  echo ""
  echo "   Llave SSH nueva generada. Copia esta clave pública y agrégala en:"
  echo "   https://github.com/settings/keys"
  echo "   -------------------------------------------"
  cat "$HOME/.ssh/id_ed25519.pub"
  echo "   -------------------------------------------"
else
  echo "   Ya existe una llave SSH en ~/.ssh/id_ed25519, no se generó una nueva."
fi

echo ""
if [ "${#FAILURES[@]}" -eq 0 ]; then
  echo "Restauración completa sin errores."
else
  echo "Restauración terminada con ${#FAILURES[@]} problema(s):"
  printf '  - %s\n' "${FAILURES[@]}"
fi
