from django.urls import path
from . import views

app_name = 'front_web'

urlpatterns = [
    path('', views.landing, name='home'),
    path('login/', views.login_view, name='login'),
    path('signup/', views.signup_view, name='signup'),
    path('logout/', views.logout_view, name='logout'),
    path('client/', views.client_dashboard, name='client_dashboard'),
    path('client/appointments/', views.client_appointments, name='client_appointments'),
    path('client/calendar/', views.client_calendar, name='client_calendar'),
    path('pro/', views.pro_dashboard, name='pro_dashboard'),
    path('pro/appointments/', views.pro_appointments, name='pro_appointments'),
    path('pro/onboarding/', views.pro_onboarding, name='pro_onboarding'),
    path('pro/onboarding/save/', views.save_professional_extras_web, name='pro_onboarding_save'),
    path('booking/', views.booking_page, name='booking'),
    path('professional/<int:pro_id>/', views.professional_detail, name='professional_detail'),
    path('professional/<int:pro_id>/book/', views.book_appointment, name='book_appointment'),
    path('professional/<int:pro_id>/book-page/', views.book_appointment_page, name='book_appointment_page'),
    path('professional/<int:pro_id>/available-slots/', views.get_available_slots, name='get_available_slots'),
    path('professional/<int:pro_id>/review/', views.create_review, name='create_review'),
    path('professional/<int:pro_id>/review/submit/', views.submit_review, name='submit_review'),
    # Gestion des avis pour les professionnelles
    path('pro/reviews/', views.pro_reviews_management, name='pro_reviews_management'),
    path('pro/review/<int:review_id>/response/', views.pro_review_response, name='pro_review_response'),
    path('pro/review/<int:review_id>/toggle-visibility/', views.pro_toggle_review_visibility, name='pro_toggle_review_visibility'),
]

