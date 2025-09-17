# Modèles pour l'app reviews
# Système d'avis et évaluations

from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone

User = get_user_model()

class Review(models.Model):
    """Modèle pour les avis des clients sur les professionnels"""
    
    RATING_CHOICES = [
        (1, '1 étoile'),
        (2, '2 étoiles'),
        (3, '3 étoiles'),
        (4, '4 étoiles'),
        (5, '5 étoiles'),
    ]
    
    # Relations
    client = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='reviews_given',
        verbose_name="Client"
    )
    professional = models.ForeignKey(
        'users.Professional',
        on_delete=models.CASCADE,
        related_name='reviews_received',
        verbose_name="Professionnel"
    )
    
    # Contenu de l'avis
    rating = models.PositiveIntegerField(
        choices=RATING_CHOICES,
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        verbose_name="Note"
    )
    comment = models.TextField(
        max_length=1000,
        blank=True,
        null=True,
        verbose_name="Commentaire"
    )
    
    # Métadonnées
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Date de création")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Date de modification")
    is_verified = models.BooleanField(default=False, verbose_name="Avis vérifié")
    is_public = models.BooleanField(default=True, verbose_name="Public")
    
    class Meta:
        verbose_name = "Avis"
        verbose_name_plural = "Avis"
        unique_together = ['client', 'professional']  # Un client ne peut donner qu'un avis par professionnel
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Avis de {self.client.get_full_name()} sur {self.professional.business_name} - {self.rating} étoiles"
    
    @property
    def stars_display(self):
        """Retourne une chaîne d'étoiles pour l'affichage"""
        return "★" * self.rating + "☆" * (5 - self.rating)
    
    @property
    def client_name(self):
        """Retourne le nom du client"""
        return self.client.get_full_name() or self.client.username
    
    @property
    def professional_name(self):
        """Retourne le nom du professionnel"""
        return self.professional.business_name or f"{self.professional.user.first_name} {self.professional.user.last_name}".strip()

class ReviewImage(models.Model):
    """Images associées aux avis"""
    
    review = models.ForeignKey(
        Review,
        on_delete=models.CASCADE,
        related_name='images',
        verbose_name="Avis"
    )
    image = models.ImageField(
        upload_to='reviews/images/%Y/%m/%d/',
        verbose_name="Image"
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Date de création")
    
    class Meta:
        verbose_name = "Image d'avis"
        verbose_name_plural = "Images d'avis"
    
    def __str__(self):
        return f"Image pour l'avis {self.review.id}"
