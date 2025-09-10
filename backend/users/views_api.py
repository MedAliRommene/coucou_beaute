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

