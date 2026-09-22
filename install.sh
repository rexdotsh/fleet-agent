#!/usr/bin/env bash
# curl -fsSL https://raw.githubusercontent.com/rexdotsh/fleet-agent/main/install.sh | sudo FLEET_HOST=media FLEET_KEY=... bash
set -euo pipefail

: "${FLEET_HOST:?}" "${FLEET_KEY:?}"
if (( EUID != 0 )); then
  echo "run as root" >&2
  exit 1
fi
for bin in curl openssl jq; do
  command -v "$bin" >/dev/null || { echo "need $bin" >&2; exit 1; }
done

raw=https://raw.githubusercontent.com/rexdotsh/fleet-agent/main
here=$(dirname "${BASH_SOURCE[0]:-}")

# put <file> <mode> <dest>: from the checkout if there is one, else from github
put() {
  if [[ -f "$here/$1" ]]; then
    install -m "$2" "$here/$1" "$3"
  else
    curl -fsSL "$raw/$1" | install -m "$2" /dev/stdin "$3"
  fi
}

put fleet-agent 755 /usr/local/bin/fleet-agent
put systemd/fleet-agent.service 644 /etc/systemd/system/fleet-agent.service
put systemd/fleet-agent.timer 644 /etc/systemd/system/fleet-agent.timer
if getent group docker >/dev/null; then
  mkdir -p /etc/systemd/system/fleet-agent.service.d
  put systemd/docker.conf 644 /etc/systemd/system/fleet-agent.service.d/docker.conf
fi

umask 077
{
  echo "FLEET_HOST=$FLEET_HOST"
  echo "FLEET_KEY=$FLEET_KEY"
  [[ -n "${FLEET_URL:-}" ]] && echo "FLEET_URL=$FLEET_URL"
  [[ -n "${FLEET_CONTAINERS:-}" ]] && echo "FLEET_CONTAINERS=$FLEET_CONTAINERS"
} > /etc/fleet-agent.env

systemctl daemon-reload
systemctl enable -q --now fleet-agent.timer
systemctl start fleet-agent.service
systemctl list-timers fleet-agent.timer --no-pager | head -2
