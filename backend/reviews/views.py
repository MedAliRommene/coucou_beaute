# Vues pour l'app reviews
# Système d'avis et évaluations

from django.shortcuts import render, get_object_or_404
from django.http import JsonResponse
from django.contrib.auth.decorators import login_required
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from django.db.models import Avg, Count, Q
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.authentication import SessionAuthentication
from rest_framework.response import Response
from .models import Review, ReviewImage
from .serializers import ReviewSerializer, ReviewCreateSerializer, ReviewSummarySerializer
from users.models import Professional
from users.models import ProfessionalProfileExtra
import json

@api_view(['GET'])
def get_professional_reviews(request, professional_id):
    """Récupérer les avis d'un professionnel"""
    try:
        professional = Professional.objects.get(id=professional_id)
        reviews = Review.objects.filter(
            professional=professional,
            is_public=True
        ).order_by('-created_at')
        
        serializer = ReviewSummarySerializer(reviews, many=True)
        
        # Calculer les statistiques
        total_reviews = reviews.count()
        if total_reviews > 0:
            avg_rating = reviews.aggregate(avg_rating=Avg('rating'))['avg_rating']
            rating_distribution = {}
            for i in range(1, 6):
                rating_distribution[i] = reviews.filter(rating=i).count()
        else:
            avg_rating = 0
            rating_distribution = {i: 0 for i in range(1, 6)}
        
        return Response({
            'reviews': serializer.data,
            'statistics': {
                'total_reviews': total_reviews,
                'average_rating': round(avg_rating, 1) if avg_rating else 0,
                'rating_distribution': rating_distribution
            }
        })
        
    except Professional.DoesNotExist:
        return Response(
            {'detail': 'Professionnel non trouvé'}, 
            status=status.HTTP_404_NOT_FOUND
        )

@api_view(['POST'])
@permission_classes([IsAuthenticated])
@authentication_classes([SessionAuthentication])
def create_review(request):
    """Créer un nouvel avis"""
    try:
        serializer = ReviewCreateSerializer(data=request.data, context={'request': request})
        
        if serializer.is_valid():
            # Vérifier que l'utilisateur a un profil client
            if not hasattr(request.user, 'client_profile'):
                return Response(
                    {'detail': 'Seuls les clients peuvent donner des avis'}, 
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Vérifier que le professionnel existe
            professional_id = request.data.get('professional')
            try:
                professional = Professional.objects.get(id=professional_id)
            except Professional.DoesNotExist:
                return Response(
                    {'detail': 'Professionnel non trouvé'}, 
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Vérifier qu'il n'y a pas déjà un avis
            if Review.objects.filter(client=request.user, professional=professional).exists():
                return Response(
                    {'detail': 'Vous avez déjà donné un avis pour ce professionnel'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            review = serializer.save()
            
            # Mettre à jour les statistiques du professionnel
            update_professional_rating(professional)
            
            return Response(
                ReviewSerializer(review).data, 
                status=status.HTTP_201_CREATED
            )
        else:
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            
    except Exception as e:
        return Response(
            {'detail': f'Erreur lors de la création de l\'avis: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['PUT', 'DELETE'])
@permission_classes([IsAuthenticated])
@authentication_classes([SessionAuthentication])
def update_or_delete_review(request, review_id):
    """Modifier ou supprimer un avis"""
    try:
        review = Review.objects.get(id=review_id)
        
        # Vérifier que l'utilisateur est le propriétaire de l'avis
        if review.client != request.user:
            return Response(
                {'detail': 'Vous ne pouvez modifier que vos propres avis'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        if request.method == 'PUT':
            serializer = ReviewSerializer(review, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                
                # Mettre à jour les statistiques du professionnel
                update_professional_rating(review.professional)
                
                return Response(serializer.data)
            else:
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        elif request.method == 'DELETE':
            professional = review.professional
            review.delete()
            
            # Mettre à jour les statistiques du professionnel
            update_professional_rating(professional)
            
            return Response({'detail': 'Avis supprimé avec succès'})
            
    except Review.DoesNotExist:
        return Response(
            {'detail': 'Avis non trouvé'}, 
            status=status.HTTP_404_NOT_FOUND
        )

@api_view(['GET'])
@permission_classes([IsAuthenticated])
@authentication_classes([SessionAuthentication])
def get_user_reviews(request):
    """Récupérer les avis donnés par l'utilisateur connecté"""
    reviews = Review.objects.filter(client=request.user).order_by('-created_at')
    serializer = ReviewSerializer(reviews, many=True)
    return Response(serializer.data)

def update_professional_rating(professional):
    """Mettre à jour la note moyenne et le nombre d'avis d'un professionnel"""
    try:
        extra = professional.extra
        if not extra:
            extra = ProfessionalProfileExtra.objects.create(professional=professional)
        
        # Calculer les nouvelles statistiques
        reviews = Review.objects.filter(professional=professional, is_public=True)
        total_reviews = reviews.count()
        
        if total_reviews > 0:
            avg_rating = reviews.aggregate(avg_rating=Avg('rating'))['avg_rating']
            extra.rating = round(avg_rating, 1)
            extra.reviews = total_reviews
        else:
            extra.rating = 0
            extra.reviews = 0
        
        extra.save()
        
    except Exception as e:
        print(f"Erreur lors de la mise à jour des statistiques: {e}")

@api_view(['GET'])
def get_professional_rating_stats(request, professional_id):
    """Récupérer les statistiques de notation d'un professionnel"""
    try:
        professional = Professional.objects.get(id=professional_id)
        extra = professional.extra
        
        if not extra:
            return Response({
                'rating': 0,
                'reviews_count': 0,
                'rating_distribution': {i: 0 for i in range(1, 6)}
            })
        
        # Calculer la distribution des notes
        reviews = Review.objects.filter(professional=professional, is_public=True)
        rating_distribution = {}
        for i in range(1, 6):
            rating_distribution[i] = reviews.filter(rating=i).count()
        
        return Response({
            'rating': extra.rating or 0,
            'reviews_count': extra.reviews or 0,
            'rating_distribution': rating_distribution
        })
        
    except Professional.DoesNotExist:
        return Response(
            {'detail': 'Professionnel non trouvé'}, 
            status=status.HTTP_404_NOT_FOUND
        )
