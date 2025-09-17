#!/usr/bin/env python
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'coucou_beaute.settings')
django.setup()

from django.contrib.auth import get_user_model
from users.models import Client

User = get_user_model()

def create_test_user():
    print("=== CREATE TEST USER ===")
    
    username = 'testclient'
    email = 'testclient@example.com'
    password = 'testpass123'
    
    try:
        # Vérifier si l'utilisateur existe déjà
        if User.objects.filter(username=username).exists():
            print(f"Utilisateur '{username}' existe déjà")
            user = User.objects.get(username=username)
        else:
            # Créer l'utilisateur
            user = User.objects.create_user(
                username=username,
                email=email,
                password=password,
                first_name='Test',
                last_name='Client'
            )
            print(f"Utilisateur '{username}' créé")
        
        # Vérifier le profil client
        client_profile = getattr(user, 'client_profile', None)
        if not client_profile:
            client_profile = Client.objects.create(
                user=user,
                phone_number='123456789',
                address='Test Address',
                city='Test City'
            )
            print(f"Profil client créé pour '{username}'")
        else:
            print(f"Profil client existe déjà pour '{username}'")
        
        print(f"\nUtilisateur de test créé:")
        print(f"- Username: {username}")
        print(f"- Email: {email}")
        print(f"- Password: {password}")
        print(f"- Client Profile: {client_profile}")
        
        return user, password
        
    except Exception as e:
        print(f"Erreur: {e}")
        return None, None

if __name__ == "__main__":
    create_test_user()
