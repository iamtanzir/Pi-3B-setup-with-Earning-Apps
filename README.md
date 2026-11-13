<p align="center">
  <img src="assets/banner.png" alt="Pi-3B Setup with Earning Apps — Pi-hole, Honeygain and EarnApp on Raspberry Pi 3B" width="100%">
</p>

<h1 align="center">Pi-3B Setup with Earning Apps</h1>

<p align="center">
  <b>Raspberry Pi 3B · USB-SSD Boot · Raspberry Pi OS 64-bit Lite · Pi-hole · Honeygain · EarnApp</b><br>
  <sub>Pi 3B সেটআপ গাইড — from zero to a headless, self-hosted earning node</sub>
</p>

<p align="center">
  <img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-yellow.svg">
  <img alt="Platform" src="https://img.shields.io/badge/Platform-Raspberry%20Pi%203B-c51a4a.svg">
  <img alt="OS" src="https://img.shields.io/badge/OS-Raspberry%20Pi%20OS%20Lite%2064--bit-A22846.svg">
  <img alt="Docker" src="https://img.shields.io/badge/Docker-amd64%20emulation%20for%20Honeygain-2496ED.svg">
</p>

---

## 📖 What is this?

A complete, beginner-friendly, step-by-step guide to turn a **Raspberry Pi 3B** into a headless, always-on server that:

| Service | Runs as | Purpose |
|---|---|---|
| **Pi-hole** | Docker container | Network-wide ad blocking / local DNS |
| **Honeygain** | Docker container (amd64 emulated) | Share unused bandwidth for credits/cash |
| **EarnApp** | Native `systemd` service | Share unused bandwidth for cash |

Everything is 64-bit compatible, resource-optimized for the Pi 3B's limited RAM (1 GB), and written from scratch — no prior Linux knowledge required.

---

## 🚀 Quick Deploy (copy-paste)

After completing Parts 1–4 (USB boot + SSD + base OS + Docker), you can deploy everything with one script:

```bash
git clone https://github.com/iamtanzir/Pi-3B-setup-with-Earning-Apps.git
cd Pi-3B-setup-with-Earning-Apps
cp .env.example .env
nano .env                     # fill in PIHOLE_PASSWORD, HONEYGAIN_EMAIL, HONEYGAIN_PASS, DEVICE_NAME
bash scripts/setup.sh                 # Pi-hole + Honeygain
bash scripts/setup.sh --with-earnapp  # + EarnApp (interactive installer)
```

The script updates the OS, installs Docker, enables amd64 emulation, writes both compose files and starts both containers. It asks you to confirm the Honeygain legitimacy checklist first (see below). **`.env` is gitignored — never commit real credentials.**

---

## 🛡️ Why Honeygain blocks IPs — and the honest fix

Honeygain's anti-fraud system blocks IPs/accounts that look abusive. **No script can or should "beat" it** — this repo contains no anti-cheat bypass, and neither should yours. The real reasons for bans, and the fixes:

| Cause of block | ToS-compliant fix |
|---|---|
| VPN / proxy / Tor / data-center or VPS IP | Run on your **genuine residential connection** only |
| Multiple accounts on one IP | One account, one household, one IP |
| Duplicate `-device` name on several containers | Use a unique `DEVICE_NAME` per device (set in `.env`) |
| Restarting/recreating the container constantly (looks like churn/farming) | Let it run stably 24/7 with `restart: unless-stopped` |
| Emulators/VMs designed to spoof humans | Run on the real Pi 3B, not nested VMs |
| Outdated client / modified app | Always pull `honeygain/honeygain:latest` |

If your IP is **already** blocked: stop the containers, wait out the block (or contact Honeygain support), remove any VPN/proxy on the router, and reconnect on a clean residential IP with a fresh device name. Attempting to hide the block behind another identity violates their ToS and risks a permanent account ban.

**The bottom line:** the Pi 3B setup in this repo — real hardware, residential IP, one account, unique device name — is the legitimate way to earn. That is the only unblockable configuration.

---

## 🏗️ Final Architecture

```
SSD Boot (USB 3.0)
└── Raspberry Pi OS Lite (64-bit)
    ├── Docker
    │   ├── Pi-hole container        (pihole_network, ports 53/80)
    │   └── Honeygain container      (linux/amd64 via binfmt/QEMU)
    └── EarnApp                      (native systemd service)
```

---

## 🧰 Hardware Requirements

1. Raspberry Pi 3B (1 GB RAM)
2. 120 GB (or larger) SATA SSD
3. USB 3.0 → SATA adapter (UASP-supported recommended)
4. 5V 2.5A power adapter (official recommended)
5. Passive heatsink / small fan
6. MicroSD card (≥ 8 GB) — needed **once** to enable USB boot
7. HDMI monitor + keyboard (first boot only; headless afterwards)
8. Ethernet cable or Wi-Fi

## 💻 Software Stack

1. Raspberry Pi OS Lite **64-bit**
2. Docker Engine (Pi-hole + Honeygain)
3. `binfmt_misc` / QEMU amd64 emulation (Honeygain ships amd64-only images)
4. EarnApp (native arm64/x64, 64-bit only)

---

## Part 1 — Enable USB Boot on the Pi 3B (one-time, via microSD)

> The Pi 3B does **not** boot from USB out of the box — you must burn a one-time OTP bit.
> (The Pi 3B+ has USB boot enabled by default; running the steps below is still harmless.)

### 1.1 Flash the microSD card
1. Download [Raspberry Pi Imager](https://www.raspberrypi.com/software/).
2. `Choose OS → Raspberry Pi OS (other) → Raspberry Pi OS Lite (64-bit)`
3. `Choose Storage → your microSD card`
4. Click the **gear (⚙) icon** and set:
   - Hostname: `pi3b-server`
   - Enable SSH (password or, better, your public key)
   - Username + password (**there is no default `pi`/`raspberry` user anymore** — you set it here)
   - Locale: `en_US.UTF-8`, timezone `Asia/Dhaka`
5. Click **Write**.

### 1.2 Boot and set the OTP bit
1. Insert the microSD into the Pi, connect HDMI + keyboard, power on.
2. Log in and update:
   ```bash
   sudo apt update && sudo apt full-upgrade -y
   ```
3. Tell the Pi to boot from USB next time. **On current 64-bit Raspberry Pi OS (Bookworm) the boot config lives in `/boot/firmware/config.txt`** (on older releases it is `/boot/config.txt`):
   ```bash
   echo 'program_usb_boot_mode=1' | sudo tee -a /boot/firmware/config.txt
   # older releases:  echo 'program_usb_boot_mode=1' | sudo tee -a /boot/config.txt
   sudo reboot
   ```
   > ⚠️ Do **not** use `rpi-eeprom-config` / `PROGRAM_USB_BOOT=1` — that is the **Pi 4** procedure and does nothing on a Pi 3B.
4. After reboot, verify the OTP bit was programmed:
   ```bash
   vcgencmd otp_dump | grep 17:
   ```
   Expected output contains `17:3020000a` (any non-zero value with bit 17 set means USB boot is enabled).
5. You may now power off and remove the microSD.

---

## Part 2 — Install the OS on the SSD

1. Connect the SSD to your PC via the USB→SATA adapter.
2. In Imager: same OS, same gear-icon settings, but select the **SSD** as storage. Double-check you picked the right device!
3. Power off the Pi, connect the SSD (no microSD inserted), power on.
4. SSH in and confirm the root filesystem lives on the SSD:
   ```bash
   ssh <user>@pi3b-server.local
   lsblk        # root should be on /dev/sda1 (or nvme0n1p2 etc.)
   ```

---

## Part 3 — Base OS Setup

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt autoremove -y && sudo apt clean

sudo timedatectl set-timezone Asia/Dhaka
sudo timedatectl set-ntp true

# Locale (en_US.UTF-8)
sudo sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen en_US.UTF-8 && sudo update-locale LANG=en_US.UTF-8

# Hostname
sudo hostnamectl set-hostname pi3b-server
grep -q pi3b-server /etc/hosts || echo '127.0.1.1   pi3b-server' | sudo tee -a /etc/hosts
sudo reboot
```

SSH hardening (recommended): edit `/etc/ssh/sshd_config`, set `PermitRootLogin no`, optionally move the port and switch to key-based auth, then `sudo systemctl restart ssh`.

Optional ZRAM (good on 1 GB RAM — replaces dphys-swapfile):
```bash
sudo apt install -y zram-tools
echo -e 'ALGO=zstd\nPERCENT=100\nPRIORITY=100' | sudo tee /etc/default/zramswap
sudo systemctl enable --now zramswap
```

---

## Part 4 — Docker Installation

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker        # or log out and back in
sudo systemctl enable --now docker
docker version
```

Reduce log growth (Pi 3B storage and RAM are limited) — `/etc/docker/daemon.json`:
```json
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
```
```bash
sudo systemctl restart docker
```

---

## Part 5 — Pi-hole (Docker)

```bash
mkdir -p ~/docker/pihole && cd ~/docker/pihole
nano docker-compose.yml
```

Pi-hole **v6** compose file:
```yaml
services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "80:80/tcp"
    environment:
      TZ: 'Asia/Dhaka'
      FTLCONF_webserver_api_password: 'CHANGE_ME_STRONG_PASSWORD'
      FTLCONF_dns_upstreams: '1.1.1.1;8.8.8.8'
    volumes:
      - './etc-pihole:/etc/pihole'
      - './etc-dnsmasq.d:/etc/dnsmasq.d'
    restart: unless-stopped
```
> On Pi-hole **v5 (legacy)** use `WEBPASSWORD='...'` and `DNS1` / `DNS2` instead of the `FTLCONF_*` variables.

```bash
docker compose up -d
docker logs pihole
```

- Admin UI: `http://<pi-ip>/admin` — log in with the password you set.
- Point your router's DHCP DNS at the Pi's IP (or set DNS per-device).
- To change the password later: edit the compose file, then `docker compose up -d --force-recreate`.

---

## Part 6 — Honeygain (Docker, amd64 emulation)

Honeygain publishes **amd64-only** images, so on the Pi 3B (arm64) you must enable QEMU/binfmt emulation first:

```bash
docker run --privileged --rm tonistiigi/binfmt --install amd64
```

`~/docker/honeygain/docker-compose.yml`:
```yaml
services:
  honeygain:
    container_name: honeygain
    image: honeygain/honeygain:latest
    platform: linux/amd64
    # Official CLI flags (https://hub.docker.com/r/honeygain/honeygain):
    command: -tou-accept -email YOU@EMAIL.COM -pass YOUR_PASSWORD -device pi3b-server
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
```

```bash
cd ~/docker/honeygain && docker compose up -d
docker logs honeygain
```

**Important notes**
- `-tou-accept` is mandatory — it accepts Honeygain's Terms of Use. Read them first: `docker run --rm honeygain/honeygain -tou-get`.
- `-device` must be **unique per running container** account-wide.
- The correct flags are `-email` / `-pass` / `-device` — the image does **not** read `EMAIL`/`PASS` env vars.
- Do **not** add a port-3000 healthcheck; Honeygain exposes no HTTP port.
- Check that the device appears as "running" on your Honeygain dashboard.

---

## Part 7 — EarnApp (native systemd service)

Official install (arm64 is supported natively — **no emulation needed**). OS must be 64-bit:

```bash
wget -qO- https://brightdata.com/static/earnapp/install.sh > /tmp/earnapp.sh && sudo bash /tmp/earnapp.sh
```

The installer creates and enables the `earnapp` systemd service automatically and prints/asks for everything. Then pair the device:

```bash
earnapp status     # is it running?
earnapp register   # prints a URL — open it in a browser and link the device to your account
earnapp showid     # device ID
earnapp upgrade    # update later
```

> ❌ Do **not** hand-write `/etc/systemd/system/earnapp.service` — overwriting the installer's unit breaks `earnapp upgrade` and service management. The stock service already starts on boot and restarts on failure.
>
> EarnApp requires a genuine residential connection. VPNs, proxies, VPS or multiple accounts violate their ToS — do not do it. Availability varies by country.

---

## Part 8 — Monitoring & Maintenance

### Temperature / CPU (`/usr/local/bin/check-temp`)
```bash
#!/bin/bash
CPU_TEMP=$(vcgencmd measure_temp | cut -d= -f2 | cut -d. -f1)
echo "CPU Temperature: ${CPU_TEMP}°C"
vcgencmd measure_clock arm
free -h
# Alert above 75°C (uses awk — bc is NOT installed by default)
if awk -v t="$CPU_TEMP" 'BEGIN{exit !(t > 75)}'; then
  echo "WARNING: High temperature detected!"
fi
```
```bash
sudo chmod +x /usr/local/bin/check-temp
(crontab -l 2>/dev/null; echo '*/5 * * * * /usr/local/bin/check-temp >> /var/log/temp-check.log') | crontab -
```

### Service health check (`/usr/local/bin/service-health`)
```bash
#!/bin/bash
echo "=== Service Health — $(date) ==="
echo "Docker:  $(systemctl is-active docker)"
echo "EarnApp: $(systemctl is-active earnapp)"
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
uptime
free -h
df -h /
```
```bash
sudo chmod +x /usr/local/bin/service-health
```

### Weekly backup of compose files (`/usr/local/bin/backup-services`)
```bash
#!/bin/bash
BACKUP_DIR="$HOME/backups/docker-compose"; DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/docker-backup-$DATE.tar.gz" "$HOME"/docker/*/docker-compose.yml 2>/dev/null
find "$BACKUP_DIR" -name '*.tar.gz' -mtime +7 -delete
echo "Backup completed: docker-backup-$DATE.tar.gz"
```
```bash
sudo chmod +x /usr/local/bin/backup-services
(crontab -l 2>/dev/null; echo '0 2 * * 0 /usr/local/bin/backup-services') | crontab -
```

### Log rotation (`/etc/logrotate.d/pi-services`)
```
/var/log/temp-check.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
}
```

---

## Part 9 — Troubleshooting

**USB boot doesn't work**
```bash
vcgencmd otp_dump | grep 17:     # expect 17:3020000a (Pi 3B only)
ls -l /boot/firmware/config.txt  # Bookworm path — NOT /boot/config.txt
```
Re-flash the microSD and repeat Part 1 if the OTP bit never got set. `rpi-eeprom-*` commands are Pi 4-only — they will mislead you here.

**Port 53 already in use / Pi-hole won't start**
```bash
sudo ss -tulpn | grep ':53'      # ss is preinstalled; netstat is NOT
# If systemd-resolved is squatting on 53 (it is NOT enabled by default on Raspberry Pi OS Lite):
sudo systemctl stop systemd-resolved && sudo systemctl disable systemd-resolved
docker restart pihole
```

**Pi-hole DNS not resolving**
```bash
docker exec pihole pihole status   # or: docker logs pihole
```
Make sure your router/device actually points DNS at the Pi.

**Honeygain not showing up on dashboard**
```bash
docker logs honeygain
```
- Did you pass `-tou-accept`? Without it the container exits silently.
- Is the `-device` name unique?
- Do you actually have amd64 emulation? Re-run the `tonistiigi/binfmt` command and `docker run --rm --platform linux/amd64 hello-world` to prove it.

**EarnApp problems**
```bash
systemctl status earnapp
sudo journalctl -u earnapp -n 50
earnapp status
```
Re-pair with `earnapp register`. Uninstall/reinstall with `earnapp uninstall` + the Part 7 script. Do **not** create custom unit files or pass proxies/VPNs.

---

## ✅ Final Verification Script (`~/check-all-services.sh`)

```bash
#!/bin/bash
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $*"; }
fail() { echo -e "${RED}✗${NC} $*"; }

echo "=== Service Status ==="
systemctl is-active --quiet docker  && ok "docker running"  || fail "docker not running"
systemctl is-active --quiet earnapp && ok "earnapp running" || fail "earnapp not running"

echo; echo "=== Containers ==="
for c in pihole honeygain; do
  docker ps --format '{{.Names}}' | grep -qx "$c" && ok "container $c running" || fail "container $c not running"
done

echo; echo "=== System Health ==="
grep PRETTY_NAME /etc/os-release
uname -m
vcgencmd measure_temp
free -h   | awk 'NR==2{printf "Memory: %s/%s used\n", $3, $2}'
df  -h /  | awk 'NR==2{printf "Disk:   %s/%s used (%s)\n", $3, $2, $5}'
docker network ls
```
```bash
chmod +x ~/check-all-services.sh
~/check-all-services.sh
```

**Routine maintenance**
```bash
# daily/weekly
~/check-all-services.sh
sudo apt update && sudo apt full-upgrade -y
docker system prune -f

# monthly
/usr/local/bin/backup-services
docker compose -f ~/docker/pihole/docker-compose.yml pull && docker compose -f ~/docker/pihole/docker-compose.yml up -d
docker compose -f ~/docker/honeygain/docker-compose.yml pull && docker compose -f ~/docker/honeygain/docker-compose.yml up -d
sudo smartctl -a /dev/sda        # needs: sudo apt install smartmontools
```

**Emergency recovery**
```bash
ssh <user>@pi3b-server.local
sudo systemctl restart docker earnapp
cd ~/docker/pihole   && docker compose up -d
cd ~/docker/honeygain && docker compose up -d
~/check-all-services.sh
```

---

## 🔗 Referral Links

Signing up through these links supports this guide (no cost to you):

- 🍯 Honeygain — <https://join.honeygain.com/TANZI74EF7>
- 💠 EarnApp — <https://earnapp.com/i/udDJugSV>
- 🕳️ Pi-hole — <https://pi-hole.net/>

---

## ⚠️ Disclaimer

- Honeygain and EarnApp pay only for genuine, consented bandwidth sharing. VPNs, proxies, multiple accounts or automated abuse will get accounts banned.
- Pi-hole is fully open-source and safe; Honeygain/EarnApp are bandwidth-sharing services — **read their Terms of Use** before running them.
- This guide is provided "as-is" without warranty. You are responsible for your own hardware and accounts.
- Earnings from bandwidth sharing are very small. Expect cents, not a salary.

---

## 📄 License

MIT © 2026 A.K.M. Tanzir Ahmed — see [LICENSE](LICENSE).
