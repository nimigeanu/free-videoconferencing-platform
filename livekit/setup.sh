#!/bin/bash

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <domain> <record> <ACCESS_KEY> <ACCESS_KEY_ID>"
  exit 1
fi

DOMAIN=$1
ID=$2
RECORD1="$ID.$DOMAIN";
RECORD2="turn.$ID.$DOMAIN";
ACCESS_KEY=$3
ACCESS_KEY_ID=$4

WAIT_TIME=10 # seconds to wait between checks

echo "Waiting for DNS record $RECORD1 to become available..."

while true; do
  if dig @8.8.8.8 +nocmd "$RECORD1" a +noall +answer | grep -q "^"; then
    echo "DNS record $RECORD1 is now available."
    break
  else
    echo "DNS record $RECORD1 not found. Checking again in $WAIT_TIME seconds..."
    sleep $WAIT_TIME
  fi
done

echo "Waiting for DNS record $RECORD2 to become available..."

while true; do
  if dig @8.8.8.8 +nocmd "$RECORD2" a +noall +answer | grep -q "^"; then
    echo "DNS record $RECORD2 is now available."
    break
  else
    echo "DNS record $RECORD2 not found. Checking again in $WAIT_TIME seconds..."
    sleep $WAIT_TIME
  fi
done

# Proceed with the rest of your script
echo "Continuing with the script..."

# create directories for LiveKit
mkdir -p /opt/livekit/caddy_data
mkdir -p /usr/local/bin

# Docker & Docker Compose will need to be installed on the machine
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sh /tmp/get-docker.sh
curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod 755 /usr/local/bin/docker-compose

sudo systemctl enable docker

# livekit config
cat << EOF > /opt/livekit/livekit.yaml
port: 7880
bind_addresses:
    - ""
rtc:
    tcp_port: 7881
    port_range_start: 50000
    port_range_end: 60000
    use_external_ip: true
    enable_loopback_candidate: false
redis:
    address: localhost:6379
    username: ""
    password: ""
    db: 0
    use_tls: false
    sentinel_master_name: ""
    sentinel_username: ""
    sentinel_password: ""
    sentinel_addresses: []
    cluster_addresses: []
    max_redirects: null
turn:
    enabled: true
    domain: $RECORD2
    tls_port: 5349
    udp_port: 3478
    external_tls: true
keys:
    $ACCESS_KEY: $ACCESS_KEY_ID


EOF

# caddy config
cat << EOF > /opt/livekit/caddy.yaml
logging:
  logs:
    default:
      level: INFO
storage:
  "module": "file_system"
  "root": "/data"
apps:
  tls:
    certificates:
      automate:
        - $RECORD1
        - $RECORD2
  layer4:
    servers:
      main:
        listen: [":8443"]
        routes:
          - match:
            - tls:
                sni:
                  - "$RECORD2"
            handle:
              - handler: tls
              - handler: proxy
                upstreams:
                  - dial: ["localhost:5349"]
          - match:
              - tls:
                  sni:
                    - "$RECORD1"
            handle:
              - handler: tls
                connection_policies:
                  - alpn: ["http/1.1"]
              - handler: proxy
                upstreams:
                  - dial: ["localhost:7880"]


EOF

# update ip script
cat << "EOF" > /opt/livekit/update_ip.sh
#!/usr/bin/env bash
ip=`ip addr show |grep "inet " |grep -v 127.0.0. |head -1|cut -d" " -f6|cut -d/ -f1`
sed -i.orig -r "s/\\\"(.+)(\:5349)/\\\"$ip\2/" /opt/livekit/caddy.yaml


EOF

# docker compose
cat << EOF > /opt/livekit/docker-compose.yaml
# This docker-compose requires host networking, which is only available on Linux
# This compose will not function correctly on Mac or Windows
services:
  caddy:
    image: livekit/caddyl4
    command: run --config /etc/caddy.yaml --adapter yaml
    restart: unless-stopped
    network_mode: "host"
    volumes:
      - ./caddy.yaml:/etc/caddy.yaml
      - ./caddy_data:/data
  livekit:
    image: livekit/livekit-server:latest
    command: --config /etc/livekit.yaml
    restart: unless-stopped
    network_mode: "host"
    volumes:
      - ./livekit.yaml:/etc/livekit.yaml
  redis:
    image: redis:7-alpine
    command: redis-server /etc/redis.conf
    restart: unless-stopped
    network_mode: "host"
    volumes:
      - ./redis.conf:/etc/redis.conf


EOF

# systemd file
cat << EOF > /etc/systemd/system/livekit-docker.service
[Unit]
Description=LiveKit Server Container
After=docker.service
Requires=docker.service

[Service]
LimitNOFILE=500000
Restart=always
WorkingDirectory=/opt/livekit
# Shutdown container (if running) when unit is started
ExecStartPre=/usr/local/bin/docker-compose -f docker-compose.yaml down
ExecStart=/usr/local/bin/docker-compose -f docker-compose.yaml up
ExecStop=/usr/local/bin/docker-compose -f docker-compose.yaml down

[Install]
WantedBy=multi-user.target


EOF
# redis config
cat << EOF > /opt/livekit/redis.conf
bind 127.0.0.1 ::1
protected-mode yes
port 6379
timeout 0
tcp-keepalive 300


EOF

chmod 755 /opt/livekit/update_ip.sh
/opt/livekit/update_ip.sh

systemctl enable livekit-docker
systemctl start livekit-docker
