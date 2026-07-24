#!/bin/bash
set -e

# Fix JAVA_HOME if not set
if [ -z "$JAVA_HOME" ]; then
  export JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null || echo "")
fi

# Android SDK
export ANDROID_HOME="/opt/homebrew/Caskroom/android-platform-tools/37.0.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ -f "$SCRIPT_DIR/.env.build" ]; then
  echo "==> loading .env.build"
  set -a
  # shellcheck disable=SC1091
  . "$SCRIPT_DIR/.env.build"
  set +a
fi

# API_BASE_URL="${API_BASE_URL:-https://c8b1-2804-2610-6752-3e00-4d11-702d-6b00-cf10.ngrok-free.app/api}"
# PUSHER_APP_KEY="${PUSHER_APP_KEY:-app-key}"

echo "==> flutter pub get"
flutter pub get

# Patch maplibre NDK version to match installed NDK (28.2.13676358)
for BUILD_GRADLE in \
  "$HOME/.pub-cache/hosted/pub.dev/maplibre_gl-0.21.0/android/build.gradle" \
  "$HOME/.pub-cache/hosted/pub.dev/maplibre_gl-0.26.1/android/build.gradle"; do
  if [ -f "$BUILD_GRADLE" ]; then
    sed -i '' \
      's/ndkVersion "27\.0\.12077973"/ndkVersion "28.2.13676358"/' \
      "$BUILD_GRADLE"
    sed -i '' \
      's/ndkVersion "28\.1\.13356709"/ndkVersion "28.2.13676358"/' \
      "$BUILD_GRADLE"
    # Align Java/Kotlin target to 17 (project pins Kotlin jvmTarget=17;
    # maplibre 0.26.1 ships VERSION_21 which causes a JVM-target mismatch).
    sed -i '' \
      's/JavaVersion\.VERSION_21/JavaVersion.VERSION_17/g' \
      "$BUILD_GRADLE"
  fi
done

echo "==> flutter build apk --release --target-platform android-arm64"
echo "    API_BASE_URL=$API_BASE_URL"

flutter build apk --release \
  --target-platform android-arm64 \
  --dart-define=API_BASE_URL="$API_BASE_URL"

APK="$SCRIPT_DIR/build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK" ]; then
  echo ""
  echo "==> APK pronto: $APK"
  ls -lh "$APK"
else
  echo "==> ERRO: APK não encontrado"
  exit 1
fi
