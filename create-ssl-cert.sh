#!/bin/bash
# Script pour créer un certificat SSL plus complet

set -euo pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "🔐 Création d'un certificat SSL amélioré..."

# Aller dans le répertoire du projet
cd /opt/coucou_beaute

# Créer le dossier ssl s'il n'existe pas
mkdir -p ssl

# Créer un fichier de configuration OpenSSL
cat > ssl/openssl.conf << 'EOF'
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = TN
ST = Tunisia
L = Tunis
O = CoucouBeaute
CN = 196.203.120.35

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
IP.1 = 196.203.120.35
DNS.1 = localhost
EOF

# Créer le certificat avec SAN
log "📜 Génération du certificat avec SAN..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/privkey.pem \
    -out ssl/fullchain.pem \
    -config ssl/openssl.conf \
    -extensions v3_req

# Vérifier le certificat
log "🔍 Vérification du certificat..."
openssl x509 -in ssl/fullchain.pem -text -noout | grep -A 5 "Subject Alternative Name"

# Redémarrer Nginx
log "🔄 Redémarrage de Nginx..."
docker compose -f docker-compose.prod.yml restart nginx

log "✅ Certificat SSL amélioré créé!"
log "🌐 Testez maintenant: https://196.203.120.35"
