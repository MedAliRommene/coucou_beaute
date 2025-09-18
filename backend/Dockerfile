# ===========================================
# DOCKERFILE PRODUCTION - Coucou Beauté
# ===========================================

FROM python:3.11-slim as base

# Variables d'environnement
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Installation des dépendances système
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    gettext \
    && rm -rf /var/lib/apt/lists/*

# ===========================================
# STAGE 1: INSTALLATION DES DÉPENDANCES
# ===========================================
FROM base as dependencies

WORKDIR /app

# Copier et installer les requirements
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# ===========================================
# STAGE 2: APPLICATION
# ===========================================
FROM base as application

WORKDIR /app

# Créer un utilisateur non-root
RUN groupadd -r django && useradd -r -g django django

# Copier les dépendances installées
COPY --from=dependencies /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=dependencies /usr/local/bin /usr/local/bin

# Copier le code de l'application
COPY . /app

# Créer les répertoires nécessaires
RUN mkdir -p /app/static /app/media /app/logs && \
    chown -R django:django /app

# Changer vers l'utilisateur non-root
USER django

# Exposer le port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

# Commande de démarrage
CMD ["gunicorn", "coucou_beaute.wsgi:application", \
    "--bind", "0.0.0.0:8000", \
    "--workers", "3", \
    "--worker-class", "gevent", \
    "--worker-connections", "1000", \
    "--max-requests", "1000", \
    "--max-requests-jitter", "100", \
    "--timeout", "30", \
    "--keep-alive", "2", \
    "--access-logfile", "-", \
    "--error-logfile", "-", \
    "--log-level", "info"]
