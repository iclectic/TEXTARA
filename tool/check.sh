#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> flutter pub get"
flutter pub get

echo "==> dart format"
dart format --output=none --set-exit-if-changed .

echo "==> flutter analyze"
flutter analyze --no-fatal-infos --fatal-warnings

echo "==> flutter test"
flutter test

echo "==> All checks passed"
