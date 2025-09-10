from django.urls import path
from . import views

app_name = 'front_web'

urlpatterns = [
    path('', views.landing, name='home'),
    path('login/', views.login_view, name='login'),
    path('signup/', views.signup_view, name='signup'),
    path('client/', views.client_dashboard, name='client_dashboard'),
    path('pro/', views.pro_dashboard, name='pro_dashboard'),
    path('pro/onboarding/', views.pro_onboarding, name='pro_onboarding'),
    path('pro/onboarding/save/', views.save_professional_extras_web, name='pro_onboarding_save'),
    path('booking/', views.booking_page, name='booking'),
]

