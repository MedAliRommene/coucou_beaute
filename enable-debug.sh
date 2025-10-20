#!/bin/bash
echo "Enabling DEBUG mode temporarily..."
ssh vpsuser@196.203.120.35 << 'EOF'
cd /opt/coucou_beaute
# Backup current env
docker exec coucou_web cat /app/.env > /tmp/env_backup.txt 2>/dev/null || true

# Enable DEBUG
docker exec coucou_web sh -c "echo 'DJANGO_DEBUG=True' >> /app/.env"

# Restart web container
docker compose -f docker-compose.prod.yml restart web

echo "DEBUG enabled. Check https://196.203.120.35/ to see the error"
echo "After checking, run: docker compose -f docker-compose.prod.yml restart web"
EOF

