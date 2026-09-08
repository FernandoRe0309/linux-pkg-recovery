#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$SCRIPT_DIR/manifests"
WITH_EMAIL=false

for arg in "$@"; do
  case "$arg" in
    --with-email) WITH_EMAIL=true ;;
    *) echo "Argumento desconocido: $arg" >&2; exit 1 ;;
  esac
done

mkdir -p "$OUT_DIR"

echo "==> Respaldando paquetes instalados manualmente (apt)..."
if command -v apt-mark &>/dev/null; then
  apt-mark showmanual | sort > "$OUT_DIR/apt-packages.txt"
else
  : > "$OUT_DIR/apt-packages.txt"
fi

echo "==> Respaldando snaps..."
if command -v snap &>/dev/null; then
  snap list 2>/dev/null | awk 'NR>1{print $1}' | sort > "$OUT_DIR/snap-packages.txt"
else
  : > "$OUT_DIR/snap-packages.txt"
fi

echo "==> Respaldando flatpaks..."
if command -v flatpak &>/dev/null; then
  flatpak list --app --columns=application 2>/dev/null | sort > "$OUT_DIR/flatpak-packages.txt"
else
  : > "$OUT_DIR/flatpak-packages.txt"
fi

echo "==> Respaldando paquetes pip (usuario)..."
if command -v pip3 &>/dev/null; then
  pip3 list --user --format=freeze 2>/dev/null | sort > "$OUT_DIR/pip-packages.txt"
else
  : > "$OUT_DIR/pip-packages.txt"
fi

echo "==> Respaldando herramientas pipx..."
if command -v pipx &>/dev/null; then
  pipx list --short 2>/dev/null | awk '{print $1}' | sort > "$OUT_DIR/pipx-packages.txt"
else
  : > "$OUT_DIR/pipx-packages.txt"
fi

echo "==> Respaldando paquetes npm globales..."
if command -v npm &>/dev/null; then
  npm list -g --depth=0 --parseable 2>/dev/null | tail -n +2 | xargs -r -n1 basename | sort > "$OUT_DIR/npm-global-packages.txt"
else
  : > "$OUT_DIR/npm-global-packages.txt"
fi

echo "==> Respaldando extensiones de VS Code..."
if command -v code &>/dev/null; then
  code --list-extensions | sort > "$OUT_DIR/vscode-extensions.txt"
else
  : > "$OUT_DIR/vscode-extensions.txt"
fi

echo "==> Respaldando configuración de Git..."
if [ -f "$HOME/.gitconfig" ]; then
  if [ "$WITH_EMAIL" = true ]; then
    cp "$HOME/.gitconfig" "$OUT_DIR/gitconfig"
  else
    grep -v -E '^\s*email\s*=' "$HOME/.gitconfig" > "$OUT_DIR/gitconfig"
    echo "   (email omitido; usa --with-email para incluirlo)"
  fi
else
  : > "$OUT_DIR/gitconfig"
fi

echo "==> Registrando versión de Claude Code (si está instalado)..."
if command -v claude &>/dev/null; then
  claude --version > "$OUT_DIR/claude-code-version.txt" 2>&1 || true
else
  : > "$OUT_DIR/claude-code-version.txt"
fi

echo ""
echo "Respaldo completo en: $OUT_DIR"
echo "Revisa los archivos y luego haz commit + push antes de reinstalar el sistema."
