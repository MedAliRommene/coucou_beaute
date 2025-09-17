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
from django.contrib.auth import authenticate

User = get_user_model()

def test_client_login_flow():
    print("=== TEST CLIENT LOGIN FLOW ===")
    
    # Test avec différents clients
    test_clients = ['client', 'client123', 'test', 'sahar']
    
    for username in test_clients:
        print(f"\n--- Test avec {username} ---")
        
        try:
            # Simuler la connexion
            user = User.objects.get(username=username)
            print(f"1. Utilisateur trouvé: {user.username} ({user.email})")
            print(f"   - Role: {getattr(user, 'role', 'N/A')}")
            
            # Vérifier le profil client (comme dans login_view)
            client_profile = getattr(user, 'client_profile', None)
            print(f"2. Profil client initial: {client_profile}")
            
            if not client_profile:
                print("   - Création du profil client...")
                try:
                    from users.models import Client as ClientModel
                    client_profile, created = ClientModel.objects.get_or_create(
                        user=user,
                        defaults={'phone_number': '', 'address': '', 'city': ''}
                    )
                    print(f"   - Profil créé: {created}, ID: {client_profile.id}")
                except Exception as e:
                    print(f"   - Erreur création profil: {e}")
                    client_profile = None
            
            if client_profile:
                # Récupérer les rendez-vous (comme dans client_appointments)
                appts_qs = (
                    Appointment.objects.select_related('professional__user')
                    .filter(client=client_profile)
                    .order_by('-start')[:200]
                )
                
                print(f"3. Rendez-vous trouvés: {appts_qs.count()}")
                
                # Classer par statut (comme dans la vue)
                pending, confirmed, cancelled = [], [], []
                for a in appts_qs:
                    if a.status == 'confirmed':
                        confirmed.append(a)
                    elif a.status == 'pending':
                        pending.append(a)
                    else:
                        cancelled.append(a)
                
                print(f"   - Confirmés: {len(confirmed)}")
                print(f"   - En attente: {len(pending)}")
                print(f"   - Annulés: {len(cancelled)}")
                print(f"   - Total: {len(pending) + len(confirmed) + len(cancelled)}")
                
                # Afficher quelques détails
                for apt in appts_qs[:3]:  # Afficher les 3 premiers
                    print(f"     - RDV {apt.id}: {apt.service_name} - {apt.status} - {apt.start}")
            else:
                print("3. Aucun profil client disponible")
                
        except User.DoesNotExist:
            print(f"Utilisateur '{username}' non trouvé")
        except Exception as e:
            print(f"Erreur: {e}")

if __name__ == "__main__":
    test_client_login_flow()
