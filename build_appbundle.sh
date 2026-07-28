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

echo "==> flutter pub get"
flutter pub get

# integration_test (dev_dependency) vaza para o GeneratedPluginRegistrant após
# `flutter test` e quebra o compile de release ("package ...integration_test
# does not exist"). Remove a linha do plugin após o pub get; o build roda com
# --no-pub para não regenerar o arquivo antes de compilar.
REGISTRANT="$SCRIPT_DIR/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java"
if [ -f "$REGISTRANT" ]; then
  sed -i '' '/integration_test/d' "$REGISTRANT"
fi

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

echo "==> flutter build appbundle --release"
echo "    API_BASE_URL=$API_BASE_URL"
echo "    version=$(grep '^version:' pubspec.yaml)"

flutter build appbundle --release --no-pub \
  --dart-define=API_BASE_URL="$API_BASE_URL"

AAB="$SCRIPT_DIR/build/app/outputs/bundle/release/app-release.aab"
if [ -f "$AAB" ]; then
  echo ""
  echo "==> App Bundle pronto: $AAB"
  ls -lh "$AAB"
else
  echo "==> ERRO: App Bundle não encontrado"
  exit 1
fi
