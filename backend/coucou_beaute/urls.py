from django.contrib import admin
from django.urls import include, path
from django.conf import settings
from django.conf.urls.static import static
from django.views.generic import RedirectView
from django.contrib.auth import views as auth_views

urlpatterns = [
    # Public/front web
    path('', include('front_web.urls', namespace='front_web')),
    # Admin dashboard moved under /dashboard/
    path('dashboard/', include('adminpanel.urls', namespace='adminpanel')),
    path('admin/', admin.site.urls),
    path('logout/', auth_views.LogoutView.as_view(), name='logout'),
    # API
    path('api/', include('users.urls')),
    path('api/appointments/', include('appointments.urls', namespace='appointments')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
