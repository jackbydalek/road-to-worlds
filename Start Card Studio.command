#!/bin/zsh
set -eu
cd "${0:A:h}/tools/card-editor"
if ! command -v node >/dev/null 2>&1; then
  # Finder launches do not source the interactive shell that initializes nvm.
  if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    set +u
    source "$HOME/.nvm/nvm.sh"
    set -u
  fi
fi
if ! command -v node >/dev/null 2>&1; then
  print 'Card Studio needs Node.js 18 or newer. Install Node, then open this launcher again.'
  read -r 'reply?Press Return to close.'
  exit 1
fi
node server.mjs &
studio_pid=$!
trap 'kill "$studio_pid" 2>/dev/null || true' EXIT INT TERM
studio_port="${CARD_STUDIO_PORT:-4317}"
for studio_attempt in {1..30}; do
  if /usr/bin/curl --silent --fail "http://127.0.0.1:$studio_port/api/catalog" >/dev/null; then
    /usr/bin/open "http://127.0.0.1:$studio_port"
    break
  fi
  if ! kill -0 "$studio_pid" 2>/dev/null; then
    wait "$studio_pid"
    exit $?
  fi
  sleep 0.2
done
wait "$studio_pid"
