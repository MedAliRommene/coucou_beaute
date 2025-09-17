#!/usr/bin/env python
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'coucou_beaute.settings')
django.setup()

from django.contrib.auth import get_user_model
from users.models import Client, Professional
from appointments.models import Appointment

User = get_user_model()

def debug_appointments():
    print("=== DEBUG APPOINTMENTS ===")
    
    # 1. Vérifier tous les utilisateurs
    print("\n1. Utilisateurs dans le système:")
    users = User.objects.all()
    for user in users:
        print(f"  - {user.username} ({user.email}) - Role: {getattr(user, 'role', 'N/A')}")
        print(f"    - Client profile: {hasattr(user, 'client_profile')}")
        print(f"    - Professional profile: {hasattr(user, 'professional_profile')}")
    
    # 2. Vérifier tous les profils clients
    print("\n2. Profils clients:")
    clients = Client.objects.all()
    for client in clients:
        print(f"  - Client ID: {client.id} - User: {client.user.username} ({client.user.email})")
    
    # 3. Vérifier tous les rendez-vous
    print("\n3. Tous les rendez-vous:")
    appointments = Appointment.objects.all()
    for apt in appointments:
        client_info = "None"
        if apt.client:
            client_info = f"Client ID: {apt.client.id} (User: {apt.client.user.username})"
        print(f"  - RDV ID: {apt.id} - Service: {apt.service_name} - Status: {apt.status}")
        print(f"    - Client: {client_info}")
        print(f"    - Professional: {apt.professional.user.username if apt.professional else 'None'}")
        print(f"    - Date: {apt.start}")
    
    # 4. Vérifier les rendez-vous par client spécifique
    print("\n4. Rendez-vous par client:")
    for client in clients:
        client_appointments = Appointment.objects.filter(client=client)
        print(f"  - Client {client.id} ({client.user.username}): {client_appointments.count()} rendez-vous")
        for apt in client_appointments:
            print(f"    - RDV {apt.id}: {apt.service_name} - {apt.status} - {apt.start}")

if __name__ == "__main__":
    debug_appointments()
