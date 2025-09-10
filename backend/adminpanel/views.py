# Vues pour l'app adminpanel
# Interface d'administration moderne

from django.shortcuts import redirect, render
from django.contrib.auth.forms import AuthenticationForm
from django.contrib.auth import login, logout
from django.contrib.auth.decorators import login_required
from django.http import HttpRequest, HttpResponse
from django.contrib import messages
from django.contrib.auth import get_user_model
from users.models import Professional
from users.models import ProfessionalApplication
from users.serializers import ProfessionalApplicationSerializer

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
    return render(request, 'adminpanel/clients.html')

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
    context = {
        'pro': {
            'id': pro.id,
            'email': pro.user.email,
            'business_name': pro.business_name,
            'is_verified': pro.is_verified,
            'created_at': pro.created_at,
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
