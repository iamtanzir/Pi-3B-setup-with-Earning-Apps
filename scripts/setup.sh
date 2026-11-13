#!/usr/bin/env bash
# ============================================================================
#  Pi-3B full setup — Pi-hole + Honeygain (Docker) + optional EarnApp
#  Idempotent-ish, copy-paste friendly. Run from the repo root:
#
#      cp .env.example .env   # then edit .env
#      bash scripts/setup.sh                 # Pi-hole + Honeygain
#      bash scripts/setup.sh --with-earnapp  # also installs EarnApp (interactive)
#      bash scripts/setup.sh --yes           # skip the interactive ToS checklist
#
#  What this script does NOT do:
#    - It does NOT bypass Honeygain/EarnApp anti-cheat or detection.
#      Bypassing those systems violates their Terms of Service and gets
#      accounts and IPs banned. The checklist below is the legitimate way
#      to keep your IP in good standing.
# ============================================================================
set -euo pipefail

WITH_EARNAPP=0
ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    --with-earnapp) WITH_EARNAPP=1 ;;
    --yes|-y)       ASSUME_YES=1 ;;
    -h|--help)      sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "Unknown option: $arg (try --help)" >&2; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

log()  { printf '\033[0;32m[setup]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n'  "$*"; }
die()  { printf '\033[0;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

# --- Load .env --------------------------------------------------------------
[ -f .env ] || die ".env not found. Run: cp .env.example .env  (then edit it)"
set -a; # shellcheck disable=SC1091
source .env; set +a

TZ_VALUE="${TZ:-Asia/Dhaka}"
DEVICE_NAME="${DEVICE_NAME:-pi3b-server}"
: "${PIHOLE_PASSWORD:?Set PIHOLE_PASSWORD in .env}"
: "${HONEYGAIN_EMAIL:?Set HONEYGAIN_EMAIL in .env}"
: "${HONEYGAIN_PASS:?Set HONEYGAIN_PASS in .env}"
[[ "$PIHOLE_PASSWORD" != change-me* ]] || die "PIHOLE_PASSWORD is still the placeholder — edit .env first."

# Escape single quotes for safe inclusion in YAML single-quoted strings
yaml_sq() { printf "%s" "$1" | sed "s/'/''/g"; }
PIHOLE_PASSWORD_Y=$(yaml_sq "$PIHOLE_PASSWORD")
HONEYGAIN_EMAIL_Y=$(yaml_sq "$HONEYGAIN_EMAIL")
HONEYGAIN_PASS_Y=$(yaml_sq "$HONEYGAIN_PASS")
DEVICE_NAME_Y=$(yaml_sq "$DEVICE_NAME")
TZ_Y=$(yaml_sq "$TZ_VALUE")

# --- Legitimacy checklist (the honest anti-block strategy) ------------------
echo
echo "  Before deploying, confirm ALL of the following (Honeygain ToS):"
echo "    [1] This Pi is on a genuine residential internet connection"
echo "    [2] You are NOT behind a VPN, proxy, Tor or data-center/VPS IP"
echo "    [3] This Honeygain account is the only account on this IP, used by you"
echo "    [4] DEVICE_NAME ('$DEVICE_NAME') is unique — never reused on another device"
echo "    [5] You accept Honeygain/EarnApp Terms of Use (bandwidth sharing)"
echo
if [ "$ASSUME_YES" -ne 1 ]; then
  read -r -p "  Confirm all of the above? [y/N] " reply
  [[ "$reply" =~ ^[yY]$ ]] || die "Aborted — fix the above first, otherwise your IP/account will be blocked."
fi

# --- System packages ----------------------------------------------------------
log "Updating system packages…"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y curl ca-certificates wget
sudo timedatectl set-timezone "$TZ_VALUE"
sudo timedatectl set-ntp true

# --- Docker -------------------------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
  log "Installing Docker…"
  curl -fsSL https://get.docker.com | sudo sh
fi
sudo usermod -aG docker "$USER" || true
sudo systemctl enable --now docker

# Prefer rootless docker if the current shell already has group access,
# otherwise fall back to sudo for this run.
DOCKER="docker"
docker info >/dev/null 2>&1 || DOCKER="sudo docker"

# --- amd64 emulation for Honeygain (image is amd64-only) ---------------------
log "Enabling amd64 emulation (binfmt/QEMU)…"
$DOCKER run --privileged --rm tonistiigi/binfmt --install amd64

# --- Pi-hole ------------------------------------------------------------------
PIHOLE_DIR="$HOME/docker/pihole"
mkdir -p "$PIHOLE_DIR"
cat > "$PIHOLE_DIR/docker-compose.yml" <<YAML
services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "80:80/tcp"
    environment:
      TZ: '${TZ_Y}'
      FTLCONF_webserver_api_password: '${PIHOLE_PASSWORD_Y}'
      FTLCONF_dns_upstreams: '1.1.1.1;8.8.8.8'
    volumes:
      - './etc-pihole:/etc/pihole'
      - './etc-dnsmasq.d:/etc/dnsmasq.d'
    restart: unless-stopped
YAML

# --- Honeygain -----------------------------------------------------------------
HONEYGAIN_DIR="$HOME/docker/honeygain"
mkdir -p "$HONEYGAIN_DIR"
cat > "$HONEYGAIN_DIR/docker-compose.yml" <<YAML
services:
  honeygain:
    container_name: honeygain
    image: honeygain/honeygain:latest
    platform: linux/amd64
    # argv list — robust against special characters in passwords
    command:
      - '-tou-accept'
      - '-email'
      - '${HONEYGAIN_EMAIL_Y}'
      - '-pass'
      - '${HONEYGAIN_PASS_Y}'
      - '-device'
      - '${DEVICE_NAME_Y}'
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
YAML

log "Starting Pi-hole…"
( cd "$PIHOLE_DIR"   && $DOCKER compose up -d )
log "Starting Honeygain…"
( cd "$HONEYGAIN_DIR" && $DOCKER compose up -d )

# --- EarnApp (optional, interactive) -------------------------------------------
if [ "$WITH_EARNAPP" -eq 1 ]; then
  log "Installing EarnApp (official installer — follow the prompts)…"
  wget -qO /tmp/earnapp.sh https://brightdata.com/static/earnapp/install.sh
  sudo bash /tmp/earnapp.sh
  log "Pair the device with:  earnapp register"
fi

# --- Verification ---------------------------------------------------------------
echo
log "Done. Status:"
$DOCKER ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
echo
echo "  Pi-hole admin : http://$(hostname -I | awk '{print $1}')/admin"
echo "  Honeygain     : check your dashboard — device '${DEVICE_NAME}' should appear as running"
[ "$WITH_EARNAPP" -eq 1 ] && echo "  EarnApp       : earnapp status   /   pair with: earnapp register"
echo
warn "If Pi-hole fails with port 53 in use: sudo ss -tulpn | grep ':53'"
warn "Re-login (or 'newgrp docker') so 'docker' works without sudo."
