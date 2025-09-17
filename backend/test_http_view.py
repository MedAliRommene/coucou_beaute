#!/usr/bin/env python
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'coucou_beaute.settings')
django.setup()

from django.test import Client as TestClient
from django.contrib.auth import get_user_model
from django.urls import reverse

User = get_user_model()

def test_http_view():
    print("=== TEST HTTP VIEW ===")
    
    # Créer un client de test
    client = TestClient()
    
    # Tester avec un utilisateur qui a des rendez-vous
    username = 'client123'
    
    try:
        # 1. Récupérer l'utilisateur
        user = User.objects.get(username=username)
        print(f"1. Utilisateur: {user.username} ({user.email})")
        
        # 2. Se connecter (simuler la connexion)
        # Note: Nous devons d'abord créer un mot de passe ou utiliser un utilisateur existant
        print("2. Tentative de connexion...")
        
        # Essayer de se connecter avec le nom d'utilisateur
        login_success = client.login(username=username, password='password123')
        if not login_success:
            # Essayer avec l'email
            login_success = client.login(username=user.email, password='password123')
        
        if login_success:
            print("   ✓ Connexion réussie")
            
            # 3. Accéder à la page des rendez-vous
            print("3. Accès à la page des rendez-vous...")
            response = client.get('/client/appointments/')
            
            print(f"   - Status code: {response.status_code}")
            print(f"   - Content-Type: {response.get('Content-Type', 'N/A')}")
            
            if response.status_code == 200:
                print("   ✓ Page chargée avec succès")
                
                # 4. Analyser le contenu de la réponse
                content = response.content.decode('utf-8')
                
                # Vérifier si les rendez-vous sont présents dans le HTML
                if 'appointment-item' in content:
                    print("   ✓ Éléments 'appointment-item' trouvés dans le HTML")
                else:
                    print("   ✗ Éléments 'appointment-item' NON trouvés dans le HTML")
                
                if 'Aucun rendez-vous' in content:
                    print("   ✗ Message 'Aucun rendez-vous' trouvé (ne devrait pas être là)")
                else:
                    print("   ✓ Message 'Aucun rendez-vous' non trouvé (correct)")
                
                # Vérifier les compteurs
                if 'confirmed' in content.lower():
                    print("   ✓ Mot 'confirmed' trouvé dans le HTML")
                else:
                    print("   ✗ Mot 'confirmed' NON trouvé dans le HTML")
                
                # Compter les éléments appointment-item
                appointment_count = content.count('appointment-item')
                print(f"   - Nombre d'éléments 'appointment-item': {appointment_count}")
                
                # Vérifier les filtres
                if 'filter-btn' in content:
                    print("   ✓ Boutons de filtre trouvés")
                else:
                    print("   ✗ Boutons de filtre NON trouvés")
                
                # Afficher un extrait du HTML pour débogage
                print(f"\n4. Extrait du HTML (premiers 1000 caractères):")
                print(content[:1000])
                
            else:
                print(f"   ✗ Erreur lors du chargement de la page: {response.status_code}")
                if hasattr(response, 'content'):
                    print(f"   - Contenu: {response.content.decode('utf-8')[:500]}")
        else:
            print("   ✗ Connexion échouée")
            print("   - Vérifiez le mot de passe ou créez un utilisateur de test")
            
    except User.DoesNotExist:
        print(f"Utilisateur '{username}' non trouvé")
    except Exception as e:
        print(f"Erreur: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_http_view()
