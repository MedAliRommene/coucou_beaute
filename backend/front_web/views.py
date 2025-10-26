from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from django.views.decorators.http import require_http_methods, require_POST
from django.contrib import messages
from django.contrib.auth import authenticate, login, logout
from django.utils.http import url_has_allowed_host_and_scheme
from urllib.parse import urlparse
from django.http import HttpRequest, HttpResponse, JsonResponse
from django.utils import timezone
from users.models import Professional
from django.contrib.auth import get_user_model
from users.models import Client as ClientProfile, ProfessionalApplication, ProfessionalApplicationAction
from appointments.models import Appointment
from users.models import ProfessionalProfileExtra
from reviews.models import Review
import json
import re
from django.core.cache import cache
from users.serializers import ProfessionalApplicationSerializer
from django.db.models import Q, Avg, Count
from django.core.paginator import Paginator
from django.core.files.base import ContentFile
from django.core.files import File
from django.conf import settings
import base64
from reviews.views import update_professional_rating


def _extract_city_name(address_string: str) -> str:
    """Extrait le nom de la ville d'une adresse complète"""
    if not address_string:
        return ''
    
    # Diviser l'adresse par les virgules
    parts = [p.strip() for p in address_string.split(',')]
    
    # Chercher la partie qui contient "Délégation" ou qui est avant "Gouvernorat"
    for i, part in enumerate(parts):
        # Si on trouve "Délégation", la ville est généralement le mot d'après ou dans la même partie
        if 'Délégation' in part or 'Delegation' in part:
            # Extraire le mot après "Délégation"
            words = part.split()
            for j, word in enumerate(words):
                if word in ['Délégation', 'Delegation']:
                    if j + 1 < len(words):
                        # Si c'est "Le", prendre les 2 mots suivants
                        if words[j + 1] == 'Le' and j + 2 < len(words):
                            return f"{words[j + 1]} {words[j + 2]}".rstrip(',')
                        return words[j + 1].rstrip(',')
        
        # Si on trouve "Gouvernorat", la ville est généralement juste après
        if 'Gouvernorat' in part or 'Governorat' in part:
            words = part.split()
            for j, word in enumerate(words):
                if word in ['Gouvernorat', 'Governorat']:
                    if j + 1 < len(words):
                        # La ville est le mot après "Gouvernorat"
                        return words[j + 1].rstrip(',')
                    elif i + 1 < len(parts):
                        # Ou dans la partie suivante
                        return parts[i + 1].split()[0].rstrip(',')
        
        # Chercher les noms de villes tunisiennes communes
        city_keywords = ['Tunis', 'Hammamet', 'Sousse', 'Sfax', 'Nabeul', 'Monastir', 'Bizerte', 'Gabès', 'Ariana', 'Gafsa', 'Kasserine', 'Kairouan', 'Tozeur', 'Bardo', 'Lac']
        for keyword in city_keywords:
            if keyword in part:
                return keyword
    
    # Si rien n'est trouvé, retourner la première partie (par défaut)
    return parts[0] if parts else ''


def landing(request: HttpRequest) -> HttpResponse:
    """Page d'accueil avec les professionnelles 5 étoiles"""
    # Récupérer les professionnelles avec 5 étoiles
    professionals_5_stars = []
    
    try:
        # Récupérer toutes les professionnelles avec leurs profils extra
        professionals = Professional.objects.select_related('user').prefetch_related('extra').filter(
            is_verified=True  # Seulement les professionnelles vérifiées
        )
        
        for pro in professionals:
            try:
                # Vérifier si elle a un profil extra
                if hasattr(pro, 'extra') and pro.extra:
                    extra = pro.extra
                    
                    # Calculer la note moyenne des avis
                    from django.db.models import Avg, Count
                    reviews_stats = Review.objects.filter(
                        professional=pro,
                        is_public=True
                    ).aggregate(
                        avg_rating=Avg('rating'),
                        total_reviews=Count('id')
                    )
                    
                    avg_rating = reviews_stats['avg_rating'] or 0
                    total_reviews = reviews_stats['total_reviews'] or 0
                    
                    # Afficher toutes les professionnelles vérifiées (avec ou sans avis)
                    # Si elles ont des avis, vérifier qu'elles ont au moins 3.5 étoiles
                    if total_reviews == 0 or avg_rating >= 3.5:
                        # Préparer les services
                        services_list = []
                        if extra.services:
                            if isinstance(extra.services, list):
                                for service in extra.services[:5]:  # Max 5 services
                                    if isinstance(service, dict):
                                        services_list.append({
                                            'name': str(service.get('name', service.get('Name', str(service)))).strip(),
                                            'price': float(service.get('price', service.get('Price', 50))),
                                            'duration': int(service.get('duration', service.get('Duration_Min', 30)))
                                        })
                                    else:
                                        services_list.append({
                                            'name': str(service).strip(),
                                            'price': 50,
                                            'duration': 30
                                        })
                            elif isinstance(extra.services, str):
                                for service in extra.services.split(',')[:5]:
                                    if service.strip():
                                        services_list.append({
                                            'name': service.strip(),
                                            'price': 50,
                                            'duration': 30
                                        })
                        
                        # Préparer la galerie
                        gallery_list = []
                        if extra.gallery:
                            if isinstance(extra.gallery, list):
                                gallery_list = [str(img).strip() for img in extra.gallery[:6] if img and str(img).strip()]
                            elif isinstance(extra.gallery, str):
                                gallery_list = [img.strip() for img in extra.gallery.split(',')[:6] if img.strip()]
                        
                        # Informations de la professionnelle
                        professional_data = {
                            'id': pro.id,
                            'full_name': pro.user.get_full_name() or f"{pro.user.first_name} {pro.user.last_name}".strip() or pro.user.username,
                            'first_name': pro.user.first_name or '',
                            'last_name': pro.user.last_name or '',
                            'email': pro.user.email,
                            'business_name': pro.business_name or pro.user.get_full_name(),
                            'bio': extra.bio or "Professionnelle passionnée par l'art de la beauté",
                            'city': extra.city or '',
                            'address': extra.address or '',
                            'city_only': _extract_city_name(extra.city or extra.address or ''),
                            'phone_number': extra.phone_number or '',
                            'rating': round(avg_rating, 1),
                            'total_reviews': total_reviews,
                            'price': extra.price or 50,
                            'services': services_list,
                            'gallery': gallery_list,
                            'profile_photo': extra.profile_photo.url if extra.profile_photo else None,
                            'social_instagram': extra.social_instagram or '',
                            'social_facebook': extra.social_facebook or '',
                            'social_tiktok': extra.social_tiktok or '',
                            'working_days': extra.working_days or [],
                            'working_hours': extra.working_hours or {},
                            'specialty': extra.primary_service or 'Spécialiste beauté',
                            'badge': 'Certifiée 5★' if avg_rating >= 4.9 else 'Expert ⭐' if avg_rating >= 4.5 else 'Professionnelle ⭐',
                            'availability': 'Disponible' if extra.working_days else 'Sur demande',
                            'profile_url': f'/professional/{pro.id}/'
                        }
                        
                        professionals_5_stars.append(professional_data)
                        
            except Exception as e:
                # En cas d'erreur avec une professionnelle, continuer avec les autres
                continue
        
        # Trier par note décroissante puis par nombre d'avis
        professionals_5_stars.sort(key=lambda x: (x['rating'], x['total_reviews']), reverse=True)
        
        # Limiter à 12 professionnelles maximum
        professionals_5_stars = professionals_5_stars[:12]
        
    except Exception as e:
        # En cas d'erreur, continuer avec une liste vide
        professionals_5_stars = []
    
    # Extraire la liste unique des villes
    cities = sorted(list(set([pro['city_only'] for pro in professionals_5_stars if pro.get('city_only')])))
    
    context = {
        'professionals': professionals_5_stars,
        'total_experts': len(professionals_5_stars),
        'professionals_json': json.dumps({str(pro['id']): pro for pro in professionals_5_stars}),
        'cities': cities
    }
    
    return render(request, 'front_web/landing.html', context)


@require_http_methods(["GET", "POST"])
def login_view(request: HttpRequest) -> HttpResponse:
    # Ensure a clean form with no stale messages
    if request.method == 'GET':
        try:
            for _ in messages.get_messages(request):
                pass
        except Exception:
            pass

    if request.method == 'POST':
        identifier = (request.POST.get('email') or '').strip()
        password = request.POST.get('password') or ''
        selected_role = request.POST.get('role') or 'client'

        # Allow login with email OR username
        username_to_use = identifier
        try:
            if '@' in identifier:
                UserModel = get_user_model()
                u = UserModel.objects.filter(email__iexact=identifier).first()
                if u:
                    username_to_use = u.username
        except Exception:
            pass

        user = authenticate(request, username=username_to_use, password=password)
        if user is not None:
            if not user.is_active:
                messages.error(request, "Votre compte n'est pas encore activé. Vérifiez votre email ou contactez le support.")
                return render(request, 'front_web/login.html')

            login(request, user)

            # Admin
            if user.is_staff or user.is_superuser:
                return redirect('/dashboard/')

            if selected_role == 'professional':
                try:
                    pro = getattr(user, 'professional_profile', None)
                    if pro:
                        try:
                            _ = pro.extra
                            return redirect('front_web:pro_dashboard')
                        except ProfessionalProfileExtra.DoesNotExist:
                            return redirect('front_web:pro_onboarding')
                    else:
                        messages.error(request, "Aucun profil professionnel trouvé pour cet utilisateur.")
                        return render(request, 'front_web/login.html')
                except Exception:
                    messages.error(request, "Erreur lors de la vérification du profil professionnel.")
                    return render(request, 'front_web/login.html')

            elif selected_role == 'client':
                try:
                    client_profile = getattr(user, 'client_profile', None)
                    if client_profile:
                        return redirect('front_web:client_dashboard')
                    else:
                        ClientProfile.objects.get_or_create(
                            user=user,
                            defaults={'phone_number': '', 'address': '', 'city': ''}
                        )
                        return redirect('front_web:client_dashboard')
                except Exception:
                    messages.error(request, "Erreur lors de la création du profil client.")
                    return render(request, 'front_web/login.html')

            # Optional "next"
            next_url = request.POST.get('next') or request.GET.get('next')
            if next_url and url_has_allowed_host_and_scheme(next_url, allowed_hosts={request.get_host()}):
                return redirect(next_url)

            # Auto-detect role
            try:
                pro = getattr(user, 'professional_profile', None)
                if pro:
                    try:
                        _ = pro.extra
                        return redirect('front_web:pro_dashboard')
                    except ProfessionalProfileExtra.DoesNotExist:
                        return redirect('front_web:pro_onboarding')
            except Exception:
                pass

            # Default: client dashboard
            try:
                ClientProfile.objects.get_or_create(
                    user=user,
                    defaults={'phone_number': '', 'address': '', 'city': ''}
                )
                return redirect('front_web:client_dashboard')
            except Exception:
                messages.error(request, "Erreur lors de la création du profil.")
                return render(request, 'front_web/login.html')
        else:
            messages.error(request, "Identifiants invalides")

    return render(request, 'front_web/login.html')


@require_http_methods(["GET", "POST"])
def signup_view(request: HttpRequest) -> HttpResponse:
    if request.method == 'POST':
        email = (request.POST.get('email') or '').strip().lower()
        password = request.POST.get('password') or ''
        first_name = request.POST.get('first_name') or ''
        last_name = request.POST.get('last_name') or ''
        role_raw = (request.POST.get('role') or 'client').strip().lower()
        # Normalize role value from UI (supports FR/EN labels)
        if role_raw in ('client', 'customer'):
            role = 'client'
        elif role_raw in ('professional', 'professionnel', 'pro'):
            role = 'professional'
        else:
            role = 'client'

        if not email or not password:
            messages.error(request, "Email et mot de passe requis")
            return render(request, 'front_web/signup.html')

        UserModel = get_user_model()

        if role == 'client':
            if UserModel.objects.filter(username__iexact=email).exists() or UserModel.objects.filter(email__iexact=email).exists():
                messages.error(request, "Un compte existe déjà avec cet email")
                return render(request, 'front_web/signup.html')

            u = UserModel.objects.create_user(
                username=email,
                email=email,
                password=password,
                first_name=first_name,
                last_name=last_name,
            )
            try:
                if hasattr(u, 'role'):
                    setattr(u, 'role', 'client')
                    u.save(update_fields=['role'])
            except Exception:
                pass

            phone = request.POST.get('phone') or ''
            address = request.POST.get('address') or ''
            city = request.POST.get('city') or ''
            latitude = request.POST.get('latitude')
            longitude = request.POST.get('longitude')

            try:
                latitude = float(latitude) if latitude else None
                longitude = float(longitude) if longitude else None
            except (ValueError, TypeError):
                latitude = longitude = None

            ClientProfile.objects.create(
                user=u,
                phone_number=phone,
                address=address,
                city=city,
                latitude=latitude,
                longitude=longitude,
            )
            login(request, u)
            return redirect('front_web:client_dashboard')

        # Professional application flow
        phone = request.POST.get('phone') or ''
        category = request.POST.get('activity_category') or 'other'
        service_type = request.POST.get('service_type') or 'mobile'
        address = request.POST.get('address') or ''
        lat = request.POST.get('latitude') or None
        lng = request.POST.get('longitude') or None
        salon_name = request.POST.get('salon_name') or ''
        spoken_languages = request.POST.getlist('spoken_languages') or ['french']
        subscription_active = bool(request.POST.get('subscription_active'))
        # Handle uploaded files
        profile_photo = None
        id_document = None
        
        # Handle profile photo upload
        if 'profile_photo' in request.FILES:
            profile_photo = request.FILES['profile_photo']
        elif 'profile_photo' in request.POST and request.POST['profile_photo']:
            # Handle base64 or URL data if needed
            profile_photo = request.POST['profile_photo']
        
        # Handle ID document upload
        if 'id_document' in request.FILES:
            id_document = request.FILES['id_document']
        elif 'id_document' in request.POST and request.POST['id_document']:
            # Handle base64 or URL data if needed
            id_document = request.POST['id_document']
        try:
            lat = float(lat) if lat else None
            lng = float(lng) if lng else None
        except Exception:
            lat = lng = None

        payload = {
            'first_name': first_name or email.split('@')[0],
            'last_name': last_name or '',
            'email': email,
            'phone_number': phone,
            'activity_category': category,
            'service_type': service_type,
            'spoken_languages': spoken_languages,
            'address': address,
            'latitude': lat,
            'longitude': lng,
            'salon_name': salon_name,
            'subscription_active': subscription_active,
        }
        
        # Add files to payload if they exist
        if profile_photo:
            payload['profile_photo'] = profile_photo
        if id_document:
            payload['id_document'] = id_document
        
        ser = ProfessionalApplicationSerializer(data=payload)
        if ser.is_valid():
            # Si un utilisateur existe déjà avec cet e-mail, on bloque pour éviter le conflit serializer côté API mobile
            if UserModel.objects.filter(email__iexact=email).exists():
                messages.error(request, "Cet e-mail est déjà associé à un compte. Veuillez utiliser un autre e-mail ou vous connecter.")
                return render(request, 'front_web/signup.html')

            app = ser.save()
            try:
                ProfessionalApplicationAction.objects.create(
                    application=app, action='submitted', actor=None, notes='Soumission via site web'
                )
            except Exception:
                pass
            # Créer un compte utilisateur inactif pour futur login après approbation (même logique mobile)
            base_username = (email.split('@')[0] or 'pro').replace(' ', '_')[:150]
            username = base_username
            i = 1
            while UserModel.objects.filter(username=username).exists():
                suffix = f"_{i}"
                username = (base_username[: (150 - len(suffix))] + suffix)
                i += 1
            extra_fields = {}
            if hasattr(UserModel(), 'phone'):
                extra_fields['phone'] = phone or '00000000'
            if hasattr(UserModel(), 'role'):
                extra_fields['role'] = 'professional'
            if hasattr(UserModel(), 'language'):
                extra_fields['language'] = 'fr'
            user_obj = UserModel.objects.create_user(
                username=username, email=email, password=password, **extra_fields
            )
            user_obj.first_name = first_name
            user_obj.last_name = last_name
            user_obj.is_active = False
            try:
                user_obj.save()
            except Exception:
                user_obj.save()
            messages.info(request, "Votre demande professionnelle a été soumise et est en cours de vérification. Vous serez notifié par e-mail après validation.")
            return redirect('front_web:home')
        else:
            # Afficher les erreurs du serializer
            err_map = []
            for k, v in ser.errors.items():
                try:
                    first = v[0]
                except Exception:
                    first = v
                err_map.append(f"{k}: {first}")
            messages.error(request, " ".join(err_map))
            return render(request, 'front_web/signup.html')
    return render(request, 'front_web/signup.html')


@login_required
def client_dashboard(request: HttpRequest) -> HttpResponse:
    # Get client profile data
    client_profile = None
    try:
        client_profile = request.user.client_profile
    except Exception:
        pass
    
    context = {
        'client_profile': client_profile,
    }
    return render(request, 'front_web/client_dashboard.html', context)


def logout_view(request: HttpRequest) -> HttpResponse:
    try:
        logout(request)
    finally:
        try:
            for _ in messages.get_messages(request):
                pass
        except Exception:
            pass
    return redirect('front_web:home')


def professional_detail(request: HttpRequest, pro_id: int) -> HttpResponse:
    """Display professional profile details"""
    try:
        pro = Professional.objects.select_related('user').prefetch_related('extra').get(id=pro_id)
        
        # Prepare services as a list of dictionaries
        services_list = []
        if pro.extra and pro.extra.services:
            if isinstance(pro.extra.services, list):
                # If it's already a list, process each item
                for service in pro.extra.services:
                    if service:
                        if isinstance(service, dict):
                            # If it's a dict, extract name, price, duration
                            service_name = service.get('Name', service.get('name', str(service)))
                            service_price = service.get('Price', service.get('price', 50))
                            service_duration = service.get('Duration_Min', service.get('duration', 30))
                            services_list.append({
                                'name': str(service_name).strip(),
                                'price': float(service_price) if service_price else 50,
                                'duration': int(service_duration) if service_duration else 30
                            })
                        else:
                            # If it's a string, treat as service name
                            services_list.append({
                                'name': str(service).strip(),
                                'price': 50,  # Default price
                                'duration': 30  # Default duration
                            })
            elif isinstance(pro.extra.services, dict):
                # If it's a dict, extract values
                for service in pro.extra.services.values():
                    if service:
                        if isinstance(service, dict):
                            service_name = service.get('Name', service.get('name', str(service)))
                            service_price = service.get('Price', service.get('price', 50))
                            service_duration = service.get('Duration_Min', service.get('duration', 30))
                            services_list.append({
                                'name': str(service_name).strip(),
                                'price': float(service_price) if service_price else 50,
                                'duration': int(service_duration) if service_duration else 30
                            })
                        else:
                            services_list.append({
                                'name': str(service).strip(),
                                'price': 50,
                                'duration': 30
                            })
            elif isinstance(pro.extra.services, str):
                # If it's a string, split it
                for service in pro.extra.services.split(','):
                    if service.strip():
                        services_list.append({
                            'name': service.strip(),
                            'price': 50,
                            'duration': 30
                        })
            else:
                # Fallback: convert to string and split
                for service in str(pro.extra.services).split(','):
                    if service.strip():
                        services_list.append({
                            'name': service.strip(),
                            'price': 50,
                            'duration': 30
                        })

        # Prepare gallery as a list
        gallery_list = []
        if pro.extra and pro.extra.gallery:
            if isinstance(pro.extra.gallery, list):
                # If it's already a list, use it directly
                gallery_list = [str(image).strip() for image in pro.extra.gallery if image and str(image).strip()]
            elif isinstance(pro.extra.gallery, dict):
                # If it's a dict, extract values
                gallery_list = [str(image).strip() for image in pro.extra.gallery.values() if image and str(image).strip()]
            elif isinstance(pro.extra.gallery, str):
                # If it's a string, split it
                gallery_list = [image.strip() for image in pro.extra.gallery.split(',') if image.strip()]
            else:
                # Fallback: convert to string and split
                gallery_list = [str(image).strip() for image in str(pro.extra.gallery).split(',') if str(image).strip()]

        # Prepare working days and hours
        working_days_list = []
        working_hours_display = ""
        if pro.extra and pro.extra.working_days:
            if isinstance(pro.extra.working_days, list):
                working_days_list = pro.extra.working_days
            elif isinstance(pro.extra.working_days, str):
                working_days_list = [day.strip() for day in pro.extra.working_days.split(',') if day.strip()]
            else:
                working_days_list = [str(pro.extra.working_days)]

        if pro.extra and pro.extra.working_hours:
            if isinstance(pro.extra.working_hours, dict):
                start_time = pro.extra.working_hours.get('start', '08:00')
                end_time = pro.extra.working_hours.get('end', '18:00')
                working_hours_display = f"{start_time} - {end_time}"
            elif isinstance(pro.extra.working_hours, str):
                working_hours_display = pro.extra.working_hours
            else:
                working_hours_display = str(pro.extra.working_hours)
        
        # Get reviews for this professional
        reviews = Review.objects.filter(
            professional=pro,
            is_public=True
        ).order_by('-created_at')[:10]  # Limit to 10 most recent reviews
        
        # Check if current user has already reviewed this professional
        user_has_reviewed = False
        if request.user.is_authenticated and hasattr(request.user, 'client_profile'):
            user_has_reviewed = Review.objects.filter(
                client=request.user,
                professional=pro
            ).exists()
        
        context = {
            'pro': pro,
            'pro_id': pro_id,
            'services_list': services_list,
            'gallery_list': gallery_list,
            'working_days_list': working_days_list,
            'working_hours_display': working_hours_display,
            'reviews': reviews,
            'user_has_reviewed': user_has_reviewed,
        }
        return render(request, 'front_web/professional_detail.html', context)
    except Professional.DoesNotExist:
        messages.error(request, "Professionnel non trouvé.")
        return redirect('front_web:client_dashboard')


@login_required
def book_appointment(request, pro_id):
    """Handle appointment booking form submission"""
    if request.method == 'POST':
        try:
            pro = Professional.objects.get(id=pro_id)
            
            # Get form data
            service_name = request.POST.get('service_name', 'Service Général')
            service_price = float(request.POST.get('service_price', 50))
            service_duration = int(request.POST.get('service_duration', 60))
            appointment_date = request.POST.get('appointment_date')
            appointment_time = request.POST.get('appointment_time')
            client_notes = request.POST.get('client_notes', '')
            
            if not appointment_date or not appointment_time:
                messages.error(request, 'Veuillez sélectionner une date et une heure.')
                return redirect('front_web:professional_detail', pro_id=pro_id)
            
            # Create datetime objects
            from datetime import datetime, time
            appointment_datetime = datetime.combine(
                datetime.strptime(appointment_date, '%Y-%m-%d').date(),
                datetime.strptime(appointment_time, '%H:%M').time()
            )
            
            # Calculate end time
            from datetime import timedelta
            end_datetime = appointment_datetime + timedelta(minutes=service_duration)
            
            # VERIFICATION FINALE: Check if slot is still available (anti-collision)
            conflicting_appointments = Appointment.objects.filter(
                professional=pro,
                start__date=appointment_datetime.date(),
                status__in=['confirmed', 'pending']
            ).filter(
                start__time__lt=end_datetime.time(),
                end__time__gt=appointment_datetime.time()
            )
            
            if conflicting_appointments.exists():
                messages.error(request, 'Ce créneau n\'est plus disponible. Veuillez choisir un autre horaire.')
                return redirect('front_web:book_appointment_page', pro_id=pro_id)
            
            # Create appointment
            # Get client profile
            client_profile = getattr(request.user, 'client_profile', None)
            if not client_profile:
                messages.error(request, 'Profil client requis pour réserver un rendez-vous.')
                return redirect('front_web:professional_detail', pro_id=pro_id)
            
            appointment = Appointment.objects.create(
                professional=pro,
                client=client_profile,
                service_name=service_name,
                price=service_price,
                start=appointment_datetime,
                end=end_datetime,
                status='pending',
                notes=client_notes
            )
            
            # Notifications and emails are handled by signals automatically
            
            messages.success(request, 'Votre demande de rendez-vous a été envoyée avec succès! Vous recevrez une confirmation par email.')
            return redirect('front_web:client_appointments')
            
        except Professional.DoesNotExist:
            messages.error(request, 'Professionnel non trouvé.')
            return redirect('front_web:client_dashboard')
        except Exception as e:
            messages.error(request, f'Erreur lors de la réservation: {str(e)}')
            return redirect('front_web:professional_detail', pro_id=pro_id)
    
    return redirect('front_web:professional_detail', pro_id=pro_id)


@login_required
def get_available_slots(request, pro_id):
    """API endpoint to get available time slots for a specific date"""
    try:
        from django.http import JsonResponse
        from datetime import datetime, timedelta
        
        pro = Professional.objects.get(id=pro_id)
        date_str = request.GET.get('date')
        
        if not date_str:
            return JsonResponse({'error': 'Date parameter required'}, status=400)
        
        # Parse the requested date
        try:
            requested_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return JsonResponse({'error': 'Invalid date format'}, status=400)
        
        # Get working hours and days from professional profile
        if pro.extra:
            working_hours_dict = pro.extra.working_hours if pro.extra.working_hours else {'start': '09:00', 'end': '18:00'}
            working_days = pro.extra.working_days if pro.extra.working_days else ['mon', 'tue', 'wed', 'thu', 'fri']
        else:
            working_hours_dict = {'start': '09:00', 'end': '18:00'}
            working_days = ['mon', 'tue', 'wed', 'thu', 'fri']
        
        # Check if the requested date is a working day
        day_of_week = requested_date.weekday()  # 0=Monday, 6=Sunday
        day_names = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
        day_name = day_names[day_of_week]
        
        if day_name not in working_days:
            return JsonResponse({'slots': [], 'message': 'Centre fermé ce jour'})
        
        # Parse working hours from dict format
        if isinstance(working_hours_dict, dict):
            start_time_str = working_hours_dict.get('start', '09:00')
            end_time_str = working_hours_dict.get('end', '18:00')
        else:
            # Fallback for string format "09:00-18:00"
            start_time_str, end_time_str = str(working_hours_dict).split('-') if '-' in str(working_hours_dict) else ('09:00', '18:00')
        
        start_hour = int(start_time_str.split(':')[0])
        end_hour = int(end_time_str.split(':')[0])
        
        # Get existing appointments for this date
        existing_appointments = Appointment.objects.filter(
            professional=pro,
            start__date=requested_date,
            status__in=['confirmed', 'pending']  # Include pending appointments
        ).values_list('start__time', 'end__time')
        
        # Generate available slots
        available_slots = []
        for hour in range(start_hour, end_hour):
            slot_start = f"{hour:02d}:00"
            slot_end = f"{hour + 1:02d}:00"
            
            # Check if this slot conflicts with existing appointments
            is_available = True
            for appt_start, appt_end in existing_appointments:
                appt_start_hour = appt_start.hour
                appt_end_hour = appt_end.hour
                
                # Check for overlap
                if hour >= appt_start_hour and hour < appt_end_hour:
                    is_available = False
                    break
            
            if is_available:
                available_slots.append({
                    'time': slot_start,
                    'end_time': slot_end,
                    'available': True
                })
        
        return JsonResponse({
            'slots': available_slots,
            'date': date_str,
            'working_hours': f"{start_time_str}-{end_time_str}",
            'working_days': working_days
        })
        
    except Professional.DoesNotExist:
        return JsonResponse({'error': 'Professionnel non trouvé'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@login_required
def book_appointment_page(request, pro_id):
    """Display booking page with agenda view"""
    try:
        pro = Professional.objects.select_related('user').prefetch_related('extra').get(id=pro_id)
        
        # Prepare services as a list
        services_list = []
        if pro.extra and pro.extra.services:
            if isinstance(pro.extra.services, list):
                for service in pro.extra.services:
                    if isinstance(service, dict):
                        services_list.append({
                            'name': str(service.get('Name', service.get('name', str(service)))).strip(),
                            'price': float(service.get('Price', service.get('price', 50))) if service.get('Price', service.get('price')) else 50,
                            'duration': int(service.get('Duration_Min', service.get('duration', 30))) if service.get('Duration_Min', service.get('duration')) else 30
                        })
                    else:
                        services_list.append({
                            'name': str(service).strip(),
                            'price': 50,
                            'duration': 30
                        })
            elif isinstance(pro.extra.services, str):
                for service in pro.extra.services.split(','):
                    if service.strip():
                        services_list.append({
                            'name': service.strip(),
                            'price': 50,
                            'duration': 30
                        })
        
        if not services_list:
            services_list = [{'name': 'Service Général', 'price': 50, 'duration': 60}]
        
        # Get working hours and days from professional profile
        if pro.extra:
            working_hours_dict = pro.extra.working_hours if pro.extra.working_hours else {'start': '09:00', 'end': '18:00'}
            working_days = pro.extra.working_days if pro.extra.working_days else ['mon', 'tue', 'wed', 'thu', 'fri']
        else:
            working_hours_dict = {'start': '09:00', 'end': '18:00'}
            working_days = ['mon', 'tue', 'wed', 'thu', 'fri']
        
        # Convert working hours to string format for template compatibility
        if isinstance(working_hours_dict, dict):
            working_hours = f"{working_hours_dict.get('start', '09:00')}-{working_hours_dict.get('end', '18:00')}"
        else:
            working_hours = str(working_hours_dict) if working_hours_dict else "09:00-18:00"
        
        context = {
            'pro': pro,
            'pro_id': pro_id,
            'services_list': services_list,
            'working_hours': working_hours,
            'working_days': working_days,
        }
        
        return render(request, 'front_web/book_appointment.html', context)
        
    except Professional.DoesNotExist:
        messages.error(request, 'Professionnel non trouvé.')
        return redirect('front_web:client_dashboard')


@login_required
def create_review(request: HttpRequest, pro_id: int) -> HttpResponse:
    """Afficher le formulaire de création d'avis"""
    try:
        pro = Professional.objects.select_related('user').prefetch_related('extra').get(id=pro_id)
        
        # Vérifier que l'utilisateur a un profil client
        if not hasattr(request.user, 'client_profile'):
            messages.error(request, "Seuls les clients peuvent donner des avis.")
            return redirect('client_dashboard')
        
        # Vérifier s'il y a déjà un avis
        existing_review = Review.objects.filter(client=request.user, professional=pro).first()
        
        context = {
            'pro': pro,
            'pro_id': pro_id,
            'existing_review': existing_review,
        }
        return render(request, 'front_web/create_review.html', context)
        
    except Professional.DoesNotExist:
        messages.error(request, "Professionnel non trouvé.")
        return redirect('client_dashboard')
    except Exception as e:
        messages.error(request, f"Une erreur est survenue: {str(e)}")
        return redirect('client_dashboard')


@login_required
def pro_reviews_management(request: HttpRequest) -> HttpResponse:
    """Gestion des avis pour les professionnelles"""
    try:
        # Vérifier que l'utilisateur est une professionnelle
        try:
            pro = Professional.objects.get(user=request.user)
            extra = pro.extra
        except Professional.DoesNotExist:
            messages.error(request, 'Vous devez être une professionnelle pour accéder à cette page.')
            return redirect('front_web:pro_dashboard')
        
        # Récupérer les paramètres de filtrage
        search_query = request.GET.get('search', '')
        rating_filter = request.GET.get('rating', '')
        status_filter = request.GET.get('status', '')
        sort_by = request.GET.get('sort', 'newest')
        
        # Construire la requête de base
        reviews = Review.objects.filter(professional=pro).select_related('client', 'professional')
        
        # Appliquer les filtres
        if search_query:
            reviews = reviews.filter(
                Q(comment__icontains=search_query) |
                Q(client__first_name__icontains=search_query) |
                Q(client__last_name__icontains=search_query)
            )
        
        if rating_filter:
            reviews = reviews.filter(rating=rating_filter)
        
        if status_filter == 'verified':
            reviews = reviews.filter(is_verified=True)
        elif status_filter == 'unverified':
            reviews = reviews.filter(is_verified=False)
        elif status_filter == 'public':
            reviews = reviews.filter(is_public=True)
        elif status_filter == 'private':
            reviews = reviews.filter(is_public=False)
        
        # Appliquer le tri
        if sort_by == 'newest':
            reviews = reviews.order_by('-created_at')
        elif sort_by == 'oldest':
            reviews = reviews.order_by('created_at')
        elif sort_by == 'rating_high':
            reviews = reviews.order_by('-rating', '-created_at')
        elif sort_by == 'rating_low':
            reviews = reviews.order_by('rating', '-created_at')
        
        # Pagination
        paginator = Paginator(reviews, 10)
        page_number = request.GET.get('page')
        page_obj = paginator.get_page(page_number)
        
        # Statistiques
        total_reviews = reviews.count()
        verified_reviews = reviews.filter(is_verified=True).count()
        public_reviews = reviews.filter(is_public=True).count()
        avg_rating = reviews.aggregate(avg_rating=Avg('rating'))['avg_rating'] or 0
        
        # Distribution des notes avec pourcentages
        rating_distribution = {}
        for i in range(1, 6):
            count = reviews.filter(rating=i).count()
            percentage = (count * 100 / total_reviews) if total_reviews > 0 else 0
            rating_distribution[i] = {
                'count': count,
                'percentage': round(percentage, 1)
            }
        
        # Choix pour les filtres
        rating_choices = [
            ('', 'Toutes les notes'),
            ('5', '5 étoiles'),
            ('4', '4 étoiles'),
            ('3', '3 étoiles'),
            ('2', '2 étoiles'),
            ('1', '1 étoile'),
        ]
        
        status_choices = [
            ('', 'Tous les statuts'),
            ('verified', 'Vérifiés'),
            ('unverified', 'Non vérifiés'),
            ('public', 'Publics'),
            ('private', 'Privés'),
        ]
        
        sort_choices = [
            ('newest', 'Plus récents'),
            ('oldest', 'Plus anciens'),
            ('rating_high', 'Note élevée'),
            ('rating_low', 'Note faible'),
        ]
        
        context = {
            'pro': pro,
            'extra': extra,
            'page_obj': page_obj,
            'reviews': page_obj.object_list,
            'search_query': search_query,
            'rating_filter': rating_filter,
            'status_filter': status_filter,
            'sort_by': sort_by,
            'rating_choices': rating_choices,
            'status_choices': status_choices,
            'sort_choices': sort_choices,
            'statistics': {
                'total_reviews': total_reviews,
                'verified_reviews': verified_reviews,
                'public_reviews': public_reviews,
                'avg_rating': round(avg_rating, 1),
                'rating_distribution': rating_distribution,
            }
        }
        
        return render(request, 'front_web/pro_reviews_management.html', context)
        
    except Professional.DoesNotExist:
        messages.error(request, 'Vous devez être une professionnelle pour accéder à cette page.')
        return redirect('client_dashboard')
    except Exception as e:
        messages.error(request, f'Une erreur est survenue: {str(e)}')
        return redirect('front_web:pro_dashboard')


@login_required
@require_POST
def pro_review_response(request: HttpRequest, review_id: int) -> HttpResponse:
    """Permettre aux professionnelles de répondre aux avis"""
    try:
        pro = Professional.objects.get(user=request.user)
        review = Review.objects.get(id=review_id, professional=pro)
        
        response_text = request.POST.get('response_text', '').strip()
        
        if not response_text:
            return JsonResponse({'success': False, 'message': 'Le texte de réponse ne peut pas être vide.'})
        
        # Ajouter la réponse à l'avis (nous devons d'abord ajouter ce champ au modèle)
        # Pour l'instant, nous allons stocker dans un champ JSON
        if not hasattr(review, 'professional_response'):
            # Si le champ n'existe pas encore, nous allons l'ajouter via une migration
            pass
        
        # Mettre à jour l'avis avec la réponse
        review.professional_response = response_text
        review.professional_response_date = timezone.now()
        review.save()
        
        return JsonResponse({
            'success': True, 
            'message': 'Réponse ajoutée avec succès!',
            'response_text': response_text,
            'response_date': review.professional_response_date.strftime('%d %b %Y à %H:%M')
        })
        
    except Professional.DoesNotExist:
        return JsonResponse({'success': False, 'message': 'Accès non autorisé.'})
    except Review.DoesNotExist:
        return JsonResponse({'success': False, 'message': 'Avis non trouvé.'})
    except Exception as e:
        return JsonResponse({'success': False, 'message': f'Erreur: {str(e)}'})


@login_required
@require_POST
def pro_toggle_review_visibility(request: HttpRequest, review_id: int) -> HttpResponse:
    """Permettre aux professionnelles de basculer la visibilité de leurs avis"""
    try:
        pro = Professional.objects.get(user=request.user)
        review = Review.objects.get(id=review_id, professional=pro)
        
        # Basculer la visibilité
        review.is_public = not review.is_public
        review.save()
        
        return JsonResponse({
            'success': True,
            'message': f'Avis {"publié" if review.is_public else "masqué"} avec succès!',
            'is_public': review.is_public
        })
        
    except Professional.DoesNotExist:
        return JsonResponse({'success': False, 'message': 'Accès non autorisé.'})
    except Review.DoesNotExist:
        return JsonResponse({'success': False, 'message': 'Avis non trouvé.'})
    except Exception as e:
        return JsonResponse({'success': False, 'message': f'Erreur: {str(e)}'})


@login_required
@require_POST
def submit_review(request: HttpRequest, pro_id: int) -> HttpResponse:
    """Soumettre un avis"""
    try:
        pro = Professional.objects.get(id=pro_id)
        
        # Vérifier que l'utilisateur a un profil client
        if not hasattr(request.user, 'client_profile'):
            messages.error(request, "Seuls les clients peuvent donner des avis.")
            return redirect('front_web:client_dashboard')
        
        rating = int(request.POST.get('rating', 0))
        comment = request.POST.get('comment', '').strip()
        
        if not (1 <= rating <= 5):
            messages.error(request, "Veuillez sélectionner une note entre 1 et 5 étoiles.")
            return redirect('front_web:create_review', pro_id=pro_id)
        
        # Vérifier s'il y a déjà un avis
        existing_review = Review.objects.filter(client=request.user, professional=pro).first()
        
        if existing_review:
            # Mettre à jour l'avis existant
            existing_review.rating = rating
            existing_review.comment = comment
            existing_review.save()
            messages.success(request, "Votre avis a été mis à jour avec succès.")
        else:
            # Créer un nouvel avis
            Review.objects.create(
                client=request.user,
                professional=pro,
                rating=rating,
                comment=comment
            )
            messages.success(request, "Votre avis a été enregistré avec succès.")
        
        # Mettre à jour les statistiques du professionnel
        from reviews.views import update_professional_rating
        update_professional_rating(pro)
        
        return redirect('front_web:professional_detail', pro_id=pro_id)
        
    except Professional.DoesNotExist:
        messages.error(request, "Professionnel non trouvé.")
        return redirect('front_web:client_dashboard')
    except ValueError:
        messages.error(request, "Note invalide.")
        return redirect('front_web:create_review', pro_id=pro_id)
    except Exception as e:
        messages.error(request, f"Erreur lors de l'enregistrement de l'avis: {str(e)}")
        return redirect('front_web:create_review', pro_id=pro_id)


@login_required
def pro_dashboard(request: HttpRequest) -> HttpResponse:
    # Guard: onboarding must be completed (extra exists)
    try:
        pro = request.user.professional_profile
        # If no pro profile, redirect to home/login
        if not pro:
            return redirect('front_web:home')
        try:
            _ = pro.extra
        except ProfessionalProfileExtra.DoesNotExist:
            return redirect('front_web:pro_onboarding')
        
        # Récupérer les statistiques de rendez-vous pour l'analytique
        total_appointments = Appointment.objects.filter(professional=pro).count()
        pending_appointments = Appointment.objects.filter(professional=pro, status='pending').count()
        confirmed_appointments = Appointment.objects.filter(professional=pro, status='confirmed').count()
        completed_appointments = Appointment.objects.filter(professional=pro, status='completed').count()
        
        # Revenus total (confirmés + complétés)
        from django.db.models import Sum
        total_revenue = Appointment.objects.filter(
            professional=pro, 
            status__in=['confirmed', 'completed']
        ).aggregate(total=Sum('price'))['total'] or 0
        
        context = { 
            'pro': pro, 
            'pro_id': pro.id,
            'total_appointments': total_appointments,
            'pending_appointments': pending_appointments,
            'confirmed_appointments': confirmed_appointments,
            'completed_appointments': completed_appointments,
            'total_revenue': float(total_revenue),
        }
        
        return render(request, 'front_web/pro_dashboard.html', context)
    except Exception:
        return redirect('front_web:home')


@login_required
def pro_onboarding(request: HttpRequest) -> HttpResponse:
    """Onboarding web minimal pour compléter le profil pro (synchronisé avec mobile).

    Champs supportés (mappage vers ProfessionalProfileExtra.save):
      - bio, city, social_instagram, social_facebook, social_tiktok
      - services: liste d'objets {name, duration_min, price}
      - working_days: liste ["mon",...]
      - working_hours: {start: "09:00", end: "18:00"}
      - gallery: liste d'images base64 (optionnel)
    """
    # Préremplissage: puiser dans la dernière application puis extras
    app_hint = None
    extra_hint = None
    try:
        pro = request.user.professional_profile
        try:
            e = pro.extra
            extra_hint = {
                'bio': e.bio or '',
                'city': e.city or '',
                'phone_number': e.phone_number or getattr(pro.user, 'phone', '') or '',
                'social_instagram': e.social_instagram or '',
                'social_facebook': e.social_facebook or '',
                'social_tiktok': e.social_tiktok or '',
                'services': e.services or [],
                'working_days': e.working_days or [],
                'working_hours': e.working_hours or {},
                'gallery': e.gallery or [],
            }
            try:
                if getattr(e, 'profile_photo', None):
                    extra_hint['profile_photo_url'] = e.profile_photo.url
            except Exception:
                pass
        except ProfessionalProfileExtra.DoesNotExist:
            extra_hint = {}
        
        # Inclure business_name pour préremplir le nom du centre
        extra_hint['business_name'] = getattr(pro, 'business_name', '') or ''
        
    except Exception:
        extra_hint = {}
    
    try:
        app = ProfessionalApplication.objects.filter(email__iexact=request.user.email, is_approved=True).order_by('-created_at').first() or \
              ProfessionalApplication.objects.filter(email__iexact=request.user.email).order_by('-created_at').first()
        if app:
            app_hint = {
                'first_name': app.first_name or '',
                'last_name': app.last_name or '',
                'activity_category': app.activity_category or '',
                'service_type': app.service_type or '',
                'address': app.address or '',
                'latitude': app.latitude,
                'longitude': app.longitude,
                'email': app.email or '',
                'phone_number': app.phone_number or '',
                'salon_name': app.salon_name or '',
                'profile_photo': app.profile_photo or '',
                'id_document': app.id_document or '',
                'created_at': app.created_at.isoformat() if getattr(app, 'created_at', None) else None,
            }
    except Exception:
        app_hint = {}
    
    prefill = { 'application_hint': app_hint or {}, 'extra': extra_hint or {} }
    return render(request, 'front_web/pro_onboarding.html', { 'prefill': json.dumps(prefill) })


@login_required
def pro_profile(request: HttpRequest) -> HttpResponse:
    """Page profil professionnel (édition après onboarding).

    Réutilise le même préremplissage et le même endpoint de sauvegarde que l'onboarding.
    """
    app_hint = None
    extra_hint = None
    try:
        pro = request.user.professional_profile
        try:
            e = pro.extra
            extra_hint = {
                'bio': e.bio or '',
                'city': e.city or '',
                'phone_number': getattr(e, 'phone_number', '') or getattr(pro.user, 'phone', '') or '',
                'social_instagram': e.social_instagram or '',
                'social_facebook': e.social_facebook or '',
                'social_tiktok': e.social_tiktok or '',
                'services': e.services or [],
                'working_days': e.working_days or [],
                'working_hours': e.working_hours or {},
                'gallery': e.gallery or [],
            }
            try:
                if getattr(e, 'profile_photo', None):
                    extra_hint['profile_photo_url'] = e.profile_photo.url
            except Exception:
                pass
        except ProfessionalProfileExtra.DoesNotExist:
            extra_hint = {}

        # Inclure business_name pour préremplir le nom du centre
        extra_hint['business_name'] = getattr(pro, 'business_name', '') or ''

    except Exception:
        extra_hint = {}

    try:
        app = ProfessionalApplication.objects.filter(email__iexact=request.user.email, is_approved=True).order_by('-created_at').first() or \
              ProfessionalApplication.objects.filter(email__iexact=request.user.email).order_by('-created_at').first()
        if app:
            app_hint = {
                'first_name': app.first_name or '',
                'last_name': app.last_name or '',
                'activity_category': app.activity_category or '',
                'service_type': app.service_type or '',
                'address': app.address or '',
                'latitude': app.latitude,
                'longitude': app.longitude,
                'email': app.email or '',
                'phone_number': app.phone_number or '',
                'salon_name': app.salon_name or '',
                'profile_photo': app.profile_photo or '',
                'id_document': app.id_document or '',
                'created_at': app.created_at.isoformat() if getattr(app, 'created_at', None) else None,
            }
    except Exception:
        app_hint = {}

    prefill = { 'application_hint': app_hint or {}, 'extra': extra_hint or {} }
    return render(request, 'front_web/profil_professionnelle.html', { 'prefill': json.dumps(prefill) })
@login_required
@require_POST
def save_professional_extras_web(request: HttpRequest) -> HttpResponse:
    # Strict JSON only
    # Rate limit: max 5 saves/min per user
    try:
        key = f"pro_onboarding_rate_{request.user.id}"
        cnt = cache.get(key) or 0
        if cnt and int(cnt) >= 5:
            return HttpResponse(status=429)
        cache.set(key, int(cnt) + 1, 60)
    except Exception:
        pass

    try:
        payload = json.loads(request.body.decode('utf-8') or '{}')
    except Exception:
        return HttpResponse(status=400)
    if not hasattr(request.user, 'professional_profile'):
        return HttpResponse(status=404)
    pro = request.user.professional_profile

    def clean_str(val: str, max_len: int = 500) -> str:
        v = (val or '').strip()
        return v[:max_len]

    def clean_url(val: str) -> str:
        v = clean_str(val, 300)
        if not v:
            return ''
        if not (v.startswith('http://') or v.startswith('https://')):
            return ''
        return v

    def clean_services(arr):
        result = []
        if not isinstance(arr, list):
            return result
        for item in arr[:50]:
            if not isinstance(item, dict):
                continue
            name = clean_str(str(item.get('name', '')), 120)
            try:
                duration = int(item.get('duration_min') or 0)
            except Exception:
                duration = 0
            try:
                price = float(item.get('price') or 0)
            except Exception:
                price = 0.0
            if not name:
                continue
            duration = max(0, min(duration, 24 * 60))
            price = max(0.0, min(price, 1e6))
            result.append({'name': name, 'duration_min': duration, 'price': price})
        return result

    allowed_days = {'mon','tue','wed','thu','fri','sat','sun'}
    working_days = [d for d in (payload.get('working_days') or []) if d in allowed_days][:7]
    wh = payload.get('working_hours') or {}
    time_re = re.compile(r'^[0-2]\d:[0-5]\d$')
    start = wh.get('start') or '09:00'
    end = wh.get('end') or '18:00'
    start = start if time_re.match(start) else '09:00'
    end = end if time_re.match(end) else '18:00'

    extra, _ = ProfessionalProfileExtra.objects.get_or_create(professional=pro)
    extra.bio = clean_str(payload.get('bio') or '', 1000)
    extra.city = clean_str(payload.get('city') or '', 120)
    # Téléphone: enregistrer sur User et sur Extra (pour compatibilité)
    phone_raw = clean_str(payload.get('phone') or '', 32)
    try:
        if hasattr(pro.user, 'phone'):
            pro.user.phone = phone_raw
            pro.user.save(update_fields=['phone'])
    except Exception:
        pass
    extra.phone_number = phone_raw
    # Nom du centre: enregistrer sur Professional
    business_raw = clean_str(payload.get('business') or '', 255)
    try:
        pro.business_name = business_raw
        pro.save(update_fields=['business_name'])
    except Exception:
        pass
    # Photo de profil
    try:
        photo_src = payload.get('profile_photo') or ''
        if photo_src:
            if isinstance(photo_src, str) and photo_src.startswith('data:image'):
                header, b64data = photo_src.split(',', 1)
                ext = 'png'
                if 'jpeg' in header or 'jpg' in header:
                    ext = 'jpg'
                content = ContentFile(base64.b64decode(b64data))
                extra.profile_photo.save(f"professionals/avatars/pro_{pro.id}.{ext}", content, save=False)
            # else: if it's already a URL in MEDIA, we leave as is (client sends base64 normally)
    except Exception:
        pass
    extra.social_instagram = clean_url(payload.get('social_instagram') or '')
    extra.social_facebook = clean_url(payload.get('social_facebook') or '')
    extra.social_tiktok = clean_url(payload.get('social_tiktok') or '')
    extra.services = clean_services(payload.get('services') or [])
    extra.working_days = working_days
    extra.working_hours = {'start': start, 'end': end}
    gallery = payload.get('gallery') or []
    if isinstance(gallery, list):
        extra.gallery = gallery[:20]
    extra.save()
    return HttpResponse(status=204)


@login_required
def booking_page(request: HttpRequest) -> HttpResponse:
    try:
        pro = getattr(request.user, 'professional_profile', None)
        if not pro:
            return redirect('front_web:home')
        return render(request, 'front_web/booking.html', { 'pro': pro, 'pro_id': pro.id })
    except Exception:
        return redirect('front_web:home')


@login_required
def client_appointments(request):
    """Page des rendez-vous du client"""
    # Récupérer les rendez-vous du client (ne pas rediriger si profil manquant)
    client_profile = getattr(request.user, 'client_profile', None)
    if not client_profile:
        try:
            from users.models import Client as ClientModel
            client_profile, _ = ClientModel.objects.get_or_create(
                user=request.user,
                defaults={'phone_number': '', 'address': '', 'city': ''}
            )
        except Exception as e:
            # Afficher quand même la page vide si création impossible
            messages.error(request, f"Profil client introuvable: {str(e)}")
            client_profile = None

    appts_qs = (
        Appointment.objects.select_related('professional__user')
        .filter(client=client_profile)
        .order_by('-start')[:200]
    ) if client_profile else []

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
            # En cas d'erreur, garder les valeurs par défaut et continuer
            pass
        
        # Construire l'URL Google Maps
        map_url = ''
        try:
            if pro_info.get('latitude') is not None and pro_info.get('longitude') is not None:
                map_url = f"https://www.google.com/maps?q={pro_info['latitude']},{pro_info['longitude']}"
            elif pro_info.get('address'):
                map_url = f"https://www.google.com/maps/search/?api=1&query={quote_plus(pro_info['address'])}"
        except Exception:
            # En cas d'erreur avec l'URL, continuer sans map_url
            pass
        
        try:
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
        except Exception:
            # En cas d'erreur lors de la création du row, continuer avec le prochain rendez-vous
            continue

    return render(request, 'front_web/client_appointments.html', {
        'pending': pending,
        'confirmed': confirmed,
        'cancelled': cancelled,
        'client_profile': client_profile,
        'total_count': len(pending) + len(confirmed) + len(cancelled),
        'confirmed_count': len(confirmed),
        'pending_count': len(pending),
        'cancelled_count': len(cancelled),
    })


@login_required
def client_calendar(request):
    """Page calendrier du client - N'affiche que les rendez-vous CONFIRMÉS"""
    try:
        # Récupérer/créer le profil client au besoin (ne pas rediriger)
        client_profile = getattr(request.user, 'client_profile', None)
        if not client_profile:
            try:
                from users.models import Client as ClientModel
                client_profile, _ = ClientModel.objects.get_or_create(
                    user=request.user,
                    defaults={'phone_number': '', 'address': '', 'city': ''}
                )
            except Exception:
                messages.error(request, "Profil client non trouvé.")
                return redirect('front_web:client_dashboard')
        
        # Récupérer les rendez-vous pour le calendrier (confirmés ET en attente)
        calendar_qs = Appointment.objects.select_related('professional__user').filter(
            client=client_profile,
            status__in=['confirmed', 'pending']
        ).order_by('start')
        
        # Préparer les données pour le calendrier
        calendar_events = []
        for appt in calendar_qs:
            try:
                center_name = appt.professional.business_name or appt.professional.user.get_full_name()
            except Exception:
                center_name = "Centre"
            
            calendar_events.append({
                'id': appt.id,
                'title': f"{appt.service_name}",
                'start': appt.start.isoformat(),
                'end': appt.end.isoformat(),
                'center_name': center_name,
                'price': float(appt.price or 0),
                'status': appt.status,
                'professional_name': appt.professional.user.get_full_name(),
                'notes': appt.notes or '',
            })
        
        # Statistiques pour le client
        total_confirmed = Appointment.objects.filter(client=client_profile, status='confirmed').count()
        total_pending = Appointment.objects.filter(client=client_profile, status='pending').count()
        total_spent = sum(float(appt.price or 0) for appt in calendar_qs if appt.status == 'confirmed')
        
        return render(request, 'front_web/client_calendar.html', {
            'appointments': calendar_events,
            'client_profile': client_profile,
            'total_confirmed': total_confirmed,
            'total_pending': total_pending,
            'total_spent': total_spent,
        })
    except Exception as e:
        # Ne pas rediriger: afficher un calendrier vide avec un message d'erreur doux
        try:
            messages.error(request, f"Erreur lors du chargement du calendrier: {str(e)}")
        except Exception:
            pass
        return render(request, 'front_web/client_calendar.html', {
            'appointments': [],
            'client_profile': getattr(request.user, 'client_profile', None),
            'total_confirmed': 0,
            'total_pending': 0,
            'total_spent': 0,
        })


@login_required
def pro_appointments(request: HttpRequest) -> HttpResponse:
    """Liste des demandes et rendez-vous confirmés pour la professionnelle avec notifications."""
    try:
        try:
            pro = request.user.professional_profile
        except AttributeError:
            messages.error(request, "Vous devez être une professionnelle.")
            return redirect('front_web:home')

        appts = (
            Appointment.objects.select_related('client__user')
            .filter(professional=pro)
            .order_by('-start')[:300]
        )
        pending, confirmed = [], []
        for a in appts:
            # Récupération complète des informations client
            client_info = {
                'name': 'Client',
                'first_name': '',
                'last_name': '',
                'email': '',
                'phone': '',
                'full_name': 'Client'
            }
            
            try:
                if a.client and a.client.user:
                    user = a.client.user
                    client_info.update({
                        'first_name': user.first_name or '',
                        'last_name': user.last_name or '',
                        'email': user.email or '',
                        'full_name': user.get_full_name() or f"{user.first_name} {user.last_name}".strip() or user.username,
                    })
                    
                    # Récupérer le téléphone depuis le profil client
                    if hasattr(a.client, 'phone_number') and a.client.phone_number:
                        client_info['phone'] = a.client.phone_number
                        
            except Exception as e:
                pass  # Garder les valeurs par défaut
            
            row = {
                'id': a.id,
                'service_name': a.service_name,
                'price': float(a.price or 0),
                'start': a.start,
                'end': a.end,
                'status': a.status,
                'client_name': client_info['full_name'],
                'client_first_name': client_info['first_name'],
                'client_last_name': client_info['last_name'],
                'client_email': client_info['email'],
                'client_phone': client_info['phone'],
                'notes': a.notes or '',
            }
            if a.status == 'pending':
                pending.append(row)
            elif a.status == 'confirmed':
                confirmed.append(row)

        # Get recent notifications
        from appointments.models import Notification
        recent_notifications = Notification.objects.filter(
            professional=pro
        ).order_by('-created_at')[:15]
        
        # Count unread notifications
        unread_count = Notification.objects.filter(professional=pro, is_read=False).count()

        context = {
            'pending': pending,
            'confirmed': confirmed,
            'pro': pro,
            'recent_notifications': recent_notifications,
            'unread_count': unread_count,
        }
        return render(request, 'front_web/pro_appointments.html', context)
    except Exception as e:
        messages.error(request, f"Erreur: {str(e)}")
        return redirect('front_web:pro_dashboard')

