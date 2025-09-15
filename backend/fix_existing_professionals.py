#!/usr/bin/env python
import os
import sys
import django

# Setup Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'coucou_beaute.settings')
django.setup()

from users.models import ProfessionalProfileExtra
import requests
import time

def fix_existing_professionals():
    """Corriger les professionnels existants sans coordonnées"""
    print("=== Correction des professionnels existants ===\n")
    
    # Trouver tous les profils extra sans coordonnées
    extras_without_coords = ProfessionalProfileExtra.objects.filter(
        latitude__isnull=True,
        longitude__isnull=True
    )
    
    print(f"Profils sans coordonnées trouvés: {extras_without_coords.count()}")
    
    if extras_without_coords.count() == 0:
        print("✅ Tous les professionnels ont déjà des coordonnées!")
        return
    
    fixed_count = 0
    
    for extra in extras_without_coords:
        print(f"\n--- Profil {extra.professional_id} ---")
        print(f"Professionnel: {extra.professional.business_name}")
        print(f"Adresse: {extra.address}")
        print(f"Ville: {extra.city}")
        
        # Construire l'adresse complète
        full_address = ""
        if extra.address:
            full_address = extra.address
        if extra.city and extra.city not in full_address:
            if full_address:
                full_address += f", {extra.city}"
            else:
                full_address = extra.city
        
        # Ajouter "Tunisie" si pas déjà présent
        if full_address and "tunisie" not in full_address.lower():
            full_address += ", Tunisie"
        
        print(f"Adresse complète: {full_address}")
        
        if full_address:
            # Géocoder l'adresse
            try:
                url = "https://nominatim.openstreetmap.org/search"
                params = {
                    'q': full_address,
                    'format': 'json',
                    'limit': 1,
                    'countrycodes': 'tn',
                    'addressdetails': 1
                }
                headers = {'User-Agent': 'CoucouBeaute/1.0'}
                
                response = requests.get(url, params=params, headers=headers, timeout=10)
                
                if response.status_code == 200:
                    data = response.json()
                    if data:
                        result = data[0]
                        lat = float(result['lat'])
                        lng = float(result['lon'])
                        
                        # Mettre à jour les coordonnées
                        extra.latitude = lat
                        extra.longitude = lng
                        extra.save()
                        fixed_count += 1
                        print(f"✅ Coordonnées mises à jour: {lat}, {lng}")
                    else:
                        print(f"❌ Aucun résultat pour: {full_address}")
                else:
                    print(f"❌ Erreur API: {response.status_code}")
                    
            except Exception as e:
                print(f"❌ Erreur géocodage: {e}")
        else:
            print(f"❌ Aucune adresse disponible")
        
        # Pause pour éviter de surcharger l'API
        time.sleep(1)
    
    print(f"\n=== Résumé ===")
    print(f"Profils corrigés: {fixed_count}")
    
    # Vérifier le résultat final
    total_with_coords = ProfessionalProfileExtra.objects.filter(
        latitude__isnull=False,
        longitude__isnull=False
    ).count()
    
    print(f"Total des profils avec coordonnées: {total_with_coords}")

if __name__ == "__main__":
    fix_existing_professionals()
