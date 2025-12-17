from rest_framework import serializers
from .models import ProfessionalApplication, ProfessionalApplicationAction, Professional, User, Client
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
            "gender",
            "activity_category",
            "service_type",
            "spoken_languages",
            "services",
            "governorate",
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

    def validate(self, attrs):
        service_type = attrs.get("service_type") or getattr(self.instance, "service_type", None)
        salon_name = attrs.get("salon_name", "")
        if service_type == "salon" and not str(salon_name or "").strip():
            raise serializers.ValidationError({"salon_name": "Nom du salon requis pour le type 'J'ai un salon'"})
        return super().validate(attrs)


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


class ClientRegistrationSerializer(serializers.Serializer):
    first_name = serializers.CharField(max_length=150)
    last_name = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=6)
    phone_number = serializers.CharField(max_length=32, required=False, allow_blank=True)
    address = serializers.CharField(required=False, allow_blank=True)
    city = serializers.CharField(required=False, allow_blank=True)
    latitude = serializers.FloatField(required=False)
    longitude = serializers.FloatField(required=False)

    def validate_email(self, value):
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("Cet e-mail est déjà utilisé")
        return value

    def validate_phone_number(self, value: str):
        if not value:
            return value
        phone = re.sub(r"[\s-]", "", value)
        pattern = re.compile(r"^\+?[0-9]{8,15}$")
        if not pattern.match(phone):
            raise serializers.ValidationError(
                "Numéro de téléphone invalide. Utilisez un format international (ex: +216XXXXXXXX)."
            )
        return phone

    def create(self, validated_data):
        phone = validated_data.get("phone_number") or ""
        base_username = (validated_data["email"].split('@')[0] or "client").replace(" ", "_")[:150]
        username = base_username
        i = 1
        from django.contrib.auth import get_user_model
        UserModel = get_user_model()
        while UserModel.objects.filter(username=username).exists():
            suffix = f"_{i}"
            username = (base_username[: (150 - len(suffix))] + suffix)
            i += 1
        user = UserModel.objects.create_user(
            username=username,
            email=validated_data["email"].strip().lower(),
            password=validated_data["password"],
            phone=phone,
            role="client",
            language="fr",
        )
        user.first_name = validated_data.get("first_name", "")
        user.last_name = validated_data.get("last_name", "")
        user.is_active = True
        user.save()

        Client.objects.create(
            user=user,
            phone_number=phone,
            address=validated_data.get("address", ""),
            city=validated_data.get("city", ""),
            latitude=validated_data.get("latitude"),
            longitude=validated_data.get("longitude"),
        )
        return user

