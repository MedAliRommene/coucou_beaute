from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from django.conf import settings
from django.core.files.storage import default_storage
from django.utils.timezone import now
from rest_framework_simplejwt.tokens import RefreshToken

from .models import ProfessionalApplication, ProfessionalApplicationAction, User
import re
from .serializers import ProfessionalApplicationSerializer


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


