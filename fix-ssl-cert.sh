#!/bin/bash
# Script pour corriger le certificat SSL

set -euo pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "🔧 Correction du certificat SSL..."

cd /opt/coucou_beaute

# Arrêter Nginx
log "⏹️ Arrêt de Nginx..."
docker compose -f docker-compose.prod.yml stop nginx

# Supprimer l'ancien certificat
log "🗑️ Suppression de l'ancien certificat..."
rm -f ssl/privkey.pem ssl/fullchain.pem

# Créer un nouveau certificat avec la bonne configuration
log "🔐 Création d'un nouveau certificat SSL..."

# Créer le fichier de configuration OpenSSL
cat > ssl/openssl.conf << 'EOF'
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C=TN
ST=Tunisia
L=Tunis
O=CoucouBeaute
CN=196.203.120.35

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
IP.1 = 196.203.120.35
DNS.1 = localhost
EOF

# Générer la clé privée
openssl genrsa -out ssl/privkey.pem 2048

# Générer le certificat
openssl req -new -x509 -key ssl/privkey.pem -out ssl/fullchain.pem -days 365 -config ssl/openssl.conf -extensions v3_req

# Vérifier le certificat
log "🔍 Vérification du certificat..."
openssl x509 -in ssl/fullchain.pem -text -noout | grep -A 5 "Subject Alternative Name"

# Redémarrer Nginx
log "🚀 Redémarrage de Nginx..."
docker compose -f docker-compose.prod.yml up -d nginx

# Attendre que Nginx démarre
sleep 10

# Test
log "🧪 Test de connectivité..."
if curl -kfsS "https://196.203.120.35/" > /dev/null 2>&1; then
    log "✅ Certificat SSL corrigé! Site accessible sur https://196.203.120.35"
else
    log "❌ Problème persistant. Vérifiez les logs: docker logs coucou_nginx"
fi

log "🎉 Correction terminée!"
