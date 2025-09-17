#!/usr/bin/env python
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'coucou_beaute.settings')
django.setup()

from django.test import Client as TestClient
from django.contrib.auth import get_user_model
from users.models import Professional
from appointments.models import Appointment
from datetime import datetime, timedelta

User = get_user_model()

def test_with_appointment():
    print("=== TEST WITH APPOINTMENT ===")
    
    # 1. Récupérer l'utilisateur de test
    username = 'testclient'
    password = 'testpass123'
    
    try:
        user = User.objects.get(username=username)
        print(f"1. Utilisateur: {user.username} ({user.email})")
        
        # 2. Récupérer le profil client
        client_profile = getattr(user, 'client_profile', None)
        print(f"2. Profil client: {client_profile}")
        
        if not client_profile:
            print("   ✗ Aucun profil client trouvé")
            return
        
        # 3. Créer un rendez-vous de test
        print("3. Création d'un rendez-vous de test...")
        
        # Récupérer un professionnel existant
        professional = Professional.objects.first()
        if not professional:
            print("   ✗ Aucun professionnel trouvé")
            return
        
        print(f"   - Professionnel: {professional.user.username}")
        
        # Créer le rendez-vous
        start_time = datetime.now() + timedelta(days=1)
        end_time = start_time + timedelta(hours=1)
        
        appointment = Appointment.objects.create(
            professional=professional,
            client=client_profile,
            service_name='Test Service',
            price=50.0,
            start=start_time,
            end=end_time,
            status='confirmed',
            notes='Rendez-vous de test'
        )
        
        print(f"   ✓ Rendez-vous créé: ID {appointment.id}")
        
        # 4. Tester la vue HTTP
        print("4. Test de la vue HTTP...")
        
        client = TestClient()
        
        # Se connecter
        login_success = client.login(username=username, password=password)
        if login_success:
            print("   ✓ Connexion réussie")
            
            # Accéder à la page des rendez-vous
            response = client.get('/client/appointments/')
            
            print(f"   - Status code: {response.status_code}")
            
            if response.status_code == 200:
                print("   ✓ Page chargée avec succès")
                
                # Analyser le contenu
                content = response.content.decode('utf-8')
                
                # Vérifier les éléments clés
                checks = [
                    ('appointment-item', 'Éléments appointment-item'),
                    ('Test Service', 'Nom du service'),
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
                print(f"   - Nombre d'éléments 'appointment-item': {appointment_count}")
                
                # Vérifier l'état vide
                if 'Aucun rendez-vous' in content:
                    print("   ✗ Message 'Aucun rendez-vous' trouvé (ne devrait pas être là)")
                else:
                    print("   ✓ Message 'Aucun rendez-vous' non trouvé (correct)")
                
                # Afficher un extrait du HTML
                print(f"\n5. Extrait du HTML (premiers 1500 caractères):")
                print(content[:1500])
                
            else:
                print(f"   ✗ Erreur lors du chargement: {response.status_code}")
                print(f"   - Contenu: {response.content.decode('utf-8')[:500]}")
        else:
            print("   ✗ Connexion échouée")
            
    except User.DoesNotExist:
        print(f"Utilisateur '{username}' non trouvé")
    except Exception as e:
        print(f"Erreur: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_with_appointment()
