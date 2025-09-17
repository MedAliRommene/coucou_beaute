#!/usr/bin/env python
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'coucou_beaute.settings')
django.setup()

from django.contrib.auth import get_user_model
from django.test import Client as TestClient
from users.models import Client, Professional
from appointments.models import Appointment
from datetime import datetime, timedelta
from django.utils import timezone

User = get_user_model()

def test_template_fix():
    print("=== TEST TEMPLATE FIX ===")
    
    # 1. Créer ou récupérer un utilisateur de test
    username = 'testclient_template'
    password = 'testpass123'
    
    try:
        # Créer l'utilisateur s'il n'existe pas
        user, created = User.objects.get_or_create(
            username=username,
            defaults={
                'email': f'{username}@example.com',
                'password': password,
                'first_name': 'Test',
                'last_name': 'Client',
                'role': 'client'
            }
        )
        
        if created:
            user.set_password(password)
            user.save()
            print(f"✓ Utilisateur créé: {username}")
        else:
            # Corriger le rôle si nécessaire
            if hasattr(user, 'role') and user.role != 'client':
                user.role = 'client'
                user.save()
                print(f"✓ Rôle corrigé: {user.role}")
            else:
                print(f"✓ Utilisateur existant: {username}")
        
        # 2. Créer le profil client
        client_profile, created = Client.objects.get_or_create(
            user=user,
            defaults={'phone_number': '123456789', 'address': 'Test Address', 'city': 'Test City'}
        )
        if created:
            print("✓ Profil client créé")
        else:
            print("✓ Profil client existant")
        
        # 3. Créer un rendez-vous de test
        professional = Professional.objects.first()
        if professional:
            start_time = timezone.now() + timedelta(days=1)
            end_time = start_time + timedelta(hours=1)
            
            appointment = Appointment.objects.create(
                professional=professional,
                client=client_profile,
                service_name='Test Service Template',
                price=100.0,
                start=start_time,
                end=end_time,
                status='confirmed',
                notes='Rendez-vous de test avec template corrigé'
            )
            print(f"✓ Rendez-vous créé: ID {appointment.id}")
        
        # 4. Tester la vue HTTP
        print("\n4. Test de la vue HTTP...")
        
        client = TestClient()
        
        # Se connecter
        login_success = client.login(username=username, password=password)
        print(f"   Connexion: {'✓' if login_success else '✗'}")
        
        if login_success:
            # Accéder à la page des rendez-vous
            response = client.get('/client/appointments/')
            print(f"   Status: {response.status_code}")
            
            if response.status_code == 200:
                print("   ✓ Page chargée avec succès (pas d'erreur de template)")
                
                # Analyser le contenu
                content = response.content.decode('utf-8')
                
                # Vérifier les éléments clés
                if 'Test Service Template' in content:
                    print("   ✓ Service de test trouvé dans le contenu")
                else:
                    print("   ✗ Service de test NON trouvé")
                
                if 'appointment-item' in content:
                    print("   ✓ Éléments appointment-item trouvés")
                else:
                    print("   ✗ Éléments appointment-item NON trouvés")
                
                if 'TemplateSyntaxError' in content:
                    print("   ✗ Erreur de template détectée")
                else:
                    print("   ✓ Aucune erreur de template")
                
                print("   🎉 SUCCÈS ! Le template fonctionne correctement !")
                    
            elif response.status_code == 302:
                print("   ✗ Redirection détectée")
                print(f"   - Redirigé vers: {response.get('Location', 'N/A')}")
            else:
                print(f"   ✗ Erreur: {response.status_code}")
                print(f"   - Contenu: {response.content.decode('utf-8')[:500]}")
        else:
            print("   ✗ Connexion échouée")
            
    except Exception as e:
        print(f"Erreur: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_template_fix()
