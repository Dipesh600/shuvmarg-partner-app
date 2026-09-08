#!/usr/bin/env zsh

set -euo pipefail

project_dir="${0:A:h:h}"
cd "$project_dir"

flutter build apk \
  --release \
  --target-platform android-arm64 \
  --no-tree-shake-icons \
  --dart-define=SHUVMARG_FLAVOR=staging
