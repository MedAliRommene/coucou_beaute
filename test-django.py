#!/usr/bin/env python
import os
import sys
import django

# Setup Django
sys.path.insert(0, '/app')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'coucou_beaute.settings')
django.setup()

from django.conf import settings
from django.contrib.staticfiles.finders import find

print("=" * 60)
print("DJANGO STATIC FILES CONFIGURATION")
print("=" * 60)
print(f"DEBUG: {settings.DEBUG}")
print(f"STATIC_URL: {settings.STATIC_URL}")
print(f"STATIC_ROOT: {settings.STATIC_ROOT}")
print(f"STATICFILES_DIRS: {settings.STATICFILES_DIRS}")
print()

print("=" * 60)
print("CHECKING STATIC FILES")
print("=" * 60)

files_to_check = [
    'images/logo-coucou-beaute.png',
    'images/image.png',
    'images/image2.jpg',
    'adminpanel/css/admin-mobile.css',
]

for file in files_to_check:
    result = find(file)
    print(f"{file}: {result if result else 'NOT FOUND'}")

