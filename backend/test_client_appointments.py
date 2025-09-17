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

User = get_user_model()

def test_client_appointments():
    print("=== TEST CLIENT APPOINTMENTS ===")
    
    # Test avec le client "client" qui a des rendez-vous
    try:
        user = User.objects.get(username='client')
        print(f"\n1. Test avec l'utilisateur: {user.username} ({user.email})")
        
        # Vérifier le profil client
        client_profile = getattr(user, 'client_profile', None)
        print(f"   - Profil client: {client_profile}")
        
        if client_profile:
            # Récupérer les rendez-vous comme dans la vue
            appts_qs = (
                Appointment.objects.select_related('professional__user')
                .filter(client=client_profile)
                .order_by('-start')[:200]
            )
            
            print(f"   - Nombre de rendez-vous trouvés: {appts_qs.count()}")
            
            for apt in appts_qs:
                print(f"     - RDV {apt.id}: {apt.service_name} - {apt.status} - {apt.start}")
        else:
            print("   - Aucun profil client trouvé!")
            
    except User.DoesNotExist:
        print("Utilisateur 'client' non trouvé")
    
    # Test avec le client "client123" qui a aussi des rendez-vous
    try:
        user = User.objects.get(username='client123')
        print(f"\n2. Test avec l'utilisateur: {user.username} ({user.email})")
        
        # Vérifier le profil client
        client_profile = getattr(user, 'client_profile', None)
        print(f"   - Profil client: {client_profile}")
        
        if client_profile:
            # Récupérer les rendez-vous comme dans la vue
            appts_qs = (
                Appointment.objects.select_related('professional__user')
                .filter(client=client_profile)
                .order_by('-start')[:200]
            )
            
            print(f"   - Nombre de rendez-vous trouvés: {appts_qs.count()}")
            
            for apt in appts_qs:
                print(f"     - RDV {apt.id}: {apt.service_name} - {apt.status} - {apt.start}")
        else:
            print("   - Aucun profil client trouvé!")
            
    except User.DoesNotExist:
        print("Utilisateur 'client123' non trouvé")

if __name__ == "__main__":
    test_client_appointments()
