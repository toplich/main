#!/bin/bash

TELEPORT_VERSION="17.4.8"
TELEPORT_DOMAIN="hop.topli.ch"
TOKEN=""

NODE_NAME="proxy-${HOSTNAME}"
BASE_DIR="$HOME/teleport"
DOCKER_IMAGE="public.ecr.aws/gravitational/teleport-distroless:${TELEPORT_VERSION}"

mkdir -p "$BASE_DIR/config $BASE_DIR/data"

# ==== create token ====
cat > "$BASE_DIR/data/token" <<EOF
${TOKEN}
EOF

# ==== create teleport.yaml ====
cat > "$BASE_DIR/config/teleport.yaml" <<EOF
version: v3
teleport:
  nodename: ${NODE_NAME}
  proxy_server: "$TELEPORT_DOMAIN":443
  auth_token: "/var/lib/teleport/token"
  data_dir: /var/lib/teleport
  log:
    output: stderr
    severity: INFO

windows_desktop_service:
  enabled: "no"
  static_hosts:
  - name: win-test
    ad: false
    addr: 192.168.1.10:3389
    labels:
      department: admin

app_service:
  enabled: "no"
  apps:
  - name: proxmox
    uri: "https://192.168.1.2:8006"
    public_addr: "proxmox.${TELEPORT_DOMAIN}"
    insecure_skip_verify: true
    labels:
      env: "proxmox"

ssh_service:
  enabled: "no"
  labels:
    host: proxmox
    teleport.internal/resource-id: 

proxy_service:
  enabled: false
auth_service:
  enabled: false
EOF


# ==== create docker-compose.yml ====
cat > "$BASE_DIR/docker-compose.yml" <<EOF
version: '3.8'

services:
  ${NODE_NAME}:
    image: ${DOCKER_IMAGE}
    container_name: ${NODE_NAME}
    volumes:
      - ./config:/etc/teleport
      - ./data:/var/lib/teleport
    restart: unless-stopped
    network_mode: "host"
EOF

# ==== START TELEPORT PROXY ====
cd "$BASE_DIR"
docker compose up -d

echo "✅ Teleport Proxy started ${NODE_NAME}"
