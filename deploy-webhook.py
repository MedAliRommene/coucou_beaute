#!/usr/bin/env python3
"""
Webhook de déploiement automatique pour Coucou Beauté
Écoute les webhooks GitHub et déploie automatiquement
"""

import os
import json
import subprocess
import hmac
import hashlib
from flask import Flask, request, jsonify
from datetime import datetime

app = Flask(__name__)

# Configuration
WEBHOOK_SECRET = os.getenv('WEBHOOK_SECRET', 'votre_secret_webhook')
PROJECT_DIR = '/opt/coucou_beaute'
LOG_FILE = '/var/log/coucou_beaute_deploy.log'

def log_message(message):
    """Log un message avec timestamp"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    log_entry = f"[{timestamp}] {message}\n"
    with open(LOG_FILE, 'a') as f:
        f.write(log_entry)
    print(log_entry.strip())

def verify_webhook_signature(payload, signature):
    """Vérifie la signature du webhook GitHub"""
    if not signature:
        return False
    
    # GitHub envoie la signature avec 'sha256=' prefix
    if signature.startswith('sha256='):
        signature = signature[7:]
    
    expected_signature = hmac.new(
        WEBHOOK_SECRET.encode('utf-8'),
        payload,
        hashlib.sha256
    ).hexdigest()
    
    return hmac.compare_digest(signature, expected_signature)

def deploy_application():
    """Exécute le déploiement"""
    try:
        log_message("🚀 Début du déploiement...")
        
        # Aller dans le répertoire du projet
        os.chdir(PROJECT_DIR)
        
        # Récupérer les dernières modifications
        log_message("📥 Récupération des modifications...")
        subprocess.run(['git', 'pull', 'origin', 'main'], check=True)
        
        # Arrêter les services
        log_message("⏹️ Arrêt des services...")
        subprocess.run(['docker', 'compose', '-f', 'docker-compose.prod.yml', 'down'], 
                      check=True, capture_output=True)
        
        # Reconstruire et redémarrer
        log_message("🔨 Reconstruction et redémarrage...")
        subprocess.run(['docker', 'compose', '-f', 'docker-compose.prod.yml', 'up', '-d', '--build'], 
                      check=True)
        
        log_message("✅ Déploiement terminé avec succès!")
        return True
        
    except subprocess.CalledProcessError as e:
        log_message(f"❌ Erreur lors du déploiement: {e}")
        return False
    except Exception as e:
        log_message(f"❌ Erreur inattendue: {e}")
        return False

@app.route('/webhook', methods=['POST'])
def webhook():
    """Endpoint webhook GitHub"""
    try:
        # Vérifier la signature
        signature = request.headers.get('X-Hub-Signature-256')
        if not verify_webhook_signature(request.data, signature):
            log_message("❌ Signature webhook invalide")
            return jsonify({'error': 'Unauthorized'}), 401
        
        # Parser le payload
        payload = request.get_json()
        
        # Vérifier que c'est un push sur la branche main
        if payload.get('ref') == 'refs/heads/main':
            log_message("📝 Push détecté sur la branche main")
            
            # Déployer
            if deploy_application():
                return jsonify({'status': 'success', 'message': 'Deployment completed'})
            else:
                return jsonify({'status': 'error', 'message': 'Deployment failed'}), 500
        else:
            log_message(f"ℹ️ Push sur branche {payload.get('ref')} - ignoré")
            return jsonify({'status': 'ignored', 'message': 'Not main branch'})
            
    except Exception as e:
        log_message(f"❌ Erreur webhook: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/health', methods=['GET'])
def health():
    """Endpoint de santé"""
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})

@app.route('/deploy', methods=['POST'])
def manual_deploy():
    """Déploiement manuel"""
    if deploy_application():
        return jsonify({'status': 'success', 'message': 'Manual deployment completed'})
    else:
        return jsonify({'status': 'error', 'message': 'Manual deployment failed'}), 500

if __name__ == '__main__':
    log_message("🔧 Démarrage du webhook de déploiement...")
    app.run(host='0.0.0.0', port=5000, debug=False)
