import os
from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'coucou_beaute.settings')
application = get_asgi_application()
