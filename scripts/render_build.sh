#!/usr/bin/env bash
# Build de producción (Render). Instala la versión de Flutter fijada en
# .fvmrc, así el deploy compila exactamente con la misma que el dev local.
# Uso (Build Command de Render): bash scripts/render_build.sh [args extra de flutter build web]
#
# Cada deploy lleva un número de versión nuevo (AAAAMMDDhhmmss, o APP_VERSION
# si viene del entorno). Va compilado en la app (--dart-define=VERSION) y
# escrito en .env.production, el archivo que sirve el servidor: al abrir, la
# app compara los dos y, si el servidor tiene otro, recarga para traer la
# última versión (ver lib/core/services/app_version/app_version.dart).
set -euo pipefail

cd "$(dirname "$0")/.."
FLUTTER_VERSION=$(sed -n 's/.*"flutter": *"\([^"]*\)".*/\1/p' .fvmrc)
if [ -z "$FLUTTER_VERSION" ]; then
  echo "No se pudo leer la versión de Flutter de .fvmrc" >&2
  exit 1
fi
APP_VERSION="${APP_VERSION:-$(date -u +%Y%m%d%H%M%S)}"

FLUTTER_DIR="${FLUTTER_HOME:-$HOME/flutter}"
if [ ! -x "$FLUTTER_DIR/bin/flutter" ] || ! "$FLUTTER_DIR/bin/flutter" --version 2>/dev/null | grep -q "Flutter $FLUTTER_VERSION "; then
  echo "==> Instalando Flutter $FLUTTER_VERSION en $FLUTTER_DIR"
  rm -rf "$FLUTTER_DIR"
  git clone -q --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

# La versión del deploy en .env.production (reemplaza la que hubiera).
ENV_FILE=.env.production
touch "$ENV_FILE"
grep -v '^VERSION=' "$ENV_FILE" > "$ENV_FILE.tmp" || true
if [ -s "$ENV_FILE.tmp" ] && [ "$(tail -c1 "$ENV_FILE.tmp")" != "" ]; then echo >> "$ENV_FILE.tmp"; fi
echo "VERSION=$APP_VERSION" >> "$ENV_FILE.tmp"
mv "$ENV_FILE.tmp" "$ENV_FILE"
echo "==> Versión de la app: $APP_VERSION"

flutter --version
flutter config --no-analytics >/dev/null
flutter pub get
flutter build web --release --dart-define=VERSION="$APP_VERSION" "$@"
