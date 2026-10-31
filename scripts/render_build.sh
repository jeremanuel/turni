#!/usr/bin/env bash
# Build de producción (Render). Instala la versión de Flutter fijada en
# .fvmrc, así el deploy compila exactamente con la misma que el dev local.
# Uso (Build Command de Render): bash scripts/render_build.sh [args extra de flutter build web]
set -euo pipefail

cd "$(dirname "$0")/.."
VERSION=$(sed -n 's/.*"flutter": *"\([^"]*\)".*/\1/p' .fvmrc)
if [ -z "$VERSION" ]; then
  echo "No se pudo leer la versión de Flutter de .fvmrc" >&2
  exit 1
fi

FLUTTER_DIR="${FLUTTER_HOME:-$HOME/flutter}"
if [ ! -x "$FLUTTER_DIR/bin/flutter" ] || ! "$FLUTTER_DIR/bin/flutter" --version 2>/dev/null | grep -q "Flutter $VERSION "; then
  echo "==> Instalando Flutter $VERSION en $FLUTTER_DIR"
  rm -rf "$FLUTTER_DIR"
  git clone -q --depth 1 --branch "$VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version
flutter config --no-analytics >/dev/null
flutter pub get
flutter build web --release "$@"
