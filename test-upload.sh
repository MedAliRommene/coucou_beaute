#!/bin/bash
# Script pour tester les uploads en production

set -euo pipefail

IP_ADDRESS="196.203.120.35"
LOG_FILE="/var/log/coucou_test_upload.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "🧪 Test des uploads en production..."

# Créer un fichier de test
TEST_FILE="/tmp/test_upload.jpg"
echo "Test image content" > "$TEST_FILE"

# Test 1: Upload via API
log "📤 Test upload via API..."
RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/upload_response.json \
    -X POST \
    -F "file=@$TEST_FILE" \
    -F "kind=profile_photo" \
    "https://$IP_ADDRESS/api/applications/upload/")

HTTP_CODE="${RESPONSE: -3}"
if [ "$HTTP_CODE" = "200" ]; then
    log "✅ Upload API réussi (HTTP $HTTP_CODE)"
    cat /tmp/upload_response.json
else
    log "❌ Upload API échoué (HTTP $HTTP_CODE)"
    cat /tmp/upload_response.json
fi

# Test 2: Vérifier les permissions des dossiers
log "📁 Vérification des permissions..."
ls -la media/ || log "❌ Dossier media non accessible"
ls -la media/applications/ || log "❌ Dossier applications non accessible"

# Test 3: Vérifier les logs Nginx
log "📄 Vérification des logs Nginx..."
docker compose -f docker-compose.prod.yml logs --tail=20 nginx | grep -i "413\|413\|upload\|client_max_body_size" || log "ℹ️ Aucune erreur d'upload dans les logs Nginx"

# Test 4: Vérifier les logs Django
log "📄 Vérification des logs Django..."
docker compose -f docker-compose.prod.yml logs --tail=20 web | grep -i "upload\|file\|media" || log "ℹ️ Aucun log d'upload dans Django"

# Nettoyer
rm -f "$TEST_FILE" /tmp/upload_response.json

log "🎉 Test terminé!"
