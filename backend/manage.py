#!/usr/bin/env python
import os
import sys
from pathlib import Path

try:
	from dotenv import load_dotenv  # type: ignore
except Exception:
	load_dotenv = None  # fallback if not installed

if __name__ == "__main__":
	# Load environment variables from .env (repo root and backend/) for local dev
	if load_dotenv is not None:
		current_dir = Path(__file__).resolve().parent
		load_dotenv(current_dir.parent / '.env')
		load_dotenv(current_dir / '.env')

	os.environ.setdefault("DJANGO_SETTINGS_MODULE", "coucou_beaute.settings")
	from django.core.management import execute_from_command_line
	execute_from_command_line(sys.argv)
