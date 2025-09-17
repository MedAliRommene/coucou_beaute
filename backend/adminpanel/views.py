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
from reviews.models import Review
from django.views.decorators.http import require_POST
from django.http import JsonResponse
from django.db.models import Q, Avg
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
    """Sélection du centre pour la gestion des avis"""
    # Récupérer tous les centres professionnels avec leurs statistiques
    professionals = Professional.objects.select_related('user', 'extra').prefetch_related('reviews_received').all()
    
    # Ajouter les statistiques pour chaque centre
    centers_data = []
    for pro in professionals:
        reviews = pro.reviews_received.all()
        total_reviews = reviews.count()
        avg_rating = reviews.aggregate(avg=Avg('rating'))['avg'] or 0
        verified_reviews = reviews.filter(is_verified=True).count()
        
        centers_data.append({
            'professional': pro,
            'total_reviews': total_reviews,
            'avg_rating': round(avg_rating, 1),
            'verified_reviews': verified_reviews,
            'business_name': pro.business_name or f"{pro.user.first_name} {pro.user.last_name}".strip(),
            'city': pro.extra.city if hasattr(pro, 'extra') and pro.extra.city else 'Non spécifié',
            'is_verified': pro.is_verified
        })
    
    # Trier par nombre d'avis décroissant
    centers_data.sort(key=lambda x: x['total_reviews'], reverse=True)
    
    context = {
        'centers': centers_data,
        'total_centers': len(centers_data),
        'total_reviews_all': sum(center['total_reviews'] for center in centers_data)
    }
    
    return render(request, 'adminpanel/center_selection.html', context)

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


@login_required
def reviews_management(request: HttpRequest, center_id: int) -> HttpResponse:
    """Gestion des avis pour un centre spécifique"""
    try:
        # Récupérer le centre professionnel
        professional = Professional.objects.select_related('user', 'extra').get(id=center_id)
    except Professional.DoesNotExist:
        messages.error(request, 'Centre professionnel introuvable.')
        return redirect('adminpanel:reviews')
    
    # Récupérer les paramètres de filtrage
    search_query = request.GET.get('search', '').strip()
    rating_filter = request.GET.get('rating', '')
    status_filter = request.GET.get('status', '')
    sort_by = request.GET.get('sort', 'newest')
    
    # Construire la requête de base pour ce centre uniquement
    reviews = Review.objects.filter(professional=professional).select_related('client').order_by('-created_at')
    
    # Appliquer les filtres
    if search_query:
        reviews = reviews.filter(
            Q(comment__icontains=search_query) |
            Q(client__first_name__icontains=search_query) |
            Q(client__last_name__icontains=search_query)
        )
    
    if rating_filter:
        reviews = reviews.filter(rating=int(rating_filter))
    
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
    from django.core.paginator import Paginator
    paginator = Paginator(reviews, 15)  # 15 avis par page
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)
    
    # Statistiques pour ce centre
    total_reviews = reviews.count()
    verified_reviews = reviews.filter(is_verified=True).count()
    public_reviews = reviews.filter(is_public=True).count()
    avg_rating = reviews.aggregate(avg_rating=Avg('rating'))['avg_rating'] or 0
    
    # Distribution des notes
    rating_distribution = {}
    for i in range(1, 6):
        count = reviews.filter(rating=i).count()
        percentage = (count * 100 / total_reviews) if total_reviews > 0 else 0
        rating_distribution[i] = {
            'count': count,
            'percentage': round(percentage, 1)
        }
    
    context = {
        'professional': professional,
        'page_obj': page_obj,
        'reviews': page_obj.object_list,
        'search_query': search_query,
        'rating_filter': rating_filter,
        'status_filter': status_filter,
        'sort_by': sort_by,
        'statistics': {
            'total_reviews': total_reviews,
            'verified_reviews': verified_reviews,
            'public_reviews': public_reviews,
            'avg_rating': round(avg_rating, 1),
            'rating_distribution': rating_distribution,
        },
        'rating_choices': [(i, f'{i} étoile{"s" if i > 1 else ""}') for i in range(1, 6)],
        'status_choices': [
            ('', 'Tous les statuts'),
            ('verified', 'Vérifiés'),
            ('unverified', 'Non vérifiés'),
            ('public', 'Publics'),
            ('private', 'Privés'),
        ],
        'sort_choices': [
            ('newest', 'Plus récents'),
            ('oldest', 'Plus anciens'),
            ('rating_high', 'Note élevée'),
            ('rating_low', 'Note faible'),
        ]
    }
    
    return render(request, 'adminpanel/reviews.html', context)


@login_required
@require_POST
def delete_review(request: HttpRequest, review_id: int) -> HttpResponse:
    """Supprimer un avis"""
    try:
        review = Review.objects.get(id=review_id)
        professional_name = review.professional.business_name or f"{review.professional.user.first_name} {review.professional.user.last_name}".strip()
        client_name = review.client.get_full_name() or review.client.username
        
        # Supprimer l'avis
        review.delete()
        
        # Mettre à jour les statistiques du professionnel
        from reviews.views import update_professional_rating
        update_professional_rating(review.professional)
        
        if request.headers.get('Accept') == 'application/json':
            return JsonResponse({
                'success': True,
                'message': f'Avis de {client_name} sur {professional_name} supprimé avec succès'
            })
        else:
            messages.success(request, f'Avis de {client_name} sur {professional_name} supprimé avec succès')
            return redirect('adminpanel:reviews')
            
    except Review.DoesNotExist:
        if request.headers.get('Accept') == 'application/json':
            return JsonResponse({
                'success': False,
                'message': 'Avis non trouvé'
            }, status=404)
        else:
            messages.error(request, 'Avis non trouvé')
            return redirect('adminpanel:reviews')
    except Exception as e:
        if request.headers.get('Accept') == 'application/json':
            return JsonResponse({
                'success': False,
                'message': f'Erreur lors de la suppression: {str(e)}'
            }, status=500)
        else:
            messages.error(request, f'Erreur lors de la suppression: {str(e)}')
            return redirect('adminpanel:reviews')


@login_required
@require_POST
def toggle_review_status(request: HttpRequest, review_id: int) -> HttpResponse:
    """Basculer le statut de vérification d'un avis"""
    try:
        review = Review.objects.get(id=review_id)
        review.is_verified = not review.is_verified
        review.save()
        
        status_text = "vérifié" if review.is_verified else "non vérifié"
        
        if request.headers.get('Accept') == 'application/json':
            return JsonResponse({
                'success': True,
                'message': f'Avis marqué comme {status_text}',
                'is_verified': review.is_verified
            })
        else:
            messages.success(request, f'Avis marqué comme {status_text}')
            return redirect('adminpanel:reviews')
            
    except Review.DoesNotExist:
        if request.headers.get('Accept') == 'application/json':
            return JsonResponse({
                'success': False,
                'message': 'Avis non trouvé'
            }, status=404)
        else:
            messages.error(request, 'Avis non trouvé')
            return redirect('adminpanel:reviews')
    except Exception as e:
        if request.headers.get('Accept') == 'application/json':
            return JsonResponse({
                'success': False,
                'message': f'Erreur lors de la modification: {str(e)}'
            }, status=500)
        else:
            messages.error(request, f'Erreur lors de la modification: {str(e)}')
            return redirect('adminpanel:reviews')
