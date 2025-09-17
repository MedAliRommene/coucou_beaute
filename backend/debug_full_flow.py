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
from django.contrib.auth import authenticate, login
from django.contrib.sessions.models import Session

User = get_user_model()

def debug_full_flow():
    print("=== DEBUG FULL FLOW ===")
    
    # Tester avec un client qui a des rendez-vous
    username = 'client123'
    password = 'password123'  # Supposons que c'est le mot de passe
    
    try:
        # 1. Récupérer l'utilisateur
        user = User.objects.get(username=username)
        print(f"1. Utilisateur trouvé: {user.username} ({user.email})")
        print(f"   - Role: {getattr(user, 'role', 'N/A')}")
        print(f"   - Actif: {user.is_active}")
        
        # 2. Vérifier l'authentification
        auth_user = authenticate(username=username, password=password)
        if auth_user:
            print("2. Authentification: ✓ Réussie")
        else:
            print("2. Authentification: ✗ Échouée")
            # Essayer avec l'email
            auth_user = authenticate(username=user.email, password=password)
            if auth_user:
                print("2. Authentification (email): ✓ Réussie")
            else:
                print("2. Authentification (email): ✗ Échouée")
        
        # 3. Vérifier le profil client
        client_profile = getattr(user, 'client_profile', None)
        print(f"3. Profil client: {client_profile}")
        
        if client_profile:
            # 4. Récupérer les rendez-vous (logique exacte de la vue)
            appts_qs = (
                Appointment.objects.select_related('professional__user')
                .filter(client=client_profile)
                .order_by('-start')[:200]
            )
            
            print(f"4. Rendez-vous trouvés: {appts_qs.count()}")
            
            # 5. Traiter les rendez-vous (logique exacte de la vue)
            pending, confirmed, cancelled = [], [], []
            from urllib.parse import quote_plus
            
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
                        pro_user = a.professional.user
                        pro_info.update({
                            'first_name': pro_user.first_name or '',
                            'last_name': pro_user.last_name or '',
                            'email': pro_user.email or '',
                            'professional_name': pro_user.get_full_name() or f"{pro_user.first_name} {pro_user.last_name}".strip() or pro_user.username,
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
                except Exception as e:
                    print(f"   Erreur lors de la récupération des infos pro: {e}")
                
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
            
            # 6. Afficher les résultats finaux
            print(f"5. Résultats finaux:")
            print(f"   - pending: {len(pending)} éléments")
            print(f"   - confirmed: {len(confirmed)} éléments")
            print(f"   - cancelled: {len(cancelled)} éléments")
            print(f"   - total_count: {len(pending) + len(confirmed) + len(cancelled)}")
            print(f"   - confirmed_count: {len(confirmed)}")
            print(f"   - pending_count: {len(pending)}")
            print(f"   - cancelled_count: {len(cancelled)}")
            
            # 7. Test de la condition du template
            condition_result = bool(confirmed or pending or cancelled)
            print(f"6. Condition template: {condition_result}")
            
            if condition_result:
                print("   ✓ La page devrait afficher les rendez-vous")
                print("   ✓ Le problème n'est PAS dans la logique de récupération")
                print("   ✓ Le problème doit être dans l'affichage ou le JavaScript")
            else:
                print("   ✗ La page devrait afficher l'état vide")
            
            # 8. Afficher quelques détails
            print(f"\n7. Détails des rendez-vous:")
            for i, apt in enumerate(confirmed[:3]):
                print(f"   Confirmed {i+1}: {apt['service_name']} - {apt['start']} - {apt['center_name']}")
            for i, apt in enumerate(pending[:3]):
                print(f"   Pending {i+1}: {apt['service_name']} - {apt['start']} - {apt['center_name']}")
            for i, apt in enumerate(cancelled[:3]):
                print(f"   Cancelled {i+1}: {apt['service_name']} - {apt['start']} - {apt['center_name']}")
                
        else:
            print("4. Aucun profil client trouvé")
            
    except User.DoesNotExist:
        print(f"Utilisateur '{username}' non trouvé")
    except Exception as e:
        print(f"Erreur: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    debug_full_flow()
