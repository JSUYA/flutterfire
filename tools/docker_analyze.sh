#!/usr/bin/env bash
# Runs `flutter-tizen pub get` + `flutter-tizen analyze` across every
# Tizen plugin inside the Docker analyzer image. Stops on the first
# failure and prints a concise summary so the host log stays readable.

set -euo pipefail

cd /repo

PACKAGES=(
  firebase_core
  firebase_auth
  firebase_database
  firebase_storage
  cloud_functions
  firebase_app_installations
  firebase_remote_config
  firebase_ai
)

fail=()
ok=()

for pkg in "${PACKAGES[@]}"; do
  echo "=============================================="
  echo ">>> ${pkg}: flutter-tizen pub get"
  echo "=============================================="
  if ! (cd "packages/${pkg}" && flutter-tizen pub get); then
    fail+=("${pkg} (pub get)")
    continue
  fi

  echo "=============================================="
  echo ">>> ${pkg}: flutter-tizen analyze"
  echo "=============================================="
  if (cd "packages/${pkg}" && flutter-tizen analyze --no-pub --no-fatal-infos); then
    ok+=("${pkg}")
  else
    fail+=("${pkg} (analyze)")
  fi
done

echo
echo "=============================================="
echo "SUMMARY"
echo "=============================================="
for p in "${ok[@]}";   do echo " OK    ${p}"; done
for p in "${fail[@]}"; do echo " FAIL  ${p}"; done

if (( ${#fail[@]} > 0 )); then
  exit 1
fi
