#!/bin/bash
# ===========================================
# SCRIPT DE DÉPLOIEMENT - Coucou Beauté
# ===========================================

echo "🚀 Déploiement de Coucou Beauté..."

# ===========================================
# 1. MISE À JOUR DU CODE
# ===========================================
echo "📥 Récupération des dernières modifications..."
git pull origin main

# ===========================================
# 2. CONFIGURATION DE L'ENVIRONNEMENT
# ===========================================
echo "⚙️ Configuration de l'environnement de production..."

# Vérifier si le fichier .env existe
if [ ! -f "backend/.env" ]; then
    echo "❌ Fichier .env non trouvé !"
    echo "📝 Création du fichier .env à partir de env.example..."
    cp backend/env.example backend/.env
    echo "⚠️  IMPORTANT: Configurez votre fichier backend/.env avant de continuer !"
    echo "   Exemple: nano backend/.env"
    exit 1
fi

# ===========================================
# 3. INSTALLATION DES DÉPENDANCES
# ===========================================
echo "📦 Installation des dépendances..."
cd backend
pip install -r requirements.txt

# ===========================================
# 4. MIGRATIONS DE BASE DE DONNÉES
# ===========================================
echo "🗄️ Application des migrations..."
python manage.py migrate

# ===========================================
# 5. COLLECTE DES FICHIERS STATIQUES
# ===========================================
echo "📁 Collecte des fichiers statiques..."
python manage.py collectstatic --noinput

# ===========================================
# 6. REDÉMARRAGE DES SERVICES
# ===========================================
echo "🔄 Redémarrage des services Docker..."
cd ..
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d

# ===========================================
# 7. VÉRIFICATION DU DÉPLOIEMENT
# ===========================================
echo "✅ Vérification du déploiement..."
sleep 10

# Test de connectivité
if curl -f http://localhost:80 > /dev/null 2>&1; then
    echo "🎉 Déploiement réussi ! Site accessible sur http://$(hostname -I | awk '{print $1}')"
else
    echo "❌ Problème de déploiement. Vérifiez les logs:"
    echo "   docker compose -f docker-compose.prod.yml logs"
fi

echo "🏁 Déploiement terminé !"
