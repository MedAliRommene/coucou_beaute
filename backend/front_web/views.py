from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from django.views.decorators.http import require_http_methods, require_POST
from django.contrib import messages
from django.contrib.auth import authenticate, login, logout
from django.http import HttpRequest, HttpResponse
from users.models import Professional
from django.contrib.auth import get_user_model
from users.models import Client as ClientProfile, ProfessionalApplication, ProfessionalApplicationAction
from users.models import ProfessionalProfileExtra
import json
import re
from django.core.cache import cache
from users.serializers import ProfessionalApplicationSerializer


def landing(request: HttpRequest) -> HttpResponse:
    return render(request, 'front_web/landing.html')


@require_http_methods(["GET", "POST"])
def login_view(request: HttpRequest) -> HttpResponse:
    if request.method == 'POST':
        identifier = (request.POST.get('email') or '').strip()
        password = request.POST.get('password') or ''
        role = request.POST.get('role') or 'client'
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
            login(request, user)
            # Admin -> dashboard
            if user.is_staff or user.is_superuser:
                return redirect('/dashboard/')
            # Professional role
            try:
                pro = getattr(user, 'professional_profile', None)
                if pro:
                    # If no extra profile completed yet, redirect to onboarding first
                    try:
                        _ = pro.extra  # will raise if not exists
                    except ProfessionalProfileExtra.DoesNotExist:
                        return redirect('front_web:pro_onboarding')
                    return redirect('front_web:pro_dashboard')
            except Exception:
                pass
            # Default to client dashboard
            return redirect('front_web:client_dashboard')
        messages.error(request, "Identifiants invalides")
    return render(request, 'front_web/login.html')


@require_http_methods(["GET", "POST"])
def signup_view(request: HttpRequest) -> HttpResponse:
    if request.method == 'POST':
        email = (request.POST.get('email') or '').strip().lower()
        password = request.POST.get('password') or ''
        first_name = request.POST.get('first_name') or ''
        last_name = request.POST.get('last_name') or ''
        role = (request.POST.get('role') or 'client').strip()
        if not email or not password:
            messages.error(request, "Email et mot de passe requis")
        else:
            UserModel = get_user_model()
            # Flow CLIENT: créer directement l'utilisateur + profil et rediriger vers dashboard client
            if role == 'client':
                if UserModel.objects.filter(username__iexact=email).exists() or UserModel.objects.filter(email__iexact=email).exists():
                    messages.error(request, "Un compte existe déjà avec cet email")
                else:
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
                    ClientProfile.objects.create(user=u, phone_number=phone, address=address, city=city)
                    login(request, u)
                    return redirect('front_web:client_dashboard')
            # Flow PROFESSIONNEL: créer une demande (application) et ne pas activer l'utilisateur tant que non approuvé
            else:
                phone = request.POST.get('phone') or ''
                category = request.POST.get('activity_category') or 'other'
                service_type = request.POST.get('service_type') or 'mobile'
                address = request.POST.get('address') or ''
                lat = request.POST.get('latitude') or None
                lng = request.POST.get('longitude') or None
                salon_name = request.POST.get('salon_name') or ''
                spoken_languages = request.POST.getlist('spoken_languages') or ['french']
                subscription_active = bool(request.POST.get('subscription_active'))
                # Newly added: uploaded asset URLs
                profile_photo = request.POST.get('profile_photo') or ''
                id_document = request.POST.get('id_document') or ''
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
                    'profile_photo': profile_photo,
                    'id_document': id_document,
                }
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
    return render(request, 'front_web/client_dashboard.html')


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
        # Pass full pro object for template parity with admin view
        return render(request, 'front_web/pro_dashboard.html', { 'pro': pro, 'pro_id': pro.id })
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
                'bio': e.bio,
                'city': e.city,
                'social_instagram': e.social_instagram,
                'social_facebook': e.social_facebook,
                'social_tiktok': e.social_tiktok,
                'services': e.services,
                'working_days': e.working_days,
                'working_hours': e.working_hours,
                'gallery': e.gallery,
            }
        except ProfessionalProfileExtra.DoesNotExist:
            extra_hint = None
        # Inclure business_name pour préremplir le nom du centre
        if extra_hint is None:
            extra_hint = {}
        extra_hint['business_name'] = getattr(pro, 'business_name', '')
    except Exception:
        pass
    try:
        app = ProfessionalApplication.objects.filter(email__iexact=request.user.email, is_approved=True).order_by('-created_at').first() or \
              ProfessionalApplication.objects.filter(email__iexact=request.user.email).order_by('-created_at').first()
        if app:
            app_hint = {
                'first_name': app.first_name,
                'last_name': app.last_name,
                'activity_category': app.activity_category,
                'service_type': app.service_type,
                'address': app.address,
                'latitude': app.latitude,
                'longitude': app.longitude,
                'email': app.email,
                'phone_number': app.phone_number,
                'salon_name': app.salon_name,
                'profile_photo': app.profile_photo,
                'id_document': app.id_document,
                'created_at': app.created_at.isoformat() if getattr(app, 'created_at', None) else None,
            }
    except Exception:
        app_hint = None
    prefill = { 'application_hint': app_hint, 'extra': extra_hint }
    return render(request, 'front_web/pro_onboarding.html', { 'prefill': json.dumps(prefill) })


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

