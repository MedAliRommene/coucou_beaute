#!/bin/bash
# ===========================================
# SCRIPT DE CONFIGURATION CI/CD - Coucou Beauté
# ===========================================

set -e

echo "🚀 Configuration du CI/CD pour Coucou Beauté..."

# ===========================================
# 1. VÉRIFICATION DES PRÉREQUIS
# ===========================================
echo "🔍 Vérification des prérequis..."

# Vérifier Git
if ! command -v git &> /dev/null; then
    echo "❌ Git n'est pas installé"
    exit 1
fi

# Vérifier Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé"
    exit 1
fi

# Vérifier Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose n'est pas installé"
    exit 1
fi

echo "✅ Prérequis vérifiés"

# ===========================================
# 2. CONFIGURATION GIT
# ===========================================
echo "📝 Configuration Git..."

# Vérifier si c'est un repository Git
if [ ! -d ".git" ]; then
    echo "🔧 Initialisation du repository Git..."
    git init
    git add .
    git commit -m "Initial commit: Setup CI/CD"
fi

# Vérifier la branche main
if [ "$(git branch --show-current)" != "main" ]; then
    echo "🔧 Basculement vers la branche main..."
    git checkout -b main
fi

echo "✅ Git configuré"

# ===========================================
# 3. CONFIGURATION DES ENVIRONNEMENTS
# ===========================================
echo "⚙️ Configuration des environnements..."

# Créer le fichier .env local s'il n'existe pas
if [ ! -f "backend/.env" ]; then
    echo "📝 Création du fichier .env local..."
    cp backend/env.example backend/.env
    echo "⚠️  Configurez votre fichier backend/.env !"
fi

echo "✅ Environnements configurés"

# ===========================================
# 4. TEST DES WORKFLOWS
# ===========================================
echo "🧪 Test des workflows..."

# Vérifier que les fichiers de workflow existent
if [ ! -f ".github/workflows/deploy.yml" ]; then
    echo "❌ Fichier deploy.yml manquant"
    exit 1
fi

if [ ! -f ".github/workflows/test.yml" ]; then
    echo "❌ Fichier test.yml manquant"
    exit 1
fi

if [ ! -f ".github/workflows/release.yml" ]; then
    echo "❌ Fichier release.yml manquant"
    exit 1
fi

echo "✅ Workflows configurés"

# ===========================================
# 5. CONFIGURATION DOCKER
# ===========================================
echo "🐳 Configuration Docker..."

# Tester la construction de l'image
echo "🔨 Test de construction de l'image Docker..."
cd backend
docker build -t coucou-beaute:test .
cd ..

echo "✅ Docker configuré"

# ===========================================
# 6. INSTRUCTIONS FINALES
# ===========================================
echo ""
echo "🎉 Configuration CI/CD terminée !"
echo ""
echo "📋 Prochaines étapes :"
echo ""
echo "1. 🔐 Configurez les secrets GitHub :"
echo "   - Allez sur Settings > Secrets and variables > Actions"
echo "   - Ajoutez les secrets listés dans .github/SECRETS.md"
echo ""
echo "2. 📤 Poussez votre code :"
echo "   git add ."
echo "   git commit -m 'Setup CI/CD'"
echo "   git push origin main"
echo ""
echo "3. 🚀 Testez le déploiement :"
echo "   - Créez une Pull Request"
echo "   - Vérifiez que les tests passent"
echo "   - Mergez pour déclencher le déploiement"
echo ""
echo "4. 🏷️ Créez une release :"
echo "   git tag v1.0.0"
echo "   git push origin v1.0.0"
echo ""
echo "📚 Documentation complète dans DEPLOYMENT.md"
echo "🔧 Configuration des secrets dans .github/SECRETS.md"
echo ""
echo "✅ Configuration terminée !"
