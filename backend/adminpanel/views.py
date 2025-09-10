# Vues pour l'app adminpanel
# Interface d'administration moderne

from django.shortcuts import redirect, render
from django.contrib.auth.forms import AuthenticationForm
from django.contrib.auth import login, logout
from django.contrib.auth.decorators import login_required
from django.http import HttpRequest, HttpResponse
from django.contrib import messages
from django.contrib.auth import get_user_model
from users.models import Professional, ProfessionalProfileExtra, Client
from users.models import ProfessionalApplication
from users.serializers import ProfessionalApplicationSerializer
from django.views.decorators.http import require_POST
from django.http import JsonResponse
import json

def entry_point(request: HttpRequest) -> HttpResponse:
    if request.user.is_authenticated:
        return redirect('adminpanel:dashboard')
    return redirect('adminpanel:login')

def login_view(request: HttpRequest) -> HttpResponse:
    next_url = request.GET.get('next') or request.POST.get('next') or ''
    if request.method == 'POST':
        # Permettre la connexion via email ou username en adaptant les données POST pour AuthenticationForm
        post_data = request.POST.copy()
        identifier = post_data.get('username', '')
        if '@' in identifier:
            User = get_user_model()
            try:
                user_obj = User.objects.get(email=identifier)
                post_data['username'] = user_obj.username
            except User.DoesNotExist:
                pass

        form = AuthenticationForm(request, data=post_data)
        if form.is_valid():
            user = form.get_user()
            login(request, user)
            return redirect(next_url or 'adminpanel:dashboard')
        messages.error(request, "Identifiants invalides. Vérifiez votre email/nom d'utilisateur et mot de passe.")
    else:
        form = AuthenticationForm()
    return render(request, 'adminpanel/login.html', {'form': form, 'next': next_url})

def logout_view(request: HttpRequest) -> HttpResponse:
    logout(request)
    return redirect('adminpanel:login')

@login_required
def dashboard_view(request: HttpRequest) -> HttpResponse:
    return render(request, 'adminpanel/dashboard.html')

@login_required
def clients_view(request: HttpRequest) -> HttpResponse:
    # Basic listing of clients with quick KPIs
    clients_qs = Client.objects.select_related('user').order_by('-created_at')
    total_clients = clients_qs.count()
    from django.utils.timezone import now
    today = now().date()
    new_today = clients_qs.filter(created_at__date=today).count()
    month_start = today.replace(day=1)
    new_month = clients_qs.filter(created_at__date__gte=month_start).count()
    clients = [
        {
            'id': c.id,
            'email': c.user.email,
            'name': (c.user.get_full_name() or c.user.username or c.user.email),
            'phone': getattr(c, 'phone_number', ''),
            'address': getattr(c, 'address', ''),
            'city': getattr(c, 'city', ''),
            'created_at': c.created_at,
        }
        for c in clients_qs[:500]
    ]
    cities = sorted({cl['city'] for cl in clients if cl['city']})
    context = {
        'kpis': {
            'total': total_clients,
            'new_today': new_today,
            'new_month': new_month,
        },
        'clients': clients,
        'cities': cities,
    }
    return render(request, 'adminpanel/clients.html', context)

@login_required
def pros_view(request: HttpRequest) -> HttpResponse:
    return render(request, 'adminpanel/pros.html')

@login_required
def pros_pending_view(request: HttpRequest) -> HttpResponse:
    return render(request, 'adminpanel/pros_pending.html')

@login_required
def pro_application_detail_view(request: HttpRequest, app_id: int) -> HttpResponse:
    app = ProfessionalApplication.objects.filter(id=app_id).first()
    if not app:
        messages.error(request, "Demande introuvable")
        return redirect('adminpanel:pros_pending')
    data = ProfessionalApplicationSerializer(app).data
    return render(request, 'adminpanel/pro_application_detail.html', { 'app': data })

@login_required
def pro_detail_view(request: HttpRequest, pro_id: int) -> HttpResponse:
    try:
        pro = Professional.objects.select_related('user').get(id=pro_id)
    except Professional.DoesNotExist:
        messages.error(request, "Professionnel introuvable")
        return redirect('adminpanel:pros')
    extra_data = None
    try:
        extra = pro.extra  # ProfessionalProfileExtra
        extra_data = {
            'bio': extra.bio,
            'city': extra.city,
            'social_instagram': extra.social_instagram,
            'social_facebook': extra.social_facebook,
            'social_tiktok': extra.social_tiktok,
            'services': extra.services,
            'working_days': extra.working_days,
            'working_hours': extra.working_hours,
            'gallery': extra.gallery,
            'updated_at': extra.updated_at,
        }
    except ProfessionalProfileExtra.DoesNotExist:
        pass

    context = {
        'pro': {
            'id': pro.id,
            'email': pro.user.email,
            'phone': getattr(pro.user, 'phone', '') or '—',
            'business_name': pro.business_name,
            'is_verified': pro.is_verified,
            'created_at': pro.created_at,
            'address': extra_data['city'] if extra_data else '',
            'extra': extra_data,
        }
    }
    return render(request, 'adminpanel/pro_detail.html', context)

@login_required
def appointments_view(request: HttpRequest) -> HttpResponse:
    return render(request, 'adminpanel/appointments.html')

@login_required
def reviews_view(request: HttpRequest) -> HttpResponse:
    return render(request, 'adminpanel/reviews.html')

@login_required
def subscriptions_view(request: HttpRequest) -> HttpResponse:
    return render(request, 'adminpanel/subscriptions.html')

@login_required
def notifications_view(request: HttpRequest) -> HttpResponse:
    return render(request, 'adminpanel/notifications.html')

@login_required
def stats_view(request: HttpRequest) -> HttpResponse:
    return render(request, 'adminpanel/stats.html')

@login_required
def settings_view(request: HttpRequest) -> HttpResponse:
    return render(request, 'adminpanel/settings.html')


@login_required
@require_POST
def api_save_pro_extras(request: HttpRequest, pro_id: int):
    try:
        pro = Professional.objects.get(id=pro_id)
    except Professional.DoesNotExist:
        return JsonResponse({"ok": False, "error": "Professionnel introuvable"}, status=404)
    try:
        payload = json.loads(request.body.decode('utf-8') or '{}')
    except json.JSONDecodeError:
        payload = {}
    extra, _ = ProfessionalProfileExtra.objects.get_or_create(professional=pro)
    if 'bio' in payload:
        extra.bio = payload.get('bio') or ''
    if 'city' in payload:
        extra.city = payload.get('city') or ''
    if 'social_instagram' in payload:
        extra.social_instagram = payload.get('social_instagram') or ''
    if 'social_facebook' in payload:
        extra.social_facebook = payload.get('social_facebook') or ''
    if 'social_tiktok' in payload:
        extra.social_tiktok = payload.get('social_tiktok') or ''
    if 'services' in payload:
        extra.services = payload.get('services') or []
    if 'working_days' in payload:
        extra.working_days = payload.get('working_days') or []
    if 'working_hours' in payload:
        extra.working_hours = payload.get('working_hours') or {}
    if 'gallery' in payload:
        extra.gallery = payload.get('gallery') or []
    extra.save()
    return JsonResponse({"ok": True, "updated_at": extra.updated_at.isoformat()})
