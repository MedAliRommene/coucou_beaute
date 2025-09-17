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
    path('pros/<int:pro_id>/', views.pro_detail_view, name='pro_detail'),
    path('pros/pending/<int:app_id>/', views.pro_application_detail_view, name='pro_application_detail'),
    # Admin API
    path('api/pros/<int:pro_id>/extras/save/', views.api_save_pro_extras, name='api_save_pro_extras'),
    path('appointments/', views.appointments_view, name='appointments'),
    path('reviews/', views.reviews_view, name='reviews'),
    path('reviews/center/<int:center_id>/', views.reviews_management, name='reviews_management'),
    path('reviews/<int:review_id>/delete/', views.delete_review, name='delete_review'),
    path('reviews/<int:review_id>/toggle-status/', views.toggle_review_status, name='toggle_review_status'),
    path('subscriptions/', views.subscriptions_view, name='subscriptions'),
    path('notifications/', views.notifications_view, name='notifications'),
    path('stats/', views.stats_view, name='stats'),
    path('settings/', views.settings_view, name='settings'),
]
