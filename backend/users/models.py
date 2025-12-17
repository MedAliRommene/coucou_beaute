from django.db import models
from django.contrib.auth.models import AbstractUser
from django.conf import settings


class User(AbstractUser):
    """Utilisateur principal du système.

    - Étend le modèle utilisateur Django pour permettre l'unicité de l'email.
    - Conserve le champ username par défaut pour compatibilité avec AuthenticationForm.
    """

    email = models.EmailField("email address", unique=True)
    phone = models.CharField(max_length=32, blank=True, default="")
    # Map to existing DB column 'role' (NOT NULL)
    role = models.CharField(max_length=32, default="professional")
    # Map to existing DB column 'language' (NOT NULL in DB)
    language = models.CharField(max_length=16, default="fr")

    def __str__(self) -> str:
        full_name = self.get_full_name()
        return full_name or self.username or self.email


class Client(models.Model):
    """Profil client lié à un utilisateur."""

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="client_profile")
    phone_number = models.CharField(max_length=32, blank=True)
    address = models.TextField(blank=True)
    city = models.CharField(max_length=128, blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
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


class ProfessionalProfileExtra(models.Model):
    """Informations complémentaires configurées lors du premier accès.

    Conserve des données non critiques pour l'approbation mais utiles côté mobile.
    """

    GENDER_CHOICES = (
        ("male", "Homme"),
        ("female", "Femme"),
    )
    
    professional = models.OneToOneField(Professional, on_delete=models.CASCADE, related_name="extra")
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES, default="female")
    bio = models.TextField(blank=True)
    city = models.CharField(max_length=128, blank=True)
    governorate = models.CharField(max_length=64, blank=True)
    address = models.TextField(blank=True)
    phone_number = models.CharField(max_length=32, blank=True)
    phone_secondary = models.CharField(max_length=32, blank=True, help_text="Téléphone secondaire")
    email = models.EmailField(blank=True, help_text="Email principal du professionnel")
    email_secondary = models.EmailField(blank=True, help_text="Email secondaire")
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    primary_service = models.CharField(max_length=50, blank=True)
    rating = models.FloatField(default=4.0)
    reviews = models.IntegerField(default=0)
    price = models.FloatField(default=50.0)
    spoken_languages = models.CharField(max_length=255, blank=True)
    social_instagram = models.CharField(max_length=255, blank=True)
    social_facebook = models.CharField(max_length=255, blank=True)
    social_tiktok = models.CharField(max_length=255, blank=True)
    services = models.JSONField(default=list, help_text="Liste d'objets {name, duration_min, price}")
    working_days = models.JSONField(default=list, help_text="Jours de travail")
    working_hours = models.JSONField(default=dict, help_text="Ex: {start:'09:00', end:'18:00'}")
    gallery = models.JSONField(default=list)
    profile_photo = models.ImageField(upload_to='professionals/', blank=True, null=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self) -> str:
        return f"Extras for {self.professional_id}"


class ProfessionalApplication(models.Model):
    """Demande d'inscription d'un professionnel en attente de validation.

    Conserve les informations nécessaires pour examen par l'administrateur.
    """

    SERVICE_TYPES = (
        ("mobile", "Je me déplace"),
        ("home", "Je reçois chez moi"),
        ("salon", "J'ai un salon"),
    )

    GENDER_CHOICES = (
        ("male", "Homme"),
        ("female", "Femme"),
    )

    ACTIVITY_CATEGORIES = (
        # Coiffure
        ("hairdressing", "Coiffure"),
        ("haircut_women", "Coupe femme"),
        ("haircut_men", "Coupe homme"),
        ("haircut_children", "Coupe enfant"),
        ("hair_coloring", "Coloration"),
        ("highlights", "Mèches & Balayage"),
        ("hair_styling", "Brushing & Coiffage"),
        ("hair_treatment", "Soins capillaires"),
        ("keratin", "Lissage & Kératine"),
        ("hair_extensions", "Extensions cheveux"),
        ("braiding", "Tresses & Nattes"),
        ("bridal_hair", "Coiffure mariée"),
        # Maquillage
        ("makeup", "Maquillage"),
        ("bridal_makeup", "Maquillage mariée"),
        ("evening_makeup", "Maquillage soirée"),
        ("natural_makeup", "Maquillage naturel"),
        ("makeup_lesson", "Cours de maquillage"),
        # Ongles
        ("manicure", "Manucure"),
        ("pedicure", "Pédicure"),
        ("nail_art", "Nail art"),
        ("gel_nails", "Pose gel"),
        ("acrylic_nails", "Pose résine"),
        ("semi_permanent", "Semi-permanent"),
        ("nail_care", "Soins des ongles"),
        # Esthétique visage
        ("esthetics", "Esthétique"),
        ("facial", "Soin du visage"),
        ("deep_cleansing", "Nettoyage de peau"),
        ("anti_aging", "Soin anti-âge"),
        ("hydration", "Soin hydratant"),
        ("acne_treatment", "Traitement acné"),
        ("microdermabrasion", "Microdermabrasion"),
        ("chemical_peel", "Peeling"),
        ("led_therapy", "Luminothérapie LED"),
        # Épilation
        ("waxing", "Épilation cire"),
        ("waxing_face", "Épilation visage"),
        ("waxing_body", "Épilation corps"),
        ("waxing_bikini", "Épilation maillot"),
        ("threading", "Épilation au fil"),
        ("laser_hair", "Épilation laser"),
        ("sugaring", "Épilation au sucre"),
        # Sourcils & Cils
        ("eyebrows", "Épilation sourcils"),
        ("eyebrow_tint", "Teinture sourcils"),
        ("eyebrow_lamination", "Brow lamination"),
        ("microblading", "Microblading"),
        ("eyelash_extensions", "Extension de cils"),
        ("eyelash_lift", "Rehaussement de cils"),
        ("eyelash_tint", "Teinture de cils"),
        # Massage & Bien-être
        ("massage", "Massage"),
        ("relaxing_massage", "Massage relaxant"),
        ("deep_tissue", "Massage deep tissue"),
        ("hot_stone", "Massage pierres chaudes"),
        ("aromatherapy", "Aromathérapie"),
        ("reflexology", "Réflexologie"),
        ("lymphatic_drainage", "Drainage lymphatique"),
        ("prenatal_massage", "Massage prénatal"),
        # Corps
        ("body_treatment", "Soin du corps"),
        ("body_scrub", "Gommage corps"),
        ("body_wrap", "Enveloppement"),
        ("slimming", "Soin minceur"),
        ("cellulite", "Traitement cellulite"),
        ("tanning", "Bronzage"),
        ("spray_tan", "Autobronzant"),
        # Spa & Hammam
        ("spa", "Spa"),
        ("hammam", "Hammam"),
        ("sauna", "Sauna"),
        ("jacuzzi", "Jacuzzi"),
        # Maquillage permanent
        ("permanent_makeup", "Maquillage permanent"),
        ("lip_tattoo", "Tatouage lèvres"),
        ("eyeliner_tattoo", "Tatouage eye-liner"),
        # Hommes
        ("barber", "Barbier"),
        ("beard_trim", "Taille de barbe"),
        ("beard_care", "Soins barbe"),
        ("men_facial", "Soin visage homme"),
        # Autres
        ("henna", "Henné"),
        ("teeth_whitening", "Blanchiment dentaire"),
        ("piercing", "Piercing"),
        ("other", "Autre"),
    )

    LANG_CHOICES = (
        ("french", "Français"),
        ("arabic", "Arabe"),
        ("english", "Anglais"),
    )

    # Données d'identité
    first_name = models.CharField(max_length=150)
    last_name = models.CharField(max_length=150)
    email = models.EmailField()
    phone_number = models.CharField(max_length=32)
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES, default="female")

    # Informations professionnelles
    activity_category = models.CharField(max_length=32, choices=ACTIVITY_CATEGORIES)
    service_type = models.CharField(max_length=16, choices=SERVICE_TYPES)
    spoken_languages = models.JSONField(default=list, help_text="Liste de codes langues")
    # Services proposés (liste JSON: [{name, duration_min, price}])
    services = models.JSONField(default=list, blank=True, help_text="Liste des services proposés")

    # Adresse du centre pour paiement/facturation
    governorate = models.CharField(max_length=64, blank=True)
    address = models.TextField()
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)

    # Pièces
    profile_photo = models.CharField(max_length=512, blank=True)
    id_document = models.CharField(max_length=512, blank=True)

    # Abonnement souhaité
    subscription_active = models.BooleanField(default=False)

    # Nom du salon (si service_type == 'salon')
    salon_name = models.CharField(max_length=255, blank=True)

    # Statut
    is_processed = models.BooleanField(default=False)
    is_approved = models.BooleanField(default=False)
    processed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    processed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="processed_professional_applications",
    )

    def __str__(self) -> str:
        return f"Application {self.email} - approved={self.is_approved}"


class ProfessionalApplicationAction(models.Model):
    """Historique des actions sur une demande pro (création, approbation, rejet)."""

    ACTIONS = (
        ("submitted", "Soumise"),
        ("viewed", "Consultée"),
        ("approved", "Approuvée"),
        ("rejected", "Rejetée"),
        ("comment", "Commentaire"),
    )

    application = models.ForeignKey(
        ProfessionalApplication,
        on_delete=models.CASCADE,
        related_name="actions",
    )
    action = models.CharField(max_length=16, choices=ACTIONS)
    actor = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL
    )
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

