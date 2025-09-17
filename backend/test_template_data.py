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
from urllib.parse import quote_plus

User = get_user_model()

def test_template_data():
    print("=== TEST TEMPLATE DATA ===")
    
    # Simuler exactement la logique de client_appointments
    username = 'client123'  # Client qui a des rendez-vous
    try:
        user = User.objects.get(username=username)
        print(f"Test avec: {user.username} ({user.email})")
        
        # Récupérer les rendez-vous du client (copie exacte de la vue)
        client_profile = getattr(user, 'client_profile', None)
        if not client_profile:
            try:
                from users.models import Client as ClientModel
                client_profile, _ = ClientModel.objects.get_or_create(
                    user=user,
                    defaults={'phone_number': '', 'address': '', 'city': ''}
                )
            except Exception:
                client_profile = None

        appts_qs = (
            Appointment.objects.select_related('professional__user')
            .filter(client=client_profile)
            .order_by('-start')[:200]
        ) if client_profile else []

        pending, confirmed, cancelled = [], [], []
        for a in appts_qs:
            # Récupération complète des informations professionnel
            pro_info = {
                'center_name': 'Centre',
                'professional_name': 'Professionnel',
                'first_name': '',
                'last_name': '',
                'email': '',
                'phone': '',
                'address': '',
                'business_name': '',
                'latitude': None,
                'longitude': None,
            }
            
            try:
                if a.professional and a.professional.user:
                    user = a.professional.user
                    pro_info.update({
                        'first_name': user.first_name or '',
                        'last_name': user.last_name or '',
                        'email': user.email or '',
                        'professional_name': user.get_full_name() or f"{user.first_name} {user.last_name}".strip() or user.username,
                        'business_name': a.professional.business_name or '',
                    })
                    
                    # Le nom du centre est soit business_name soit le nom du professionnel
                    pro_info['center_name'] = a.professional.business_name or pro_info['professional_name']
                    
                    # Récupérer infos supplémentaires depuis ProfessionalProfileExtra
                    if hasattr(a.professional, 'extra') and a.professional.extra:
                        extra = a.professional.extra
                        if hasattr(extra, 'phone_number') and extra.phone_number:
                            pro_info['phone'] = extra.phone_number
                        if hasattr(extra, 'address') and extra.address:
                            pro_info['address'] = extra.address
                        if hasattr(extra, 'latitude') and extra.latitude is not None:
                            pro_info['latitude'] = extra.latitude
                        if hasattr(extra, 'longitude') and extra.longitude is not None:
                            pro_info['longitude'] = extra.longitude
            except Exception:
                pass  # Garder les valeurs par défaut
            
            # Construire l'URL Google Maps
            map_url = ''
            if pro_info.get('latitude') is not None and pro_info.get('longitude') is not None:
                map_url = f"https://www.google.com/maps?q={pro_info['latitude']},{pro_info['longitude']}"
            elif pro_info.get('address'):
                map_url = f"https://www.google.com/maps/search/?api=1&query={quote_plus(pro_info['address'])}"
            
            row = {
                'id': a.id,
                'service_name': a.service_name,
                'price': float(a.price or 0),
                'start': a.start,
                'end': a.end,
                'status': a.status,
                'center_name': pro_info['center_name'],
                'professional_name': pro_info['professional_name'],
                'professional_first_name': pro_info['first_name'],
                'professional_last_name': pro_info['last_name'],
                'professional_email': pro_info['email'],
                'professional_phone': pro_info['phone'],
                'professional_address': pro_info['address'],
                'business_name': pro_info['business_name'],
                'map_url': map_url,
                'notes': a.notes or '',
            }
            if a.status == 'confirmed':
                confirmed.append(row)
            elif a.status == 'pending':
                pending.append(row)
            else:
                cancelled.append(row)

        # Afficher les données qui seraient passées au template
        print(f"\nDonnées pour le template:")
        print(f"- pending: {len(pending)} éléments")
        print(f"- confirmed: {len(confirmed)} éléments") 
        print(f"- cancelled: {len(cancelled)} éléments")
        print(f"- total_count: {len(pending) + len(confirmed) + len(cancelled)}")
        print(f"- confirmed_count: {len(confirmed)}")
        print(f"- pending_count: {len(pending)}")
        print(f"- cancelled_count: {len(cancelled)}")
        
        # Test de la condition du template
        condition_result = bool(confirmed or pending or cancelled)
        print(f"\nCondition template: {condition_result}")
        
        if condition_result:
            print("✓ La condition devrait afficher la liste des rendez-vous")
        else:
            print("✗ La condition devrait afficher l'état vide")
            
        # Afficher quelques détails des rendez-vous
        print(f"\nDétails des rendez-vous:")
        for i, apt in enumerate(confirmed[:2]):
            print(f"  Confirmed {i+1}: {apt['service_name']} - {apt['start']}")
        for i, apt in enumerate(pending[:2]):
            print(f"  Pending {i+1}: {apt['service_name']} - {apt['start']}")
        for i, apt in enumerate(cancelled[:2]):
            print(f"  Cancelled {i+1}: {apt['service_name']} - {apt['start']}")
            
    except User.DoesNotExist:
        print(f"Utilisateur '{username}' non trouvé")

if __name__ == "__main__":
    test_template_data()
