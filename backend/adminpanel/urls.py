from django.urls import path
from . import views

app_name = 'adminpanel'

urlpatterns = [
    path('', views.entry_point, name='entry'),
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
    path('dashboard/', views.dashboard_view, name='dashboard'),
    path('clients/', views.clients_view, name='clients'),
    path('pros/', views.pros_view, name='pros'),
    path('pros/pending/', views.pros_pending_view, name='pros_pending'),
    path('appointments/', views.appointments_view, name='appointments'),
    path('reviews/', views.reviews_view, name='reviews'),
    path('subscriptions/', views.subscriptions_view, name='subscriptions'),
    path('notifications/', views.notifications_view, name='notifications'),
    path('stats/', views.stats_view, name='stats'),
    path('settings/', views.settings_view, name='settings'),
]
