#!/usr/bin/env python3
"""
Script pour basculer entre les environnements de configuration
Usage: python switch_env.py <local|prod>
"""

import os
import shutil
import sys
from pathlib import Path

def switch_environment(env_type):
    """Bascule vers l'environnement spécifié"""
    current_dir = Path(__file__).parent
    env_file = current_dir / '.env'
    target_env = current_dir / f'env.{env_type}'
    
    # Vérifier que le fichier cible existe
    if not target_env.exists():
        print(f"❌ Fichier d'environnement '{target_env.name}' non trouvé.")
        print(f"   Fichiers disponibles: {[f.name for f in current_dir.glob('env.*')]}")
        return False
    
    # Sauvegarder l'ancien .env s'il existe
    if env_file.exists():
        import time
        backup_file = current_dir / f'.env.backup.{int(time.time())}'
        shutil.copy2(env_file, backup_file)
        print(f"✅ Ancien .env sauvegardé comme {backup_file.name}")
    
    # Copier le nouveau fichier d'environnement
    shutil.copy2(target_env, env_file)
    print(f"✅ Basculement vers l'environnement {env_type.upper()}")
    print(f"   Source: {target_env.name}")
    print(f"   Cible: {env_file.name}")
    
    # Afficher la configuration active
    print(f"\n📋 Configuration active ({env_type.upper()}):")
    with open(env_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key = line.split('=')[0]
                if key in ['DJANGO_DEBUG', 'DJANGO_SECRET_KEY', 'DJANGO_ALLOWED_HOSTS', 
                          'CSRF_COOKIE_SECURE', 'SESSION_COOKIE_SECURE']:
                    value = line.split('=', 1)[1]
                    if key == 'DJANGO_SECRET_KEY':
                        value = value[:20] + '...' if len(value) > 20 else value
                    print(f"   {key}={value}")
    
    return True

def main():
    if len(sys.argv) != 2:
        print("Usage: python switch_env.py <local|prod>")
        print("\nEnvironnements disponibles:")
        current_dir = Path(__file__).parent
        for env_file in current_dir.glob('env.*'):
            print(f"   - {env_file.stem.replace('env.', '')}")
        sys.exit(1)
    
    env_type = sys.argv[1].lower()
    if env_type not in ['local', 'prod']:
        print(f"❌ Type d'environnement invalide: '{env_type}'")
        print("   Utilisez 'local' ou 'prod'")
        sys.exit(1)
    
    success = switch_environment(env_type)
    if success:
        print(f"\n🚀 Redémarrez votre serveur pour appliquer les changements:")
        if env_type == 'local':
            print("   python manage.py runserver")
        else:
            print("   docker compose -f docker-compose.prod.yml restart")
    else:
        sys.exit(1)

if __name__ == '__main__':
    main()
