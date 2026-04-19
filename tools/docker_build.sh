#!/usr/bin/env bash
# Runs `flutter-tizen build tpk` against each plugin's example/ app
# inside the build Docker image.

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
  example="packages/${pkg}/example"
  if [ ! -f "${example}/pubspec.yaml" ]; then
    echo ">>> ${pkg}: no example/pubspec.yaml — skipping"
    continue
  fi
  echo "=============================================="
  echo ">>> ${pkg}: flutter-tizen build tpk --debug"
  echo "=============================================="
  if (cd "${example}" && flutter-tizen build tpk --debug); then
    ok+=("${pkg}")
  else
    fail+=("${pkg}")
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
