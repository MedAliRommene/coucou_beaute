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
    path('pro/onboarding/', views.pro_onboarding, name='pro_onboarding'),
    path('pro/onboarding/save/', views.save_professional_extras_web, name='pro_onboarding_save'),
    path('booking/', views.booking_page, name='booking'),
    path('professional/<int:pro_id>/', views.professional_detail, name='professional_detail'),
]

