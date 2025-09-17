from rest_framework import serializers
from .models import Review, ReviewImage
from users.models import Professional
from django.contrib.auth import get_user_model

User = get_user_model()

class ReviewImageSerializer(serializers.ModelSerializer):
    """Serializer pour les images d'avis"""
    
    class Meta:
        model = ReviewImage
        fields = ['id', 'image', 'created_at']
        read_only_fields = ['id', 'created_at']

class ReviewSerializer(serializers.ModelSerializer):
    """Serializer pour les avis"""
    
    images = ReviewImageSerializer(many=True, read_only=True)
    client_name = serializers.ReadOnlyField()
    professional_name = serializers.ReadOnlyField()
    stars_display = serializers.ReadOnlyField()
    
    class Meta:
        model = Review
        fields = [
            'id', 'client', 'professional', 'rating', 'comment',
            'created_at', 'updated_at', 'is_verified', 'is_public',
            'client_name', 'professional_name', 'stars_display', 'images'
        ]
        read_only_fields = ['id', 'client', 'created_at', 'updated_at', 'is_verified']
    
    def validate_rating(self, value):
        """Validation de la note"""
        if not (1 <= value <= 5):
            raise serializers.ValidationError("La note doit être entre 1 et 5 étoiles")
        return value
    
    def validate(self, data):
        """Validation globale"""
        # Vérifier qu'un client ne peut donner qu'un avis par professionnel
        if self.instance is None:  # Création d'un nouvel avis
            client = data.get('client')
            professional = data.get('professional')
            
            if client and professional:
                if Review.objects.filter(client=client, professional=professional).exists():
                    raise serializers.ValidationError(
                        "Vous avez déjà donné un avis pour ce professionnel"
                    )
        
        return data

class ReviewCreateSerializer(serializers.ModelSerializer):
    """Serializer pour la création d'avis (sans client, ajouté automatiquement)"""
    
    images = ReviewImageSerializer(many=True, read_only=True)
    
    class Meta:
        model = Review
        fields = ['professional', 'rating', 'comment', 'images']
    
    def validate_rating(self, value):
        """Validation de la note"""
        if not (1 <= value <= 5):
            raise serializers.ValidationError("La note doit être entre 1 et 5 étoiles")
        return value
    
    def create(self, validated_data):
        """Créer un avis avec le client de la requête"""
        validated_data['client'] = self.context['request'].user
        return super().create(validated_data)

class ReviewSummarySerializer(serializers.ModelSerializer):
    """Serializer pour les résumés d'avis (dashboard, listes)"""
    
    client_name = serializers.ReadOnlyField()
    stars_display = serializers.ReadOnlyField()
    
    class Meta:
        model = Review
        fields = [
            'id', 'rating', 'comment', 'created_at',
            'client_name', 'stars_display'
        ]
