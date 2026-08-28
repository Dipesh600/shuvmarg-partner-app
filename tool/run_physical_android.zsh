#!/bin/zsh

set -euo pipefail

project_dir="${0:A:h:h}"
api_port="${SHUVMARG_API_PORT:-7012}"
api_base="${SHUVMARG_API_BASE_URL:-}"

if [[ -z "$api_base" ]]; then
  for interface_name in en0 en1; do
    lan_ip="$(ipconfig getifaddr "$interface_name" 2>/dev/null || true)"
    if [[ -n "$lan_ip" ]]; then
      api_base="http://${lan_ip}:${api_port}"
      break
    fi
  done
fi

if [[ -z "$api_base" ]]; then
  print -u2 "Could not find this Mac's Wi-Fi address."
  print -u2 "Connect to Wi-Fi or set SHUVMARG_API_BASE_URL explicitly."
  exit 1
fi

http_status="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 3 \
  "${api_base}/api/login" || true)"
if [[ "$http_status" == "000" ]]; then
  print -u2 "The backend is not reachable at ${api_base}."
  print -u2 "Start it first, and keep the phone on the same Wi-Fi network."
  exit 1
fi

print "Running Partner against ${api_base}"
cd "$project_dir"
exec flutter run \
  --dart-define=SHUVMARG_FLAVOR=local \
  --dart-define=SHUVMARG_API_BASE_URL="$api_base" \
  "$@"
