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

def test_fixed_function():
    print("=== TEST FIXED FUNCTION ===")
    
    # 1. Créer ou récupérer un utilisateur de test
    username = 'testclient_fixed'
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
                'role': 'client'  # S'assurer que le rôle est 'client'
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
                service_name='Test Service Fixed',
                price=100.0,
                start=start_time,
                end=end_time,
                status='confirmed',
                notes='Rendez-vous de test avec fonction corrigée'
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
            print(f"   Location: {response.get('Location', 'N/A')}")
            
            if response.status_code == 200:
                print("   ✓ Page chargée avec succès (pas de redirection)")
                
                # Analyser le contenu
                content = response.content.decode('utf-8')
                
                # Vérifier les éléments clés
                checks = [
                    ('appointment-item', 'Éléments appointment-item'),
                    ('Test Service Fixed', 'Nom du service'),
                    ('confirmed', 'Statut confirmé'),
                    ('filter-btn', 'Boutons de filtre'),
                ]
                
                for check, description in checks:
                    if check in content:
                        print(f"   ✓ {description} trouvé")
                    else:
                        print(f"   ✗ {description} NON trouvé")
                
                # Compter les éléments
                appointment_count = content.count('appointment-item')
                print(f"   - Éléments appointment-item: {appointment_count}")
                
                # Vérifier l'état vide
                if 'Aucun rendez-vous' in content:
                    print("   ✗ Message 'Aucun rendez-vous' trouvé (ne devrait pas être là)")
                else:
                    print("   ✓ Message 'Aucun rendez-vous' non trouvé (correct)")
                
                if appointment_count > 0:
                    print("   🎉 SUCCÈS ! Les rendez-vous s'affichent maintenant !")
                    print("   ✓ La fonction ne redirige plus vers le dashboard")
                else:
                    print("   ❌ Les rendez-vous ne s'affichent toujours pas")
                    
            elif response.status_code == 302:
                print("   ✗ Redirection détectée (ne devrait pas arriver)")
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
    test_fixed_function()
