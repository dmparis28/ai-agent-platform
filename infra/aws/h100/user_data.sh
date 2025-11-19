#!/bin/bash
# H100 Instance Initialization Script

set -e

echo "Starting H100 initialization..."

# Update system
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Install NVIDIA drivers
apt-get install -y ubuntu-drivers-common linux-headers-$(uname -r)
ubuntu-drivers autoinstall

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

apt-get update
apt-get install -y nvidia-container-toolkit
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
apt-get install -y unzip
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Create directories
mkdir -p /opt/h100/{neo4j,faiss,redis,snapshots,grpc-server}
mkdir -p /var/log/h100

# Install Neo4j container
docker run -d \
  --name neo4j \
  --restart unless-stopped \
  -p 7474:7474 -p 7687:7687 \
  -v /opt/h100/neo4j:/data \
  -e NEO4J_AUTH=neo4j/$(openssl rand -base64 32) \
  -e NEO4J_server_memory_heap_initial__size=4G \
  -e NEO4J_server_memory_heap_max__size=8G \
  neo4j:5.14

# Install Redis container
docker run -d \
  --name redis \
  --restart unless-stopped \
  -p 6379:6379 \
  -v /opt/h100/redis:/data \
  redis:7.2-alpine redis-server \
    --appendonly yes \
    --maxmemory 8gb \
    --maxmemory-policy allkeys-lru

# Install Python and dependencies
apt-get install -y python3-pip python3-dev build-essential
pip3 install --upgrade pip

pip3 install \
  grpcio==1.59.0 \
  grpcio-tools==1.59.0 \
  neo4j==5.14.0 \
  redis==5.0.1 \
  faiss-gpu==1.7.4 \
  boto3==1.29.0 \
  numpy==1.24.3 \
  sentence-transformers==2.2.2

# Create snapshot script
cat > /usr/local/bin/snapshot-to-s3.sh << 'SNAPSHOT_EOF'
#!/bin/bash
set -e

BUCKET="${s3_snapshot_bucket}"
REGION="${aws_region}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "[$(date)] Starting snapshot to S3..."

# Snapshot Neo4j
docker exec neo4j neo4j-admin database dump neo4j --to-path=/tmp
DUMP_FILE=$(docker exec neo4j ls -t /tmp | grep neo4j.*dump | head -1)
docker cp neo4j:/tmp/$DUMP_FILE /opt/h100/snapshots/neo4j-$TIMESTAMP.dump

# Snapshot FAISS indexes
if [ -d /opt/h100/faiss ] && [ "$(ls -A /opt/h100/faiss)" ]; then
  tar -czf /opt/h100/snapshots/faiss-$TIMESTAMP.tar.gz -C /opt/h100 faiss/
fi

# Snapshot Redis
docker exec redis redis-cli BGSAVE
sleep 5
docker cp redis:/data/dump.rdb /opt/h100/snapshots/redis-$TIMESTAMP.rdb

# Upload to S3
aws s3 sync /opt/h100/snapshots/ s3://$BUCKET/h100-snapshots/ \
  --region $REGION \
  --exclude "*" \
  --include "*-$TIMESTAMP.*"

# Create manifest
cat > /opt/h100/snapshots/manifest-$TIMESTAMP.json << MANIFEST_EOF
{
  "timestamp": "$TIMESTAMP",
  "neo4j": "neo4j-$TIMESTAMP.dump",
  "faiss": "faiss-$TIMESTAMP.tar.gz",
  "redis": "redis-$TIMESTAMP.rdb",
  "region": "$REGION"
}
MANIFEST_EOF

aws s3 cp /opt/h100/snapshots/manifest-$TIMESTAMP.json \
  s3://$BUCKET/h100-snapshots/latest-manifest.json \
  --region $REGION

# Cleanup old local snapshots (keep last 3)
ls -t /opt/h100/snapshots/neo4j-*.dump | tail -n +4 | xargs -r rm
ls -t /opt/h100/snapshots/faiss-*.tar.gz | tail -n +4 | xargs -r rm
ls -t /opt/h100/snapshots/redis-*.rdb | tail -n +4 | xargs -r rm

echo "[$(date)] Snapshot complete"
SNAPSHOT_EOF

chmod +x /usr/local/bin/snapshot-to-s3.sh

# Create restore script
cat > /usr/local/bin/restore-from-s3.sh << 'RESTORE_EOF'
#!/bin/bash
set -e

BUCKET="${s3_snapshot_bucket}"
REGION="${aws_region}"

echo "[$(date)] Restoring from S3..."

# Download latest manifest
aws s3 cp s3://$BUCKET/h100-snapshots/latest-manifest.json \
  /tmp/manifest.json \
  --region $REGION || {
    echo "No snapshots found. Starting fresh."
    exit 0
  }

# Parse manifest
NEO4J_FILE=$(jq -r '.neo4j' /tmp/manifest.json)
FAISS_FILE=$(jq -r '.faiss' /tmp/manifest.json)
REDIS_FILE=$(jq -r '.redis' /tmp/manifest.json)

# Download snapshots
aws s3 cp s3://$BUCKET/h100-snapshots/$NEO4J_FILE /opt/h100/snapshots/ --region $REGION || true
aws s3 cp s3://$BUCKET/h100-snapshots/$FAISS_FILE /opt/h100/snapshots/ --region $REGION || true
aws s3 cp s3://$BUCKET/h100-snapshots/$REDIS_FILE /opt/h100/snapshots/ --region $REGION || true

# Restore Neo4j
if [ -f "/opt/h100/snapshots/$NEO4J_FILE" ]; then
  echo "Restoring Neo4j..."
  docker stop neo4j || true
  docker rm neo4j || true
  
  docker run -d \
    --name neo4j \
    --restart unless-stopped \
    -p 7474:7474 -p 7687:7687 \
    -v /opt/h100/neo4j:/data \
    -e NEO4J_AUTH=neo4j/$(openssl rand -base64 32) \
    neo4j:5.14
  
  sleep 10
  docker cp /opt/h100/snapshots/$NEO4J_FILE neo4j:/tmp/restore.dump
  docker exec neo4j neo4j-admin database load neo4j --from-path=/tmp --overwrite-destination=true
  docker restart neo4j
fi

# Restore FAISS
if [ -f "/opt/h100/snapshots/$FAISS_FILE" ]; then
  echo "Restoring FAISS..."
  tar -xzf /opt/h100/snapshots/$FAISS_FILE -C /opt/h100/
fi

# Restore Redis
if [ -f "/opt/h100/snapshots/$REDIS_FILE" ]; then
  echo "Restoring Redis..."
  docker stop redis
  cp /opt/h100/snapshots/$REDIS_FILE /opt/h100/redis/dump.rdb
  docker start redis
fi

echo "[$(date)] Restore complete"
RESTORE_EOF

chmod +x /usr/local/bin/restore-from-s3.sh

# Restore on first boot
/usr/local/bin/restore-from-s3.sh || echo "First boot, no snapshots to restore"

# Create idle monitor
cat > /opt/h100/idle-monitor.py << 'IDLE_EOF'
#!/usr/bin/env python3
import time
import subprocess
import boto3
import requests
from datetime import datetime

IDLE_THRESHOLD = 1800  # 30 minutes
CHECK_INTERVAL = 60    # 1 minute

ec2 = boto3.client('ec2')

# Get instance ID
response = requests.get('http://169.254.169.254/latest/meta-data/instance-id', timeout=5)
instance_id = response.text

last_activity = time.time()

print(f"[{datetime.now()}] H100 Idle Monitor started. Instance: {instance_id}")
print(f"[{datetime.now()}] Idle threshold: {IDLE_THRESHOLD/60} minutes")

while True:
    time.sleep(CHECK_INTERVAL)
    
    current_time = time.time()
    idle_time = current_time - last_activity
    
    # Check for network activity (agents connecting)
    try:
        result = subprocess.run(
            ['netstat', '-an', '|', 'grep', ':50051.*ESTABLISHED', '|', 'wc', '-l'],
            shell=True,
            capture_output=True,
            text=True
        )
        connections = int(result.stdout.strip() or 0)
        
        if connections > 0:
            last_activity = current_time
            print(f"[{datetime.now()}] Activity detected: {connections} active connections")
            continue
    except:
        pass
    
    print(f"[{datetime.now()}] Idle for {idle_time/60:.1f} minutes")
    
    if idle_time > IDLE_THRESHOLD:
        print(f"[{datetime.now()}] Idle threshold exceeded. Shutting down...")
        
        # Create snapshot
        subprocess.run(['/usr/local/bin/snapshot-to-s3.sh'])
        
        # Stop instance
        ec2.stop_instances(InstanceIds=[instance_id])
        break
IDLE_EOF

chmod +x /opt/h100/idle-monitor.py

# Create systemd service for idle monitor
cat > /etc/systemd/system/h100-idle-monitor.service << 'SERVICE_EOF'
[Unit]
Description=H100 Idle Monitor
After=network.target docker.service

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/h100/idle-monitor.py
Restart=always
RestartSec=10
StandardOutput=append:/var/log/h100/idle-monitor.log
StandardError=append:/var/log/h100/idle-monitor.log

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# Start idle monitor
systemctl daemon-reload
systemctl enable h100-idle-monitor
systemctl start h100-idle-monitor

# Setup daily snapshot cron
echo "0 2 * * * root /usr/local/bin/snapshot-to-s3.sh >> /var/log/h100/snapshot.log 2>&1" > /etc/cron.d/h100-snapshot

echo "H100 initialization complete"
