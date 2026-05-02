#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="https://github.com/sarkroge/shvirtd-example-python.git"
APP_DIR="/opt/shvirtd-example-python"

echo "[1/7] Installing packages"
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg git

echo "[2/7] Installing Docker if needed"
if ! command -v docker >/dev/null 2>&1; then
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc >/dev/null
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

echo "[3/7] Enabling Docker"
sudo systemctl enable --now docker

echo "[4/7] Preparing /opt"
sudo mkdir -p /opt
sudo chown "$USER:$USER" /opt

echo "[5/7] Cloning or updating repo"
if [ -d "$APP_DIR/.git" ]; then
  git -C "$APP_DIR" fetch --all
  git -C "$APP_DIR" reset --hard origin/main
else
  git clone "$REPO_URL" "$APP_DIR"
fi

echo "[6/7] Starting project"
cd "$APP_DIR"
docker compose down || true
docker compose up -d --build

echo "[7/7] Status"
docker compose ps

echo "Local check:"
curl -L http://127.0.0.1:8090 || true
