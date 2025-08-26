from django.contrib import admin
from django.urls import include, path
from django.conf import settings
from django.conf.urls.static import static
from django.views.generic import RedirectView

urlpatterns = [
    path('', include('adminpanel.urls', namespace='adminpanel')),
    path('admin/', admin.site.urls),
    # API: pointe vers users.urls (core pas nécessaire)
    path('api/', include('users.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
