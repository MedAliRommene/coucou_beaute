# Vues pour l'app users
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.permissions import AllowAny, IsAdminUser
from rest_framework.response import Response
from rest_framework.authentication import SessionAuthentication
from django.utils import timezone
from django.core.mail import send_mail
from django.conf import settings
from django.core.files.storage import default_storage
from django.utils.timezone import now
from datetime import timedelta
from django.db.models import Q
from django.http import HttpResponse
import csv
import threading
from typing import Optional
from rest_framework_simplejwt.tokens import RefreshToken

from .models import ProfessionalApplication, Professional, User, ProfessionalApplicationAction, ProfessionalProfileExtra
from .serializers import ProfessionalApplicationSerializer, ProfessionalListItemSerializer


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
                # Créer avec champs supplémentaires (ex: phone) si nécessaire
                phone_fallback = getattr(app, 'phone_number', None) or '00000000'
                # Include optional fields like phone, role, language with sensible defaults
                extra_fields = {}
                if hasattr(User, 'phone'):
                    extra_fields["phone"] = phone_fallback
                if hasattr(User, 'role'):
                    extra_fields["role"] = "professional"
                if hasattr(User, 'language'):
                    extra_fields["language"] = "fr"
                user = User.objects.create_user(username=username, email=app.email, password=raw_password, **extra_fields)
                # Remplir prénom/nom
                user.first_name = getattr(app, 'first_name', '')
                user.last_name = getattr(app, 'last_name', '')
                # Par défaut, compte inactif tant que l'admin n'approuve pas
                user.is_active = False
                try:
                    user.save()
                except Exception:
                    user.save()

        ProfessionalApplicationAction.objects.create(
            application=app, action="submitted", actor=None, notes="Soumission via mobile"
        )
        return Response(ProfessionalApplicationSerializer(app).data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(["GET"]) 
@permission_classes([IsAdminUser])
@authentication_classes([SessionAuthentication])
def pending_professional_applications(request):
    qs = ProfessionalApplication.objects.filter(is_processed=False).order_by("-created_at")
    data = ProfessionalApplicationSerializer(qs, many=True).data
    return Response(data)


@api_view(["POST"]) 
@permission_classes([IsAdminUser])
@authentication_classes([SessionAuthentication])
def approve_professional_application(request, app_id: int):
    try:
        app = ProfessionalApplication.objects.get(id=app_id)
    except ProfessionalApplication.DoesNotExist:
        return Response({"detail": "Demande introuvable"}, status=status.HTTP_404_NOT_FOUND)

    if app.is_processed:
        return Response({"detail": "Déjà traitée"}, status=status.HTTP_400_BAD_REQUEST)

    # Marquer traitée/approuvée
    app.is_processed = True
    app.is_approved = True
    app.processed_at = timezone.now()
    app.processed_by = request.user
    app.save(update_fields=["is_processed", "is_approved", "processed_at", "processed_by"])

    ProfessionalApplicationAction.objects.create(
        application=app, action="approved", actor=request.user, notes=request.data.get("notes", "")
    )

    # Créer (ou récupérer) l'utilisateur à partir de l'email, puis le Professional vérifié
    try:
        user = User.objects.get(email=app.email)
    except User.DoesNotExist:
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
        user = User.objects.create_user(username=username, email=app.email, password=User.objects.make_random_password(), **extra_fields)
        # Remplir prénom/nom
        user.first_name = app.first_name
        user.last_name = app.last_name
        # Par défaut, compte inactif tant que l’admin n’a pas approuvé — on va l’activer plus bas
        user.is_active = False
        # Si le modèle User possède un champ phone NOT NULL, le renseigner
        try:
            if hasattr(user, 'phone') and (getattr(user, 'phone') is None or getattr(user, 'phone') == ''):
                setattr(user, 'phone', (getattr(app, 'phone_number', None) or '00000000'))
        except Exception:
            pass
        user.save()

    # Activer le compte à l'approbation
    if not user.is_active:
        user.is_active = True
        try:
            user.save(update_fields=["is_active"])
        except Exception:
            user.save()

    pro, created = Professional.objects.get_or_create(user=user)
    # Mettre à jour le nom du centre si disponible
    center_name = app.salon_name or getattr(app, 'business_name', '') or ''
    updates = []
    if center_name and pro.business_name != center_name:
        pro.business_name = center_name
        updates.append("business_name")
    if not pro.is_verified:
        pro.is_verified = True
        updates.append("is_verified")
    if updates:
        pro.save(update_fields=updates)

    # Créer ou mettre à jour le ProfessionalProfileExtra avec les données de l'application
    extra, extra_created = ProfessionalProfileExtra.objects.get_or_create(professional=pro)
    
    # Transférer TOUTES les données de l'application vers le profil extra
    # Forcer la mise à jour même si les champs sont vides
    
    if app.address:
        extra.address = app.address
    if app.latitude is not None:
        extra.latitude = app.latitude
    if app.longitude is not None:
        extra.longitude = app.longitude
    if app.phone_number:
        extra.phone_number = app.phone_number
    if app.activity_category:
        extra.primary_service = app.activity_category
    if app.spoken_languages:
        if isinstance(app.spoken_languages, list):
            extra.spoken_languages = ','.join(app.spoken_languages)
        else:
            extra.spoken_languages = str(app.spoken_languages)
    
    # Transférer la photo de profil
    if app.profile_photo:
        extra.profile_photo = app.profile_photo
    
    # Si les coordonnées sont manquantes mais qu'on a une adresse, essayer de géocoder
    if (extra.latitude is None or extra.longitude is None) and extra.address:
        try:
            import requests
            url = "https://nominatim.openstreetmap.org/search"
            params = {
                'q': extra.address,
                'format': 'json',
                'limit': 1,
                'countrycodes': 'tn',
                'addressdetails': 1
            }
            headers = {'User-Agent': 'CoucouBeaute/1.0'}
            response = requests.get(url, params=params, headers=headers, timeout=5)
            
            if response.status_code == 200:
                data = response.json()
                if data:
                    result = data[0]
                    extra.latitude = float(result['lat'])
                    extra.longitude = float(result['lon'])
                    print(f"✅ Coordonnées géocodées pour {app.email}: {extra.latitude}, {extra.longitude}")
        except Exception as e:
            print(f"⚠️  Erreur géocodage pour {app.email}: {e}")
    
    # Définir des valeurs par défaut si elles n'existent pas
    if not extra.rating:
        extra.rating = 4.0
    if not extra.reviews:
        extra.reviews = 0
    if not extra.price:
        extra.price = 50.0
    if not extra.services:
        extra.services = []
    if not extra.working_days:
        extra.working_days = []
    if not extra.working_hours:
        extra.working_hours = {'start': '09:00', 'end': '18:00'}
    
    extra.save()

    # Réponse rapide avec pro_id pour redirection immédiate
    payload = {"detail": "Demande approuvée", "pro_id": pro.id}

    # Envoyer l'email en tâche non bloquante (thread léger)
    def _send_approve_email():
        try:
            subject = "Votre profil Coucou Beauté est activé"
            plain = (
                "Bonjour {first_name},\n\n"
                "Bonne nouvelle : votre demande a été approuvée et votre profil professionnel est désormais actif.\n\n"
                "Étapes suivantes :\n"
                "1) Connectez-vous avec votre e-mail pour accéder à votre espace.\n"
                "2) Complétez votre profil (photo, services, tarifs, disponibilités).\n"
                "3) Activez l'abonnement si souhaité pour bénéficier de toutes les fonctionnalités.\n\n"
                "Bienvenue sur Coucou Beauté et plein de réussites !\n\n"
                "— L'équipe Coucou Beauté"
            ).format(first_name=(app.first_name or ""))

            html = f"""
                <div style=\"font-family:Inter,system-ui,-apple-system,Segoe UI,Roboto,sans-serif;line-height:1.6;color:#111827\"> 
                  <h2 style=\"margin:0 0 8px;\">Votre profil est activé 🎉</h2>
                  <p>Bonjour <strong>{app.first_name or ''}</strong>,</p>
                  <p>Votre demande a été approuvée et votre profil professionnel est désormais <strong>actif</strong> sur Coucou Beauté.</p>
                  <ol>
                    <li>Connectez-vous avec votre e-mail pour accéder à votre espace.</li>
                    <li>Complétez votre profil (photo, services, tarifs, disponibilités).</li>
                    <li>Activez l'abonnement si souhaité pour débloquer tous les avantages.</li>
                  </ol>
                  <p style=\"margin-top:16px\">Besoin d'aide ? Répondez simplement à cet e-mail.</p>
                  <p style=\"margin-top:16px;color:#6B7280\">— L'équipe Coucou Beauté</p>
                </div>
            """

            send_mail(
                subject=subject,
                message=plain,
                from_email=getattr(settings, "DEFAULT_FROM_EMAIL", "no-reply@coucou-beaute.local"),
                recipient_list=[app.email],
                fail_silently=False,  # Ne pas ignorer les erreurs pour le debugging
                html_message=html,
            )
            print(f"✅ Email d'approbation envoyé à {app.email}")  # Debug
        except Exception as e:
            print(f"❌ Erreur envoi email d'approbation: {e}")  # Debug
    
    # Lancer l'envoi d'email en arrière-plan
    email_thread = threading.Thread(target=_send_approve_email, daemon=True)
    email_thread.start()

    # Réponse avec succès et informations pour redirection
    payload = {
        "detail": "Demande approuvée avec succès", 
        "pro_id": pro.id,
        "professional_name": f"{app.first_name} {app.last_name}".strip(),
        "email": app.email,
        "success": True
    }

    return Response(payload)


@api_view(["POST"]) 
@permission_classes([IsAdminUser])
@authentication_classes([SessionAuthentication])
def fix_professionals_coordinates(request):
    """API pour corriger les coordonnées des professionnels existants"""
    try:
        # Trouver tous les profils extra sans coordonnées
        extras_without_coords = ProfessionalProfileExtra.objects.filter(
            latitude__isnull=True,
            longitude__isnull=True
        )
        
        fixed_count = 0
        
        for extra in extras_without_coords:
            # Construire l'adresse complète
            full_address = ""
            if extra.address:
                full_address = extra.address
            if extra.city and extra.city not in full_address:
                if full_address:
                    full_address += f", {extra.city}"
                else:
                    full_address = extra.city
            
            if full_address and "tunisie" not in full_address.lower():
                full_address += ", Tunisie"
            
            if full_address:
                try:
                    import requests
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
                            
                except Exception as e:
                    print(f"Erreur géocodage pour {extra.professional.business_name}: {e}")
                    continue
        
        # Vérifier le résultat final
        total_with_coords = ProfessionalProfileExtra.objects.filter(
            latitude__isnull=False,
            longitude__isnull=False
        ).count()
        
        return Response({
            'detail': f'Coordonnées corrigées pour {fixed_count} professionnels',
            'fixed_count': fixed_count,
            'total_with_coordinates': total_with_coords
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["POST"]) 
@permission_classes([IsAdminUser])
@authentication_classes([SessionAuthentication])
def reject_professional_application(request, app_id: int):
    try:
        app = ProfessionalApplication.objects.get(id=app_id)
    except ProfessionalApplication.DoesNotExist:
        return Response({"detail": "Demande introuvable"}, status=status.HTTP_404_NOT_FOUND)

    if app.is_processed:
        return Response({"detail": "Déjà traitée"}, status=status.HTTP_400_BAD_REQUEST)

    app.is_processed = True
    app.is_approved = False
    app.processed_at = timezone.now()
    app.processed_by = request.user
    app.save(update_fields=["is_processed", "is_approved", "processed_at", "processed_by"])

    ProfessionalApplicationAction.objects.create(
        application=app, action="rejected", actor=request.user, notes=request.data.get("notes", "")
    )

    # Réponse rapide
    payload = {"detail": "Demande rejetée"}

    # Email non bloquant
    import threading
    def _send_reject_email():
        try:
            send_mail(
                subject="Votre inscription professionnelle a été refusée",
                message=(
                    "Bonjour,\n\nAprès examen, votre demande a été refusée pour le moment. "
                    "Vous pouvez soumettre une nouvelle demande avec des informations à jour.\n\n"
                    "Cordialement, Coucou Beauté"
                ),
                from_email=getattr(settings, "DEFAULT_FROM_EMAIL", "no-reply@coucou-beaute.local"),
                recipient_list=[app.email],
                fail_silently=True,
            )
        except Exception:
            pass
    threading.Thread(target=_send_reject_email, daemon=True).start()

    return Response(payload)


def _ensure_synced_from_approved() -> int:
    created = 0
    approved_apps = ProfessionalApplication.objects.filter(is_processed=True, is_approved=True)
    for app in approved_apps:
        # Create or fetch user by email
        try:
            user = User.objects.get(email=app.email)
        except User.DoesNotExist:
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
            user = User.objects.create_user(username=username, email=app.email, password=User.objects.make_random_password(), **extra_fields)
            user.first_name = app.first_name
            user.last_name = app.last_name
            user.save(update_fields=["first_name", "last_name"]) 

        pro, was_created = Professional.objects.get_or_create(user=user)
        if was_created:
            created += 1
        name = app.salon_name or app.business_name if hasattr(app, 'business_name') else None
        if name and pro.business_name != name:
            pro.business_name = name
            pro.save(update_fields=["business_name"]) 
        if not pro.is_verified:
            pro.is_verified = True
            pro.save(update_fields=["is_verified"]) 
    return created


@api_view(["GET"]) 
@permission_classes([IsAdminUser])
@authentication_classes([SessionAuthentication])
def list_professionals(request):
    # Ensure Professionals are synced from approved applications so the list is never empty after approvals
    try:
        _ensure_synced_from_approved()
    except Exception:
        pass
    qs = Professional.objects.select_related("user").order_by("-created_at")
    return Response(ProfessionalListItemSerializer(qs, many=True).data)


@api_view(["POST"]) 
@permission_classes([IsAdminUser])
@authentication_classes([SessionAuthentication])
def verify_professional(request, pro_id: int):
    try:
        pro = Professional.objects.select_related("user").get(id=pro_id)
    except Professional.DoesNotExist:
        return Response({"detail": "Professionnel introuvable"}, status=status.HTTP_404_NOT_FOUND)
    pro.is_verified = True
    pro.save(update_fields=["is_verified"])
    return Response({"detail": "Professionnel vérifié"})


@api_view(["DELETE"]) 
@permission_classes([IsAdminUser])
@authentication_classes([SessionAuthentication])
def delete_professional(request, pro_id: int):
    try:
        pro = Professional.objects.get(id=pro_id)
    except Professional.DoesNotExist:
        return Response({"detail": "Professionnel introuvable"}, status=status.HTTP_404_NOT_FOUND)
    # Capture email before deletion for linkage
    email = getattr(pro.user, 'email', None)
    user_obj = pro.user
    # Delete the Professional entry
    pro.delete()
    # Optionally deactivate the underlying user to prevent re-login
    try:
        if user_obj and user_obj.is_active:
            user_obj.is_active = False
            user_obj.save(update_fields=["is_active"])
    except Exception:
        pass
    # Prevent re-création par la synchronisation: marquer la demande comme refusée
    try:
        if email:
            apps = ProfessionalApplication.objects.filter(email__iexact=email, is_processed=True, is_approved=True)
            updated = False
            for app in apps:
                app.is_approved = False
                app.save(update_fields=["is_approved"])
                try:
                    ProfessionalApplicationAction.objects.create(
                        application=app, action="rejected", actor=request.user, notes="Suppression du professionnel côté admin — application marquée refusée"
                    )
                except Exception:
                    pass
                updated = True
            # Fallback: if there is a pending application, ensure it remains processed
            if not updated:
                pass
    except Exception:
        pass
    return Response(status=status.HTTP_204_NO_CONTENT)


@api_view(["GET"]) 
@permission_classes([IsAdminUser])
@authentication_classes([SessionAuthentication])
def applications_summary(request):
    """Retourne les KPI de demandes (période 30j vs 30j précédents)."""
    now_ts = timezone.now()
    start = now_ts - timedelta(days=30)
    prev_start = start - timedelta(days=30)
    prev_end = start

    qs = ProfessionalApplication.objects
    total = qs.count()
    pending = qs.filter(is_processed=False).count()
    approved = qs.filter(is_processed=True, is_approved=True).count()
    rejected = qs.filter(is_processed=True, is_approved=False).count()

    cur_range = qs.filter(created_at__gte=start)
    prev_range = qs.filter(created_at__gte=prev_start, created_at__lt=prev_end)

    def variation(cur, prev):
        if prev == 0:
            return 100.0 if cur > 0 else 0.0
        return ((cur - prev) / prev) * 100.0

    data = {
        "period": "30d",
        "total": {"value": total, "var_pct": variation(cur_range.count(), prev_range.count())},
        "pending": {"value": pending, "var_pct": variation(
            qs.filter(is_processed=False, created_at__gte=start).count(),
            qs.filter(is_processed=False, created_at__gte=prev_start, created_at__lt=prev_end).count(),
        )},
        "approved": {"value": approved, "var_pct": variation(
            qs.filter(is_processed=True, is_approved=True, processed_at__gte=start).count(),
            qs.filter(is_processed=True, is_approved=True, processed_at__gte=prev_start, processed_at__lt=prev_end).count(),
        )},
        "rejected": {"value": rejected, "var_pct": variation(
            qs.filter(is_processed=True, is_approved=False, processed_at__gte=start).count(),
            qs.filter(is_processed=True, is_approved=False, processed_at__gte=prev_start, processed_at__lt=prev_end).count(),
        )},
    }
    return Response(data)


@api_view(["GET"]) 
@permission_classes([IsAdminUser])
@authentication_classes([SessionAuthentication])
def professionals_summary(request):
    total = Professional.objects.count()
    verified = Professional.objects.filter(is_verified=True).count()
    unverified = total - verified
    return Response({
        "total": total,
        "verified": verified,
        "unverified": unverified,
    })


@api_view(["POST"]) 
@permission_classes([IsAdminUser])
@authentication_classes([SessionAuthentication])
def sync_professionals_from_approved(request):
    created = _ensure_synced_from_approved()
    return Response({"created": created})


@api_view(["DELETE"]) 
@permission_classes([IsAdminUser])
@authentication_classes([SessionAuthentication])
def delete_application(request, app_id: int):
    try:
        app = ProfessionalApplication.objects.get(id=app_id)
    except ProfessionalApplication.DoesNotExist:
        return Response({"detail": "Demande introuvable"}, status=status.HTTP_404_NOT_FOUND)
    app.delete()
    return Response(status=status.HTTP_204_NO_CONTENT)


def _parse_date(val: str):
    try:
        return timezone.datetime.fromisoformat(val)
    except Exception:
        return None


@api_view(["GET"]) 
@permission_classes([IsAdminUser])
@authentication_classes([SessionAuthentication])
def list_applications(request):
    """Liste paginée des demandes avec filtres et export CSV.

    Query params:
      - status: pending|approved|rejected
      - q: search in name/email/phone
      - date_from, date_to: ISO8601
      - page (1-based), page_size
      - order: created_at|processed_at prefixed with - for desc
      - export=csv to download CSV
    """
    qs = ProfessionalApplication.objects.all().order_by("-created_at")

    status_param = request.GET.get("status")
    if status_param == "pending":
        qs = qs.filter(is_processed=False)
    elif status_param == "approved":
        qs = qs.filter(is_processed=True, is_approved=True)
    elif status_param == "rejected":
        qs = qs.filter(is_processed=True, is_approved=False)

    q = request.GET.get("q", "").strip()
    if q:
        qs = qs.filter(
            Q(first_name__icontains=q)
            | Q(last_name__icontains=q)
            | Q(email__icontains=q)
            | Q(phone_number__icontains=q)
        )

    df = request.GET.get("date_from")
    dt = request.GET.get("date_to")
    if df:
        dt_from = _parse_date(df)
        if dt_from:
            qs = qs.filter(created_at__gte=dt_from)
    if dt:
        dt_to = _parse_date(dt)
        if dt_to:
            qs = qs.filter(created_at__lte=dt_to)

    order = request.GET.get("order")
    if order in {"created_at", "processed_at", "-created_at", "-processed_at"}:
        qs = qs.order_by(order)

    if request.GET.get("export") == "csv":
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = 'attachment; filename="applications.csv"'
        writer = csv.writer(response)
        writer.writerow([
            "Prénom",
            "Nom",
            "Email",
            "Téléphone",
            "Catégorie",
            "Type",
            "Nom du salon",
            "Statut",
            "Créée le",
            "Traitée le",
        ])
        for a in qs[:10000]:
            status_str = "En attente"
            if a.is_processed:
                status_str = "Approuvée" if a.is_approved else "Refusée"
            writer.writerow([
                a.first_name,
                a.last_name,
                a.email,
                a.phone_number,
                a.activity_category,
                a.service_type,
                a.salon_name,
                status_str,
                a.created_at.isoformat(),
                a.processed_at.isoformat() if a.processed_at else "",
            ])
        return response

    # Pagination
    try:
        page = max(int(request.GET.get("page", 1)), 1)
    except Exception:
        page = 1
    try:
        page_size = min(max(int(request.GET.get("page_size", 10)), 1), 100)
    except Exception:
        page_size = 10
    total = qs.count()
    start = (page - 1) * page_size
    end = start + page_size
    items = qs[start:end]
    data = ProfessionalApplicationSerializer(items, many=True).data
    return Response({
        "results": data,
        "count": total,
        "page": page,
        "page_size": page_size,
    })


@api_view(["POST"]) 
@permission_classes([IsAdminUser])
@authentication_classes([SessionAuthentication])
def purge_applications(request):
    """Supprime toutes les demandes (outil d'administration pour repartir à zéro)."""
    count = ProfessionalApplication.objects.all().count()
    ProfessionalApplication.objects.all().delete()
    return Response({"deleted": count})


@api_view(["POST"]) 
@permission_classes([AllowAny])
def upload_application_file(request):
    """Upload d'un fichier de candidature (profil ou pièce d'identité).

    Reçoit multipart/form-data avec champ 'file' et optionnel 'kind'.
    Retourne le chemin et l'URL publique.
    """
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
    """Authentifie un utilisateur via email + mot de passe et retourne des JWT.

    Réponse: { access, refresh, role, user: {id, email, first_name, last_name} }
    """
    email = (request.data.get("email") or "").strip()
    password = request.data.get("password") or ""
    if not email or not password:
        return Response({"detail": "Email et mot de passe requis"}, status=status.HTTP_400_BAD_REQUEST)
    try:
        user = User.objects.get(email__iexact=email)
    except User.DoesNotExist:
        return Response({"email": ["Aucun compte avec cet e-mail"]}, status=status.HTTP_400_BAD_REQUEST)
    if not user.is_active:
        return Response({"detail": "Compte non activé. Veuillez patienter après approbation."}, status=status.HTTP_403_FORBIDDEN)
    if not user.check_password(password):
        return Response({"password": ["Mot de passe incorrect"]}, status=status.HTTP_400_BAD_REQUEST)

    refresh = RefreshToken.for_user(user)
    role = "professional" if hasattr(user, "professional_profile") else ("client" if hasattr(user, "client_profile") else "user")
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
@permission_classes([IsAdminUser])
@authentication_classes([SessionAuthentication])
def application_actions_audit(request):
    """Audit des actions sur les demandes professionnelles (exportable CSV/JSON).

    Query params:
      - status: pending|approved|rejected (statut de la demande)
      - action: submitted|viewed|approved|rejected|comment
      - q: recherche (nom, prénom, email)
      - actor: email (contient)
      - date_from, date_to: ISO-like (YYYY-MM-DD) ou ISO8601
      - export: csv|json (par défaut json paginé)
      - page, page_size (json)
    """
    qs = ProfessionalApplicationAction.objects.select_related("application", "actor").order_by("-created_at")

    # Filtres liés au statut de la demande
    status_param = request.GET.get("status")
    if status_param == "pending":
        qs = qs.filter(application__is_processed=False)
    elif status_param == "approved":
        qs = qs.filter(application__is_processed=True, application__is_approved=True)
    elif status_param == "rejected":
        qs = qs.filter(application__is_processed=True, application__is_approved=False)

    # Filtre sur type d'action
    action_param = request.GET.get("action")
    if action_param in {"submitted", "viewed", "approved", "rejected", "comment"}:
        qs = qs.filter(action=action_param)

    # Recherche globale
    q = request.GET.get("q", "").strip()
    if q:
        qs = qs.filter(
            Q(application__first_name__icontains=q)
            | Q(application__last_name__icontains=q)
            | Q(application__email__icontains=q)
        )

    # Filtre acteur
    actor = request.GET.get("actor", "").strip()
    if actor:
        qs = qs.filter(actor__email__icontains=actor)

    # Dates
    def _parse_ymd_or_iso(val: str) -> Optional[timezone.datetime]:
        if not val:
            return None
        try:
            # Try plain date
            return timezone.datetime.fromisoformat(val)
        except Exception:
            try:
                return timezone.datetime.strptime(val, "%Y-%m-%d")
            except Exception:
                return None

    df = request.GET.get("date_from") or request.GET.get("from")
    dt = request.GET.get("date_to") or request.GET.get("to")
    dt_from = _parse_ymd_or_iso(df) if df else None
    dt_to = _parse_ymd_or_iso(dt) if dt else None
    if dt_from:
        qs = qs.filter(created_at__gte=dt_from)
    if dt_to:
        qs = qs.filter(created_at__lte=dt_to)

    if request.GET.get("export") == "csv":
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = 'attachment; filename="audit_actions.csv"'
        writer = csv.writer(response)
        writer.writerow([
            "Date action",
            "Action",
            "Email professionnel",
            "Nom complet",
            "Statut demande",
            "Acteur (admin)",
            "Notes",
        ])
        for a in qs[:20000]:
            app = a.application
            status_str = "En attente"
            if app.is_processed:
                status_str = "Approuvée" if app.is_approved else "Refusée"
            full_name = f"{app.first_name} {app.last_name}".strip()
            writer.writerow([
                a.created_at.isoformat(),
                a.action,
                app.email,
                full_name,
                status_str,
                getattr(a.actor, "email", ""),
                a.notes.replace("\n", " ") if a.notes else "",
            ])
        return response

    # JSON paginé
    try:
        page = max(int(request.GET.get("page", 1)), 1)
    except Exception:
        page = 1
    try:
        page_size = min(max(int(request.GET.get("page_size", 20)), 1), 200)
    except Exception:
        page_size = 20
    total = qs.count()
    start = (page - 1) * page_size
    end = start + page_size
    items = qs[start:end]
    data = []
    for a in items:
        app = a.application
        status_str = "pending"
        if app.is_processed:
            status_str = "approved" if app.is_approved else "rejected"
        data.append({
            "id": a.id,
            "created_at": a.created_at.isoformat(),
            "action": a.action,
            "application_id": app.id,
            "email": app.email,
            "first_name": app.first_name,
            "last_name": app.last_name,
            "status": status_str,
            "actor_email": getattr(a.actor, "email", None),
            "notes": a.notes,
        })
    return Response({
        "results": data,
        "count": total,
        "page": page,
        "page_size": page_size,
    })
