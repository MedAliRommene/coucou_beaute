#!/bin/bash
# Script pour corriger l'encodage des fichiers statiques sur le serveur

set -euo pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "🔧 Correction de l'encodage des fichiers statiques..."

# Exécuter dans le conteneur web
docker exec coucou_web python -c "
import os
import chardet

def convert_to_utf8(file_path, source_encoding):
    try:
        with open(file_path, 'rb') as f:
            raw_data = f.read()
        
        # Decode with detected encoding and re-encode as UTF-8
        text = raw_data.decode(source_encoding)
        
        with open(file_path, 'w', encoding='utf-8', newline='\n') as f:
            f.write(text)
        
        print(f'Converted {file_path} from {source_encoding} to UTF-8')
        return True
    except Exception as e:
        print(f'Error converting {file_path}: {e}')
        return False

def find_and_convert_non_utf8_files(directory):
    converted = 0
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(('.css', '.js', '.html', '.txt')):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'rb') as f:
                        raw_data = f.read()
                    detected = chardet.detect(raw_data)
                    if detected['encoding'] != 'utf-8' and detected['confidence'] > 0.7:
                        if convert_to_utf8(file_path, detected['encoding']):
                            converted += 1
                except Exception as e:
                    print(f'Error processing {file_path}: {e}')
    return converted

# Convertir tous les fichiers statiques
static_dirs = ['/app/static', '/app/front_web/static', '/app/users/static', '/app/appointments/static', '/app/reviews/static', '/app/subscriptions/static', '/app/adminpanel/static']
total_converted = 0

for static_dir in static_dirs:
    if os.path.exists(static_dir):
        print(f'Checking {static_dir}...')
        converted = find_and_convert_non_utf8_files(static_dir)
        total_converted += converted
        print(f'Converted {converted} files in {static_dir}')

print(f'Total converted: {total_converted} files to UTF-8')
"

log "✅ Correction de l'encodage terminée"
