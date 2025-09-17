from django.urls import path
from . import views

app_name = 'reviews'

urlpatterns = [
    # API pour les avis
    path('professional/<int:professional_id>/reviews/', views.get_professional_reviews, name='professional_reviews'),
    path('professional/<int:professional_id>/rating-stats/', views.get_professional_rating_stats, name='professional_rating_stats'),
    path('create/', views.create_review, name='create_review'),
    path('user-reviews/', views.get_user_reviews, name='user_reviews'),
    path('review/<int:review_id>/', views.update_or_delete_review, name='update_or_delete_review'),
]
