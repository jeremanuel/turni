#!/usr/bin/env bash
# Build de producción (Render). Hace lo mismo que el Build Command que tenía
# el servicio, pero con la versión de Flutter de .fvmrc (la misma del dev
# local):
#   1. instala esa versión de Flutter (o reusa la que ya está);
#   2. arma .env.production con las variables del servicio (API_URL,
#      GOOGLE_CLIENT_ID) y la versión del deploy;
#   3. genera el código (build_runner: los *.g.dart y *.freezed.dart no están
#      en el repo) y compila la web.
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
if [ "$(git -C "$FLUTTER_DIR" describe --tags --exact-match 2>/dev/null)" != "$FLUTTER_VERSION" ]; then
  echo "==> Instalando Flutter $FLUTTER_VERSION en $FLUTTER_DIR"
  rm -rf "$FLUTTER_DIR"
  git clone -q --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

# .env.production: con las variables del servicio si están; si no (build
# local), el del repo con la versión del deploy.
ENV_FILE=.env.production
if [ -n "${API_URL:-}" ]; then
  printf 'API_URL=%s\nAPI_NATIVE_URL=%s\nGOOGLE_CLIENT_ID="%s"\nVERSION=%s\n' \
    "$API_URL" "${API_NATIVE_URL:-$API_URL}" "${GOOGLE_CLIENT_ID:-}" "$APP_VERSION" > "$ENV_FILE"
else
  touch "$ENV_FILE"
  grep -v '^VERSION=' "$ENV_FILE" > "$ENV_FILE.tmp" || true
  if [ -s "$ENV_FILE.tmp" ] && [ "$(tail -c1 "$ENV_FILE.tmp")" != "" ]; then echo >> "$ENV_FILE.tmp"; fi
  echo "VERSION=$APP_VERSION" >> "$ENV_FILE.tmp"
  mv "$ENV_FILE.tmp" "$ENV_FILE"
fi
echo "==> Flutter $FLUTTER_VERSION · versión de la app $APP_VERSION"

flutter --version
flutter config --enable-web --no-analytics >/dev/null
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build web --release --dart-define=VERSION="$APP_VERSION" "$@"
