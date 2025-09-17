#!/usr/bin/env python
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'coucou_beaute.settings')
django.setup()

from django.contrib.auth import get_user_model
from users.models import Client
from appointments.models import Appointment
from django.test import Client as TestClient
from django.urls import reverse

User = get_user_model()

def test_actual_user():
    print("=== TEST ACTUAL USER ===")
    
    # Créer un client de test Django
    client = TestClient()
    
    # Tester avec différents utilisateurs
    test_users = [
        ('client', 'client@gmail.com'),
        ('client123', 'client123@gmail.com'),
        ('test', 'test@gmail.com'),
    ]
    
    for username, email in test_users:
        print(f"\n--- Test avec {username} ---")
        
        try:
            # Récupérer l'utilisateur
            user = User.objects.get(username=username)
            print(f"1. Utilisateur: {user.username} ({user.email})")
            
            # Vérifier le profil client
            client_profile = getattr(user, 'client_profile', None)
            print(f"2. Profil client: {client_profile}")
            
            if client_profile:
                # Récupérer les rendez-vous directement
                appointments = Appointment.objects.filter(client=client_profile)
                print(f"3. Rendez-vous en base: {appointments.count()}")
                
                # Simuler une requête à la vue client_appointments
                # (Nous ne pouvons pas vraiment faire une requête HTTP ici, mais nous pouvons simuler la logique)
                print("4. Simulation de la vue client_appointments...")
                
                appts_qs = (
                    Appointment.objects.select_related('professional__user')
                    .filter(client=client_profile)
                    .order_by('-start')[:200]
                )
                
                pending, confirmed, cancelled = [], [], []
                for a in appts_qs:
                    row = {
                        'id': a.id,
                        'service_name': a.service_name,
                        'price': float(a.price or 0),
                        'start': a.start,
                        'end': a.end,
                        'status': a.status,
                        'center_name': 'Centre',
                        'professional_name': 'Professionnel',
                    }
                    if a.status == 'confirmed':
                        confirmed.append(row)
                    elif a.status == 'pending':
                        pending.append(row)
                    else:
                        cancelled.append(row)
                
                print(f"   - Confirmés: {len(confirmed)}")
                print(f"   - En attente: {len(pending)}")
                print(f"   - Annulés: {len(cancelled)}")
                print(f"   - Total: {len(pending) + len(confirmed) + len(cancelled)}")
                
                # Vérifier la condition du template
                has_appointments = bool(confirmed or pending or cancelled)
                print(f"   - Condition template: {has_appointments}")
                
                if has_appointments:
                    print("   ✓ Devrait afficher les rendez-vous")
                else:
                    print("   ✗ Devrait afficher l'état vide")
            else:
                print("3. Aucun profil client")
                
        except User.DoesNotExist:
            print(f"Utilisateur '{username}' non trouvé")
        except Exception as e:
            print(f"Erreur: {e}")

if __name__ == "__main__":
    test_actual_user()
