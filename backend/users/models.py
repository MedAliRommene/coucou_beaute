from django.db import models
from django.contrib.auth.models import AbstractUser


class User(AbstractUser):
    """Utilisateur principal du système.

    - Étend le modèle utilisateur Django pour permettre l'unicité de l'email.
    - Conserve le champ username par défaut pour compatibilité avec AuthenticationForm.
    """

    email = models.EmailField("email address", unique=True)

    def __str__(self) -> str:
        full_name = self.get_full_name()
        return full_name or self.username or self.email


class Client(models.Model):
    """Profil client lié à un utilisateur."""

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="client_profile")
    phone_number = models.CharField(max_length=32, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self) -> str:
        return f"Client: {self.user.username}"


class Professional(models.Model):
    """Profil professionnel lié à un utilisateur."""

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="professional_profile")
    business_name = models.CharField(max_length=255, blank=True)
    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self) -> str:
        return f"Pro: {self.user.username}"
