from rest_framework import serializers
from .models import ProfessionalApplication, ProfessionalApplicationAction, Professional, User
import re


class ProfessionalApplicationSerializer(serializers.ModelSerializer):
    actions = serializers.SerializerMethodField(read_only=True)
    status = serializers.SerializerMethodField(read_only=True)
    class Meta:
        model = ProfessionalApplication
        fields = [
            "id",
            "first_name",
            "last_name",
            "email",
            "phone_number",
            "activity_category",
            "service_type",
            "spoken_languages",
            "address",
            "latitude",
            "longitude",
            "profile_photo",
            "id_document",
            "subscription_active",
            "salon_name",
            "created_at",
            "processed_at",
            "is_processed",
            "is_approved",
            "status",
            "actions",
        ]
        read_only_fields = ["id", "created_at", "processed_at", "is_processed", "is_approved", "actions", "status"]

    def validate_email(self, value: str) -> str:
        # Empêche d'utiliser un e-mail déjà associé à un compte utilisateur
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError(
                "Cet e-mail est déjà associé à un compte. Veuillez utiliser un autre e-mail ou vous connecter."
            )
        return value

    def validate_phone_number(self, value: str) -> str:
        # Accept E.164 or local 8-12 digits with optional leading + and spaces
        phone = re.sub(r"[\s-]", "", value)
        pattern = re.compile(r"^\+?[0-9]{8,15}$")
        if not pattern.match(phone):
            raise serializers.ValidationError(
                "Numéro de téléphone invalide. Utilisez un format international (ex: +216XXXXXXXX)."
            )
        return phone

    def validate_spoken_languages(self, value):
        allowed = {"french", "arabic", "english"}
        if not isinstance(value, list):
            raise serializers.ValidationError("Doit être une liste de langues.")
        for v in value:
            if v not in allowed:
                raise serializers.ValidationError(f"Langue non supportée: {v}")
        return value

    def get_actions(self, obj):
        qs = obj.actions.all()[:20]
        return [
            {
                "action": a.action,
                "actor": getattr(a.actor, "email", None),
                "notes": a.notes,
                "created_at": a.created_at.isoformat(),
            }
            for a in qs
        ]

    def get_status(self, obj):
        if not obj.is_processed:
            return "pending"
        return "approved" if obj.is_approved else "rejected"


class ProfessionalListItemSerializer(serializers.ModelSerializer):
    user_email = serializers.CharField(source="user.email")
    class Meta:
        model = Professional
        fields = ["id", "user_email", "business_name", "is_verified", "created_at"]

    def validate_activity_category(self, value: str) -> str:
        allowed = {
            "hairdressing",
            "makeup",
            "manicure",
            "esthetics",
            "massage",
            "other",
        }
        if value not in allowed:
            raise serializers.ValidationError("Catégorie d'activité invalide")
        return value

    def validate_service_type(self, value: str) -> str:
        if value not in {"mobile", "home", "salon"}:
            raise serializers.ValidationError("Type de prestation invalide")
        return value

    def validate(self, attrs):
        service_type = attrs.get("service_type")
        salon_name = attrs.get("salon_name", "")
        if service_type == "salon" and not salon_name.strip():
            raise serializers.ValidationError({"salon_name": "Nom du salon requis pour le type 'J'ai un salon'"})
        return super().validate(attrs)

