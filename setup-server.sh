#!/usr/bin/env bash
# Richtet ein altes (Linux-)MacBook als Server/Zugangs-Rechner ein.
# Getestet für Ubuntu / Debian / Linux Mint (apt-basiert).
set -e

if ! command -v apt >/dev/null; then
  echo "Dieses Skript braucht Ubuntu/Debian (apt). Abbruch."; exit 1
fi

echo "==> 1/6 System aktualisieren"
sudo apt update
sudo apt full-upgrade -y

echo "==> 2/6 Werkzeuge installieren"
sudo apt install -y openssh-server git curl wget tmux htop mosh ufw fail2ban unattended-upgrades

echo "==> 3/6 SSH-Server + Firewall"
sudo systemctl enable --now ssh
sudo ufw allow OpenSSH
sudo ufw allow 60000:61000/udp   # mosh
sudo ufw --force enable
sudo systemctl enable --now fail2ban unattended-upgrades

echo "==> 4/6 Deckel zu = kein Standby (Laptop läuft als Server weiter)"
sudo mkdir -p /etc/systemd/logind.conf.d
printf '[Login]\nHandleLidSwitch=ignore\nHandleLidSwitchExternalPower=ignore\nHandleLidSwitchDocked=ignore\n' \
  | sudo tee /etc/systemd/logind.conf.d/server.conf >/dev/null
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

echo "==> 5/6 SSH-Schlüssel (für Verbindungen zu anderen Servern)"
[ -f ~/.ssh/id_ed25519 ] || ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
echo "Dein öffentlicher Schlüssel (auf Ziel-Servern eintragen):"
cat ~/.ssh/id_ed25519.pub

echo "==> 6/6 Tailscale (sicherer Zugriff von iPhone/iPad/Mac, überall)"
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --ssh

echo
echo "FERTIG! Name im Tailscale-Netz: $(hostname)  |  IP: $(tailscale ip -4 2>/dev/null)"
echo "Jetzt einmal neu starten:  sudo reboot"
