from django.urls import path
from . import views
from . import views_api

app_name = 'users'

urlpatterns = [
    # API mobile
    path('auth/login/', views_api.login_with_email, name='login_with_email'),
    path('auth/me/', views_api.me_profile, name='me_profile'),
    path('auth/register/client/', views_api.register_client, name='register_client'),
    path('professionals/extras/save/', views_api.save_professional_extras, name='save_professional_extras'),
    # Mobile search endpoint (separate path to avoid conflict with admin list)
    path('professionals/search/', views_api.professionals_search, name='professionals_search'),
    path('professionals/categories/', views_api.professionals_categories, name='professionals_categories'),
    path('applications/professionals/', views_api.submit_professional_application, name='submit_professional_application'),
    path('applications/upload/', views_api.upload_application_file, name='upload_application_file'),

    # Admin/API backoffice
    path('applications/professionals/pending/', views.pending_professional_applications, name='pending_professional_applications'),
    path('applications/professionals/<int:app_id>/approve/', views.approve_professional_application, name='approve_professional_application'),
    path('applications/professionals/<int:app_id>/reject/', views.reject_professional_application, name='reject_professional_application'),
    path('applications/<int:app_id>/delete/', views.delete_application, name='delete_application'),
    # Admin list endpoint
    path('professionals/', views.list_professionals, name='list_professionals'),
    path('professionals/summary/', views.professionals_summary, name='professionals_summary'),
    path('professionals/sync/', views.sync_professionals_from_approved, name='sync_professionals_from_approved'),
    path('professionals/<int:pro_id>/verify/', views.verify_professional, name='verify_professional'),
    path('professionals/<int:pro_id>/delete/', views.delete_professional, name='delete_professional'),
    path('applications/summary/', views.applications_summary, name='applications_summary'),
    path('applications/', views.list_applications, name='list_applications'),
    path('applications/purge/', views.purge_applications, name='purge_applications'),
    path('applications/audit/', views.application_actions_audit, name='application_actions_audit'),
]
