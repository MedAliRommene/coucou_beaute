from django.urls import path
from . import views

app_name = 'appointments'

urlpatterns = [
    path('agenda/', views.agenda, name='agenda'),
    path('agenda/day/', views.agenda_day, name='agenda_day'),
    path('kpis/', views.kpis, name='kpis'),
    path('analytics/overview/', views.analytics_overview, name='analytics_overview'),
    path('notifications/', views.notifications, name='notifications'),
    path('notifications/unread_count/', views.notifications_unread_count, name='notifications_unread_count'),
    path('notifications/mark_read/', views.notifications_mark_read, name='notifications_mark_read'),
    path('create/', views.create_appointment, name='create'),
    path('update/<int:pk>/', views.update_appointment, name='update'),
    path('seed_demo/', views.seed_demo, name='seed_demo'),
    # Public/client booking endpoints
    path('public/slots/', views.public_slots, name='public_slots'),
    path('client/book/', views.client_book, name='client_book'),
    # Web pro booking page helpers
    path('list/', views.list_for_pro, name='list_for_pro'),
    path('accept/', views.accept_appointment, name='accept_appointment'),
    path('reject/', views.reject_appointment, name='reject_appointment'),
]
