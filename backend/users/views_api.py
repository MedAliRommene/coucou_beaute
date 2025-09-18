from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.decorators import authentication_classes
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework.response import Response
from django.conf import settings
from django.core.files.storage import default_storage
from django.utils.timezone import now
from rest_framework_simplejwt.tokens import RefreshToken

from .models import ProfessionalApplication, ProfessionalApplicationAction, User
from .models import Professional, ProfessionalProfileExtra
import re
import math
from .serializers import ProfessionalApplicationSerializer, ClientRegistrationSerializer


@api_view(["POST"]) 
@permission_classes([AllowAny])
def submit_professional_application(request):
    serializer = ProfessionalApplicationSerializer(data=request.data)
    if serializer.is_valid():
        app = serializer.save()

        # Création optionnelle du compte utilisateur si password est fourni
        raw_password = request.data.get('password') or request.data.get('mot_de_passe')
        if raw_password:
            try:
                user = User.objects.get(email=app.email)
            except User.DoesNotExist:
                # username dérivé de l'email
                base_username = (app.email.split('@')[0] or "pro").replace(" ", "_")[:150]
                username = base_username
                i = 1
                while User.objects.filter(username=username).exists():
                    suffix = f"_{i}"
                    username = (base_username[: (150 - len(suffix))] + suffix)
                    i += 1
                phone_fallback = getattr(app, 'phone_number', None) or '00000000'
                extra_fields = {}
                if hasattr(User, 'phone'):
                    extra_fields["phone"] = phone_fallback
                if hasattr(User, 'role'):
                    extra_fields["role"] = "professional"
                if hasattr(User, 'language'):
                    extra_fields["language"] = "fr"
                normalized_email = (app.email or "").strip().lower()
                user = User.objects.create_user(username=username, email=normalized_email, password=raw_password, **extra_fields)
                user.first_name = getattr(app, 'first_name', '')
                user.last_name = getattr(app, 'last_name', '')
                user.is_active = False
                user.save()

        ProfessionalApplicationAction.objects.create(
            application=app, action="submitted", actor=None, notes="Soumission via mobile"
        )
        return Response(ProfessionalApplicationSerializer(app).data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(["POST"]) 
@permission_classes([AllowAny])
def upload_application_file(request):
    file_obj = request.FILES.get("file")
    if not file_obj:
        return Response({"file": "Fichier requis"}, status=status.HTTP_400_BAD_REQUEST)

    kind = (request.POST.get("kind") or "attachment").strip().lower()
    safe_kind = "profile" if kind == "profile_photo" else ("id" if kind == "id_document" else "attachment")
    filename = f"applications/{safe_kind}_{int(now().timestamp())}_{file_obj.name}"
    saved_path = default_storage.save(filename, file_obj)
    url = f"{settings.MEDIA_URL}{saved_path}"
    return Response({"path": saved_path, "url": url})


@api_view(["POST"]) 
@permission_classes([AllowAny])
def login_with_email(request):
    email = (request.data.get("email") or "").strip()
    password = request.data.get("password") or ""
    expected_role = (request.data.get("expected_role") or "").strip().lower() or None
    if not email or not password:
        return Response({"detail": "Email et mot de passe requis"}, status=status.HTTP_400_BAD_REQUEST)
    user = User.objects.filter(email__iexact=email).first()
    if user is None:
        # Tolérer espaces parasites en base
        normalized = re.sub(r"\s+", "", email.lower())
        candidates = User.objects.filter(email__icontains=email.split('@')[0])[:10]
        for u in candidates:
            if re.sub(r"\s+", "", (u.email or "").lower()) == normalized:
                user = u
                break
    if user is None:
        return Response({"email": ["Aucun compte avec cet e-mail"]}, status=status.HTTP_400_BAD_REQUEST)
    if not user.is_active:
        return Response({"detail": "Compte non activé. Veuillez patienter après approbation."}, status=status.HTTP_403_FORBIDDEN)
    if not user.check_password(password):
        return Response({"password": ["Mot de passe incorrect"]}, status=status.HTTP_400_BAD_REQUEST)

    refresh = RefreshToken.for_user(user)
    role = "professional" if hasattr(user, "professional_profile") else ("client" if hasattr(user, "client_profile") else "user")
    if expected_role and expected_role != role:
        return Response({"detail": "Type de compte différent. Veuillez choisir le bon rôle."}, status=status.HTTP_403_FORBIDDEN)
    return Response({
        "access": str(refresh.access_token),
        "refresh": str(refresh),
        "role": role,
        "user": {
            "id": user.id,
            "email": user.email,
            "first_name": user.first_name,
            "last_name": user.last_name,
        }
    })



@api_view(["GET"]) 
@permission_classes([IsAuthenticated])
@authentication_classes([JWTAuthentication])
def me_profile(request):
    """Retourne les informations du profil courant pour éviter la redondance sur mobile.

    - user: infos basiques
    - role: professional|client|user
    - professional_profile: si existe, profil minimal
    - application_hint: dernière demande (approuvée en priorité, sinon la plus récente)
    """
    user = request.user
    role = "professional" if hasattr(user, "professional_profile") else ("client" if hasattr(user, "client_profile") else "user")

    professional_profile = None
    client_profile = None
    if hasattr(user, "professional_profile"):
        pro = user.professional_profile
        professional_profile = {
            "business_name": pro.business_name,
            "is_verified": pro.is_verified,
            "created_at": pro.created_at.isoformat(),
        }
        # Extras si présents
        try:
            extra = pro.extra
            professional_profile["extra"] = {
                "bio": extra.bio,
                "city": extra.city,
                "social_instagram": extra.social_instagram,
                "social_facebook": extra.social_facebook,
                "social_tiktok": extra.social_tiktok,
                "services": extra.services,
                "working_days": extra.working_days,
                "working_hours": extra.working_hours,
                "gallery": extra.gallery,
                "updated_at": extra.updated_at.isoformat(),
            }
        except ProfessionalProfileExtra.DoesNotExist:
            pass

    # Client profile (address center)
    if hasattr(user, "client_profile"):
        cp = user.client_profile
        client_profile = {
            "address": getattr(cp, "address", ""),
            "city": getattr(cp, "city", ""),
            "latitude": getattr(cp, "latitude", None),
            "longitude": getattr(cp, "longitude", None),
            "created_at": cp.created_at.isoformat(),
        }

    # Chercher une application pour pré-remplissage (pro)
    app = None
    try:
        from .models import ProfessionalApplication
        # prioriser approuvée
        app = ProfessionalApplication.objects.filter(email__iexact=user.email, is_approved=True).order_by("-created_at").first() or \
              ProfessionalApplication.objects.filter(email__iexact=user.email).order_by("-created_at").first()
    except Exception:
        app = None

    application_hint = None
    if app:
        application_hint = {
            "first_name": app.first_name,
            "last_name": app.last_name,
            "email": app.email,
            "phone_number": app.phone_number,
            "activity_category": app.activity_category,
            "service_type": app.service_type,
            "spoken_languages": app.spoken_languages,
            "address": app.address,
            "latitude": app.latitude,
            "longitude": app.longitude,
            "profile_photo": app.profile_photo,
            "id_document": app.id_document,
            "subscription_active": app.subscription_active,
            "salon_name": app.salon_name,
            "created_at": app.created_at.isoformat(),
            "is_approved": app.is_approved,
        }

    has_profile = professional_profile is not None
    return Response({
        "role": role,
        "has_profile": has_profile,
        "user": {
            "id": user.id,
            "email": user.email,
            "first_name": user.first_name,
            "last_name": user.last_name,
        },
        "professional_profile": professional_profile,
        "client_profile": client_profile,
        "application_hint": application_hint,
    })


@api_view(["POST"]) 
@permission_classes([IsAuthenticated])
@authentication_classes([JWTAuthentication])
def save_professional_extras(request):
    user = request.user
    if not hasattr(user, "professional_profile"):
        return Response({"detail": "Profil professionnel introuvable"}, status=status.HTTP_404_NOT_FOUND)
    pro = user.professional_profile

    payload = request.data or {}
    bio = (payload.get("bio") or "").strip()
    city = (payload.get("city") or "").strip()
    social_instagram = (payload.get("social_instagram") or "").strip()
    social_facebook = (payload.get("social_facebook") or "").strip()
    social_tiktok = (payload.get("social_tiktok") or "").strip()
    services = payload.get("services") or []
    working_days = payload.get("working_days") or []
    working_hours = payload.get("working_hours") or {}
    gallery = payload.get("gallery") or []

    extra, _ = ProfessionalProfileExtra.objects.get_or_create(professional=pro)
    extra.bio = bio
    extra.city = city
    extra.social_instagram = social_instagram
    extra.social_facebook = social_facebook
    extra.social_tiktok = social_tiktok
    extra.services = services
    extra.working_days = working_days
    extra.working_hours = working_hours
    extra.gallery = gallery
    extra.save()

    return Response({"ok": True, "updated_at": extra.updated_at.isoformat()})


@api_view(["GET"]) 
@permission_classes([AllowAny])
def professionals_search(request):
    """Mobile: liste paginée des professionnels vérifiés avec position et filtres.

    Query params:
      - category: hairdressing|makeup|manicure|esthetics|massage
      - page (1-based), page_size
      - center_lat, center_lng: centre de recherche
      - within_km: rayon max (par défaut 25)
      - price_min, price_max (placeholders, utilisent extra.price si dispo sinon valeur fictive)
      - min_rating (utilise extra.rating si dispo sinon valeur fictive)
      - langs: liste séparée par virgules (FR,EN,AR, etc.)
    """
    try:
        page = max(int(request.GET.get("page", 1)), 1)
    except Exception:
        page = 1
    try:
        page_size = min(max(int(request.GET.get("page_size", 20)), 1), 100)
    except Exception:
        page_size = 20

    category = (request.GET.get("category") or "").strip().lower()
    center_lat = request.GET.get("center_lat")
    center_lng = request.GET.get("center_lng")
    within_km = float(request.GET.get("within_km") or 25)
    price_min = float(request.GET.get("price_min") or 0)
    price_max = float(request.GET.get("price_max") or 1e9)
    min_rating = float(request.GET.get("min_rating") or 0)
    langs_param = (request.GET.get("langs") or "").strip()
    langs = [s.strip().lower() for s in langs_param.split(",") if s.strip()]

    def haversine_km(lat1, lon1, lat2, lon2):
        from math import radians, cos, sin, asin, sqrt
        dlat = radians(lat2 - lat1)
        dlon = radians(lon2 - lon1)
        a = sin(dlat/2)**2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon/2)**2
        c = 2 * asin(sqrt(a))
        return 6371.0 * c

    pros_qs = Professional.objects.select_related("user").filter(is_verified=True).order_by("-created_at")
    items = []
    for pro in pros_qs:
        app = ProfessionalApplication.objects.filter(email__iexact=pro.user.email, is_approved=True).order_by("-created_at").first() or \
              ProfessionalApplication.objects.filter(email__iexact=pro.user.email).order_by("-created_at").first()

        if category and app and (app.activity_category or "").lower() != category:
            continue

        extra_dict = {}
        try:
            e = pro.extra
            extra_dict = {
                "city": e.city,
                "services": e.services,
                "working_days": e.working_days,
                "working_hours": e.working_hours,
                "bio": e.bio,
                "gallery": e.gallery,
                "social_instagram": e.social_instagram,
                "social_facebook": e.social_facebook,
                "social_tiktok": e.social_tiktok,
            }
        except ProfessionalProfileExtra.DoesNotExist:
            pass

        spoken = (app.spoken_languages if app else []) or []
        lat = (app.latitude if app else None)
        lng = (app.longitude if app else None)
        rating = (extra_dict.get("rating") or 4.8)
        # Derive a representative price from services if available (min price)
        price = None
        try:
            services = extra_dict.get("services") or []
            for s in services:
                p = s.get("price") if isinstance(s, dict) else None
                if isinstance(p, (int, float)):
                    price = p if price is None else min(price, p)
        except Exception:
            price = None
        if price is None:
            price = 100

        # Filtres côté serveur
        if langs:
            low_spoken = [str(x).lower() for x in (spoken or [])]
            if not any(l in low_spoken for l in langs):
                continue
        if min_rating and (rating is None or float(rating) < min_rating):
            continue
        if (float(price) < price_min) or (float(price) > price_max):
            continue
        distance_km = None
        if center_lat and center_lng and lat is not None and lng is not None:
            try:
                distance_km = haversine_km(float(center_lat), float(center_lng), float(lat), float(lng))
                if within_km and distance_km > within_km:
                    continue
            except Exception:
                distance_km = None

        item = {
            "id": pro.id,
            "business_name": pro.business_name or pro.user.get_full_name() or pro.user.email,
            "email": pro.user.email,
            "is_verified": pro.is_verified,
            "created_at": pro.created_at.isoformat(),
            "extra": {
                **extra_dict,
                "spoken_languages": spoken,
                "latitude": lat,
                "longitude": lng,
                "primary_service": app.activity_category if app else None,
                "rating": rating,
                "reviews": 12,
                "price": price,
                "distance_km": distance_km,
                "address": getattr(app, "address", None),
            },
        }
        items.append(item)

    # Tri par distance si fournie
    if center_lat and center_lng:
        items.sort(key=lambda x: (x["extra"].get("distance_km") or 1e9))

    total = len(items)
    start = (page - 1) * page_size
    end = start + page_size
    page_items = items[start:end]
    return Response({
        "count": total,
        "page": page,
        "page_size": page_size,
        "results": page_items,
    })


@api_view(["GET"]) 
@permission_classes([AllowAny])
def professionals_categories(request):
    """Return available categories (from applications) and global price range derived
    from professional services, for dynamic filters on mobile.

    Output:
      { "categories": [{"code": "hairdressing", "label": "Coiffure"}, ...],
        "price_min": 20, "price_max": 300 }
    """
    def fr_label(code: str) -> str:
        mapping = {
            "hairdressing": "Coiffure",
            "makeup": "Maquillage",
            "manicure": "Manucure",
            "esthetics": "Esthétique",
            "massage": "Massage",
            "other": "Autres",
        }
        return mapping.get(code, code.capitalize())

    cats = set()
    global_min = None
    global_max = None

    for pro in Professional.objects.filter(is_verified=True):
        app = ProfessionalApplication.objects.filter(email__iexact=pro.user.email, is_approved=True).order_by("-created_at").first() or \
              ProfessionalApplication.objects.filter(email__iexact=pro.user.email).order_by("-created_at").first()
        if app and app.activity_category:
            cats.add(app.activity_category)
        try:
            e = pro.extra
            services = e.services or []
            for s in services:
                p = s.get("price") if isinstance(s, dict) else None
                if isinstance(p, (int, float)):
                    global_min = p if global_min is None else min(global_min, p)
                    global_max = p if global_max is None else max(global_max, p)
        except ProfessionalProfileExtra.DoesNotExist:
            pass

    categories = [{"code": c, "label": fr_label(c)} for c in sorted(cats)]
    return Response({
        "categories": categories,
        "price_min": float(global_min or 0),
        "price_max": float(global_max or 300),
    })


@api_view(["POST"]) 
@permission_classes([AllowAny])
def register_client(request):
    serializer = ClientRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        # Auto-login (JWT)
        refresh = RefreshToken.for_user(user)
        return Response({
            "access": str(refresh.access_token),
            "refresh": str(refresh),
            "role": "client",
            "user": {
                "id": user.id,
                "email": user.email,
                "first_name": user.first_name,
                "last_name": user.last_name,
            }
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


def calculate_distance(lat1, lon1, lat2, lon2):
    """Calculate distance between two points in kilometers using Haversine formula"""
    R = 6371  # Earth's radius in kilometers
    
    lat1_rad = math.radians(lat1)
    lon1_rad = math.radians(lon1)
    lat2_rad = math.radians(lat2)
    lon2_rad = math.radians(lon2)
    
    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad
    
    a = math.sin(dlat/2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a))
    
    return R * c


@api_view(["GET"])
@permission_classes([AllowAny])
def search_professionals(request):
    """Search for professionals with filters"""
    try:
        # Get parameters
        center_lat = float(request.GET.get('center_lat', 36.4515))
        center_lng = float(request.GET.get('center_lng', 10.7353))
        within_km = float(request.GET.get('within_km', 25))
        price_min = float(request.GET.get('price_min', 0))
        price_max = float(request.GET.get('price_max', 300))
        min_rating = float(request.GET.get('min_rating', 0))
        category = request.GET.get('category', '')
        search_query = request.GET.get('search', '')
        language = request.GET.get('language', '')
        
        # Get all active professionals with extra profiles
        professionals = Professional.objects.filter(
            user__is_active=True,
            user__is_staff=False
        ).select_related('user').prefetch_related('extra')
        
        results = []
        
        for pro in professionals:
            try:
                # Get extra profile data
                extra = pro.extra
                pro_lat = extra.latitude
                pro_lng = extra.longitude
                
                if pro_lat is None or pro_lng is None:
                    continue
                
                # Calculate distance
                distance = calculate_distance(center_lat, center_lng, pro_lat, pro_lng)
                
                if distance > within_km:
                    continue
                
                # Get spoken languages first
                languages = []
                if extra.spoken_languages:
                    try:
                        languages = [lang.strip() for lang in extra.spoken_languages.split(',')]
                    except:
                        languages = ['french']
                else:
                    languages = ['french']
                
                # Filter by language
                if language and language not in languages:
                    continue
                
                # Filter by category
                if category and category != 'all':
                    if extra.primary_service != category:
                        continue
                
                # Filter by search query
                if search_query:
                    search_lower = search_query.lower()
                    if not any([
                        search_lower in (pro.business_name or '').lower(),
                        search_lower in (extra.bio or '').lower(),
                        search_lower in (pro.user.first_name or '').lower(),
                        search_lower in (pro.user.last_name or '').lower(),
                    ]):
                        continue
                
                # Get rating and price
                rating = extra.rating or 4.0
                price = extra.price or 50
                
                # Filter by rating and price
                if rating < min_rating or price < price_min or price > price_max:
                    continue
                
                # Get services
                services = []
                if extra.services and isinstance(extra.services, list):
                    services = [service.get('name', 'Service') for service in extra.services[:3]]
                elif extra.services and isinstance(extra.services, str):
                    try:
                        services = extra.services.split(',')[:3]
                    except:
                        services = []
                
                # Get profile photo
                profile_photo = None
                if extra.profile_photo:
                    profile_photo = extra.profile_photo.url
                
                # Get gallery images
                gallery = []
                if extra.gallery and isinstance(extra.gallery, list):
                    gallery = extra.gallery[:5]
                elif extra.gallery and isinstance(extra.gallery, str):
                    try:
                        gallery = extra.gallery.split(',')[:5]
                    except:
                        gallery = []
                
                # Ensure we have valid data
                name = pro.business_name or f"{pro.user.first_name} {pro.user.last_name}".strip() or "Professionnel"
                service = extra.primary_service or 'Service'
                rating_val = round(rating, 1) if rating else 4.0
                price_val = int(price) if price else 50
                reviews_val = extra.reviews or 0
                bio_val = extra.bio or ''
                phone_val = extra.phone_number or ''
                address_val = extra.address or ''
                city_val = extra.city or ''
                
                results.append({
                    'id': pro.id,
                    'name': name,
                    'service': service,
                    'categoryCode': service or 'other',
                    'rating': rating_val,
                    'reviews': reviews_val,
                    'price': price_val,
                    'lat': pro_lat,
                    'lng': pro_lng,
                    'langs': languages,
                    'distanceKm': round(distance, 1),
                    'bio': bio_val,
                    'services': services,
                    'profile_photo': profile_photo,
                    'gallery': gallery,
                    'phone': phone_val,
                    'address': address_val,
                    'city': city_val,
                    'email': pro.user.email or '',
                    'extra': {
                        'bio': bio_val,
                        'services': services,
                        'gallery': gallery,
                        'rating': rating_val,
                        'reviews': reviews_val,
                        'price': price_val,
                        'spoken_languages': languages,
                        'working_days': extra.working_days or [],
                        'working_hours': extra.working_hours or {},
                        'social_instagram': extra.social_instagram or '',
                        'social_facebook': extra.social_facebook or '',
                        'social_tiktok': extra.social_tiktok or '',
                    }
                })
                
            except Exception as e:
                continue
        
        # Sort by distance
        results.sort(key=lambda x: x['distanceKm'])
        
        return Response({
            'results': results,
            'count': len(results)
        })
        
    except Exception as e:
        return Response({
            'error': str(e),
            'results': [],
            'count': 0
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["GET"])
@permission_classes([AllowAny])
def get_professional_categories(request):
    """Get list of professional categories"""
    categories = [
        {'code': 'all', 'label': 'Tous'},
        {'code': 'hairdressing', 'label': 'Coiffure'},
        {'code': 'makeup', 'label': 'Maquillage'},
        {'code': 'manicure', 'label': 'Manucure'},
        {'code': 'esthetics', 'label': 'Esthétique'},
        {'code': 'massage', 'label': 'Massage'},
        {'code': 'other', 'label': 'Autre'},
    ]
    
    return Response({
        'categories': categories
    })

@api_view(["GET"])
@permission_classes([AllowAny])
def test_professionals(request):
    """Test API to get all professionals with coordinates"""
    try:
        professionals = Professional.objects.filter(
            user__is_active=True,
            user__is_staff=False
        ).select_related('user').prefetch_related('extra')
        
        results = []
        
        for pro in professionals:
            try:
                extra = pro.extra
                pro_lat = extra.latitude
                pro_lng = extra.longitude
                
                if pro_lat is None or pro_lng is None:
                    continue
                
                # Calculate distance from center
                center_lat = 36.8065
                center_lng = 10.1815
                distance = calculate_distance(center_lat, center_lng, pro_lat, pro_lng)
                
                results.append({
                    'id': pro.id,
                    'name': pro.business_name or f"{pro.user.first_name} {pro.user.last_name}".strip(),
                    'service': extra.primary_service or 'Service',
                    'rating': extra.rating or 4.0,
                    'price': extra.price or 50,
                    'lat': pro_lat,
                    'lng': pro_lng,
                    'distanceKm': round(distance, 1),
                    'phone': extra.phone_number or '',
                    'address': extra.address or '',
                    'city': extra.city or '',
                })
                
            except Exception as e:
                continue
        
        return Response({
            'results': results,
            'count': len(results)
        })
        
    except Exception as e:
        return Response({'error': str(e), 'results': [], 'count': 0}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(["GET"])
@permission_classes([AllowAny])
def get_all_professionals(request):
    """Simple API to get all professionals with coordinates"""
    try:
        # Get all professionals with extra profiles
        professionals = Professional.objects.filter(
            user__is_active=True,
            user__is_staff=False
        ).select_related('user').prefetch_related('extra')
        
        results = []
        
        for pro in professionals:
            try:
                extra = pro.extra
                
                # Skip if no coordinates
                if not extra.latitude or not extra.longitude:
                    continue
                
                # Calculate distance from center
                center_lat = float(request.GET.get('center_lat', 36.8065))
                center_lng = float(request.GET.get('center_lng', 10.1815))
                distance = calculate_distance(center_lat, center_lng, extra.latitude, extra.longitude)
                
                # Get services
                services = []
                if extra.services and isinstance(extra.services, list):
                    services = [service.get('name', 'Service') for service in extra.services[:3]]
                elif extra.services and isinstance(extra.services, str):
                    try:
                        services = extra.services.split(',')[:3]
                    except:
                        services = []
                
                # Get profile photo
                profile_photo = None
                if extra.profile_photo:
                    profile_photo = extra.profile_photo.url
                
                # Get spoken languages
                languages = []
                if extra.spoken_languages:
                    try:
                        languages = [lang.strip() for lang in extra.spoken_languages.split(',')]
                    except:
                        languages = ['french']
                else:
                    languages = ['french']
                
                results.append({
                    'id': pro.id,
                    'name': pro.business_name or f"{pro.user.first_name} {pro.user.last_name}".strip() or "Professionnel",
                    'service': extra.primary_service or 'Service',
                    'categoryCode': extra.primary_service or 'other',
                    'rating': round(extra.rating, 1) if extra.rating else 4.0,
                    'reviews': extra.reviews or 0,
                    'price': int(extra.price) if extra.price else 50,
                    'lat': extra.latitude,
                    'lng': extra.longitude,
                    'langs': languages,
                    'distanceKm': round(distance, 1),
                    'bio': extra.bio or '',
                    'services': services,
                    'profile_photo': profile_photo,
                    'gallery': [],
                    'phone': extra.phone_number or '',
                    'address': extra.address or '',
                    'city': extra.city or '',
                    'email': pro.user.email or '',
                    'extra': {
                        'bio': extra.bio or '',
                        'services': services,
                        'gallery': [],
                        'rating': round(extra.rating, 1) if extra.rating else 4.0,
                        'reviews': extra.reviews or 0,
                        'price': int(extra.price) if extra.price else 50,
                        'spoken_languages': languages,
                        'working_days': extra.working_days or [],
                        'working_hours': extra.working_hours or {},
                        'social_instagram': extra.social_instagram or '',
                        'social_facebook': extra.social_facebook or '',
                        'social_tiktok': extra.social_tiktok or '',
                    }
                })
                
            except Exception as e:
                print(f"Error processing professional {pro.id}: {e}")
                continue
        
        # Sort by distance
        results.sort(key=lambda x: x['distanceKm'])
        
        return Response({
            'results': results,
            'count': len(results)
        })
        
    except Exception as e:
        print(f"API Error: {e}")
        return Response({'error': str(e), 'results': [], 'count': 0}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(["GET"])
@permission_classes([AllowAny])
def simple_professionals_api(request):
    """API pour récupérer tous les professionnels avec coordonnées"""
    try:
        print(f"🔍 API simple_professionals_api appelée avec params: {dict(request.GET)}")
        
        # Get all professionals
        professionals = Professional.objects.filter(
            user__is_active=True,
            user__is_staff=False
        ).select_related('user', 'extra')
        
        print(f"📊 Total professionnels trouvés: {professionals.count()}")
        
        results = []
        skipped_no_coords = 0
        skipped_no_extra = 0

        for pro in professionals:
            try:
                # Extra (peut être absent)
                try:
                    extra = pro.extra
                except Exception:
                    extra = None
                    skipped_no_extra += 1

                # Coordonnées (facultatives)
                lat_val = float(extra.latitude) if (extra and extra.latitude is not None) else None
                lng_val = float(extra.longitude) if (extra and extra.longitude is not None) else None

                # Si manquantes, essayer via la dernière application
                if (lat_val is None or lng_val is None):
                    app = ProfessionalApplication.objects.filter(email__iexact=pro.user.email).order_by('-created_at').first()
                    try:
                        if app and app.latitude is not None and app.longitude is not None:
                            lat_val = float(app.latitude)
                            lng_val = float(app.longitude)
                    except Exception:
                        pass

                # Fallback par ville (Hammamet Est etc.) sans confondre "Tunisie"
                if (lat_val is None or lng_val is None) and extra and getattr(extra, 'city', None):
                    import re, unicodedata
                    def normalize(s: str) -> str:
                        return ''.join(c for c in unicodedata.normalize('NFD', s) if unicodedata.category(c) != 'Mn').lower()
                    city_map = [
                        ('hammamet', (36.4008, 10.6149)),
                        ('nabeul', (36.4515, 10.7353)),
                        ('tunis', (36.8065, 10.1815)),
                        ('sousse', (35.8256, 10.6360)),
                        ('sfax', (34.7406, 10.7603)),
                        ('bizerte', (37.2746, 9.8739)),
                        ('gabes', (33.8815, 10.0982)),
                        ('gafsa', (34.4250, 8.7842)),
                        ('kairouan', (35.6781, 10.0963)),
                        ('monastir', (35.7770, 10.8262)),
                        ('medenine', (33.3547, 10.5055)),
                        ('tozeur', (33.9197, 8.1335)),
                    ]
                    city_norm = normalize(str(extra.city or ''))
                    tokens = set(filter(None, re.split(r'[^a-z]+', city_norm)))
                    for key, coords in city_map:
                        if key in tokens:
                            lat_val, lng_val = coords
                            break
                if lat_val is None or lng_val is None:
                    skipped_no_coords += 1

                # Distance si possible
                distance = None
                try:
                    if lat_val is not None and lng_val is not None:
                        center_lat = float(request.GET.get('center_lat', 36.4515))
                        center_lng = float(request.GET.get('center_lng', 10.7353))
                        distance = calculate_distance(center_lat, center_lng, lat_val, lng_val)
                except Exception:
                    distance = None

                # Nom affiché
                name = pro.business_name
                if not name:
                    first_name = pro.user.first_name or ""
                    last_name = pro.user.last_name or ""
                    name = f"{first_name} {last_name}".strip() or "Professionnel"

                # Adresse
                address_parts = []
                if extra and extra.address:
                    address_parts.append(extra.address)
                if extra and extra.city:
                    address_parts.append(extra.city)
                full_address = ", ".join(address_parts) if address_parts else "Adresse non disponible"

                # Photo
                profile_photo_url = None
                try:
                    if extra and getattr(extra, 'profile_photo', None):
                        profile_photo_url = extra.profile_photo.url
                except Exception:
                    profile_photo_url = None

                # Services
                services_list = []
                if extra and extra.services:
                    if isinstance(extra.services, list):
                        services_list = extra.services
                    elif isinstance(extra.services, str):
                        services_list = [s.strip() for s in extra.services.split(',') if s.strip()]
                    elif isinstance(extra.services, dict):
                        services_list = list(extra.services.values())

                # Langues
                languages_list = []
                if extra and extra.spoken_languages:
                    if isinstance(extra.spoken_languages, list):
                        languages_list = extra.spoken_languages
                    elif isinstance(extra.spoken_languages, str):
                        languages_list = [l.strip() for l in extra.spoken_languages.split(',') if l.strip()]

                # Préparer valeurs sécurisées (évite erreurs lorsque extra est None)
                rating_val = round(float(extra.rating), 1) if (extra and extra.rating) else 4.0
                price_val = int(extra.price) if (extra and extra.price) else 50
                price_range_val = f"{price_val} - {int(price_val * 1.5)} DT"

                result = {
                    'id': pro.id,
                    'name': name,
                    'service': (extra.primary_service if (extra and getattr(extra, 'primary_service', None)) else 'Service'),
                    'services': services_list,
                    'rating': rating_val,
                    'reviews': int(extra.reviews) if (extra and extra.reviews) else 0,
                    'price': price_val,
                    'price_range': price_range_val,
                    'lat': lat_val,
                    'lng': lng_val,
                    'distanceKm': round(distance, 1) if distance is not None else None,
                    'phone': (extra.phone_number if (extra and extra.phone_number) else ''),
                    'email': pro.user.email,
                    'address': full_address,
                    'city': (extra.city if (extra and extra.city) else ''),
                    'profile_photo': profile_photo_url,
                    'bio': (extra.bio if (extra and extra.bio) else ''),
                    'spoken_languages': languages_list,
                    'working_days': (extra.working_days if (extra and extra.working_days) else []),
                    'working_hours': (extra.working_hours if (extra and extra.working_hours) else {'start': '09:00', 'end': '18:00'}),
                    'social_instagram': (extra.social_instagram if (extra and extra.social_instagram) else ''),
                    'social_facebook': (extra.social_facebook if (extra and extra.social_facebook) else ''),
                    'social_tiktok': (extra.social_tiktok if (extra and extra.social_tiktok) else ''),
                    'gallery': (extra.gallery if (extra and extra.gallery) else []),
                    'is_verified': pro.is_verified,
                    'created_at': pro.created_at.isoformat() if pro.created_at else None
                }

                results.append(result)
                print(f"✅ Professionnel ajouté: {name} - {result['service']} - {result['distanceKm']}km")

            except Exception as e:
                print(f"❌ Erreur traitement professionnel {pro.id}: {e}")
                continue

        print(f"📈 Résultats: {len(results)} professionnels inclus, {skipped_no_coords} sans coordonnées, {skipped_no_extra} sans extra")

        # Tri: distance d'abord si présente, sinon en fin
        results.sort(key=lambda x: (x['distanceKm'] is None, x['distanceKm'] if x['distanceKm'] is not None else 1e9))

        return Response({
            'results': results,
            'count': len(results),
            'debug': {
                'total_professionals': professionals.count(),
                'with_coordinates': sum(1 for r in results if r.get('lat') and r.get('lng')),
                'without_coordinates': skipped_no_coords,
                'without_extra': skipped_no_extra,
            }
        })
        
    except Exception as e:
        print(f"❌ Erreur API simple_professionals_api: {e}")
        import traceback
        traceback.print_exc()
        return Response({
            'error': str(e), 
            'results': [], 
            'count': 0,
            'debug': {'error_details': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

