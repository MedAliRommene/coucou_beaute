import os
from pathlib import Path
from datetime import timedelta
from dotenv import load_dotenv
import os

load_dotenv()
BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.getenv('DJANGO_SECRET_KEY', 'dev-secret')
DEBUG = os.getenv('DJANGO_DEBUG', 'True') == 'True'
ALLOWED_HOSTS = os.getenv('DJANGO_ALLOWED_HOSTS', '*').split(',')

INSTALLED_APPS = [
	'django.contrib.admin',
	'django.contrib.auth',
	'django.contrib.contenttypes',
	'django.contrib.sessions',
	'django.contrib.messages',
	'django.contrib.staticfiles',
	'rest_framework',
	'rest_framework.authtoken',
	'django_filters',
	'drf_spectacular',
	'corsheaders',
	'storages',
	
	# Apps locales (structure plate souhaitée)
	
	'users',
	'appointments',
	'reviews',
	'subscriptions',
	'adminpanel',
	'front_web',
]

MIDDLEWARE = [
	'corsheaders.middleware.CorsMiddleware',
	'django.middleware.security.SecurityMiddleware',
	'whitenoise.middleware.WhiteNoiseMiddleware',  # Pour servir les fichiers statiques en production
	'django.contrib.sessions.middleware.SessionMiddleware',
	'django.middleware.common.CommonMiddleware',
	'django.middleware.csrf.CsrfViewMiddleware',
	'django.contrib.auth.middleware.AuthenticationMiddleware',
	'django.contrib.messages.middleware.MessageMiddleware',
	'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'coucou_beaute.urls'

TEMPLATES = [
	{
		'BACKEND': 'django.template.backends.django.DjangoTemplates',
		'DIRS': [BASE_DIR / 'shared' / 'templates'],
		'APP_DIRS': True,
		'OPTIONS': {
			'context_processors': [
				'django.template.context_processors.debug',
				'django.template.context_processors.request',
				'django.contrib.auth.context_processors.auth',
				'django.contrib.messages.context_processors.messages',
				'django.template.context_processors.media',
			],
		},
	},
]

WSGI_APPLICATION = 'coucou_beaute.wsgi.application'

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.getenv("POSTGRES_DB", "coucou_local"),
        "USER": os.getenv("POSTGRES_USER", "postgres"),
        "PASSWORD": os.getenv("POSTGRES_PASSWORD", "admin"),
        "HOST": os.getenv("POSTGRES_HOST", "localhost"),
        "PORT": os.getenv("POSTGRES_PORT", "5432"),
    }
}

AUTH_PASSWORD_VALIDATORS = [
	{'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
	{'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
	{'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
	{'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'fr'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# --- Static & Media ---
STATIC_URL = os.getenv('STATIC_URL', '/static/')
STATIC_ROOT = Path(os.getenv('STATIC_ROOT', str(BASE_DIR / 'static')))

# Inclure les assets additionnels uniquement en développement si le dossier existe
if DEBUG and (BASE_DIR / 'shared' / 'static').exists():
	STATICFILES_DIRS = [
		BASE_DIR / 'shared' / 'static',
	]
else:
	STATICFILES_DIRS = []

MEDIA_URL = os.getenv('MEDIA_URL', '/media/')
MEDIA_ROOT = Path(os.getenv('MEDIA_ROOT', str(BASE_DIR / 'media')))

# Configuration Whitenoise pour la production
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

AUTH_USER_MODEL = 'users.User'

# Auth redirects
LOGIN_URL = '/login/'
LOGIN_REDIRECT_URL = '/client/'  # Redirection par défaut vers client
LOGOUT_REDIRECT_URL = '/login/'

REST_FRAMEWORK = {
	'DEFAULT_AUTHENTICATION_CLASSES': (
		'rest_framework_simplejwt.authentication.JWTAuthentication',
		'rest_framework.authentication.SessionAuthentication',
	),
	'DEFAULT_PERMISSION_CLASSES': (
		'rest_framework.permissions.IsAuthenticated',
	),
	'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',
	'DEFAULT_FILTER_BACKENDS': (
		'django_filters.rest_framework.DjangoFilterBackend',
	)
}


SPECTACULAR_SETTINGS = {
	'TITLE': 'Coucou Beauté API',
	'DESCRIPTION': 'Plateforme de prise de rendez-vous beauté',
	'VERSION': '1.0.0',
}

SIMPLE_JWT = {
	'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
	'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
}

CORS_ALLOWED_ORIGINS = [u for u in os.getenv('DJANGO_CORS_ORIGINS', '').split(',') if u]
# Sécurité : ne jamais autoriser toutes les origines en production
CORS_ALLOW_ALL_ORIGINS = DEBUG and not CORS_ALLOWED_ORIGINS

# --- Email settings (ENV‑driven; console backend by default in DEBUG) ---
if DEBUG:
	EMAIL_BACKEND = os.getenv('EMAIL_BACKEND', 'django.core.mail.backends.console.EmailBackend')
else:
	EMAIL_BACKEND = os.getenv('EMAIL_BACKEND', 'django.core.mail.backends.smtp.EmailBackend')
EMAIL_HOST = os.getenv('EMAIL_HOST')
EMAIL_PORT = int(os.getenv('EMAIL_PORT', '587'))
EMAIL_USE_TLS = os.getenv('EMAIL_USE_TLS', 'True') == 'True'
EMAIL_HOST_USER = os.getenv('EMAIL_HOST_USER', 'dalyrommen@gmail.com')
EMAIL_HOST_PASSWORD = os.getenv('EMAIL_HOST_PASSWORD')
DEFAULT_FROM_EMAIL = os.getenv('DEFAULT_FROM_EMAIL', os.getenv('EMAIL_HOST_USER', 'dalyrommen@gmail.com'))
SERVER_EMAIL = os.getenv('SERVER_EMAIL', DEFAULT_FROM_EMAIL)



# --- CSRF Trusted Origins (toujours actif) ---
# Configuration basée sur les variables d'environnement
csrf_origins = os.getenv('CSRF_TRUSTED_ORIGINS','').split(',')
CSRF_TRUSTED_ORIGINS = [u for u in csrf_origins if u]

# Ajouter automatiquement les origines HTTP/HTTPS basées sur ALLOWED_HOSTS
for host in ALLOWED_HOSTS:
	if host and host != '*':
		if not any(host in origin for origin in CSRF_TRUSTED_ORIGINS):
			CSRF_TRUSTED_ORIGINS.append(f'https://{host}')
			CSRF_TRUSTED_ORIGINS.append(f'http://{host}')

# --- Security headers & cookies in production ---
if not DEBUG:
	# Configuration sécurisée pour HTTPS
	CSRF_COOKIE_SECURE = os.getenv('CSRF_COOKIE_SECURE', 'False') == 'True'
	SESSION_COOKIE_SECURE = os.getenv('SESSION_COOKIE_SECURE', 'False') == 'True'
	SECURE_HSTS_SECONDS = int(os.getenv('SECURE_HSTS_SECONDS', '0'))
	SECURE_HSTS_INCLUDE_SUBDOMAINS = os.getenv('SECURE_HSTS_INCLUDE_SUBDOMAINS', 'False') == 'True'
	SECURE_HSTS_PRELOAD = os.getenv('SECURE_HSTS_PRELOAD', 'False') == 'True'
	SECURE_REFERRER_POLICY = os.getenv('SECURE_REFERRER_POLICY', 'strict-origin-when-cross-origin')
	SECURE_CONTENT_TYPE_NOSNIFF = True
	SECURE_BROWSER_XSS_FILTER = True
	SECURE_SSL_REDIRECT = os.getenv('SECURE_SSL_REDIRECT', 'False') == 'True'
else:
	# Configuration CSRF pour le développement
	CSRF_COOKIE_SECURE = False
	SESSION_COOKIE_SECURE = False

# Configuration CSRF globale
CSRF_COOKIE_HTTPONLY = False
CSRF_COOKIE_SAMESITE = 'Lax'
CSRF_USE_SESSIONS = False
CSRF_COOKIE_AGE = 31449600
CSRF_FAILURE_VIEW = 'django.views.csrf.csrf_failure'

# CSRF_TRUSTED_ORIGINS est maintenant géré par les variables d'environnement (ligne 176)
