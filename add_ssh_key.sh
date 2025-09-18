#!/bin/bash

# Script pour ajouter la clé SSH publique au serveur
# Usage: ./add_ssh_key.sh

SERVER_HOST="196.203.120.35"
SERVER_USER="vpsuser"
SERVER_PASSWORD="VPS-adminUser@2025"

# Clé publique SSH
PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDPAqjcsRWNwxaY7BzjOvDUc1a3/j4m0EysU+CeECiGmKc+9NUYPK3B5ttNwlDsNIlORCXg1tau3AY5xg+foMKSESH0RT3MSg3pZ1aOZoxdAq6WDMgxGcXL2DbzBtf5K5UMXDHYM1SKnK7+ZHayzoSJrXAa2+K42WoFz+sUFFdbDNJIajJdD9lOaK7VyjlbkUb5X0JiVIUjt0bow8A2ZW7TXEH7lzCOu6TYsLU7v07cd4ednlT8eK1orx42wkwtvkB7UdNc3XgGO9YPCXqA34+HlNz+730oCMqYEKUoZgS3FmC8Da9XWuzEWKMj+Zo2KnN0u6MvYyTtLbkHxCANHnoWZQEa0m7U0dpcXPTb0SxlPcTlVjx0BcAhi9INIWC4zCboSZCkKgXIgwsnUaOLyj1JvUIXow+YwWuq4k2LOGcMUqDsrZMFH9rFVX3VKbAgZZJ7/ksclIGQYeXQp+vQCXVj7p1FggBaK+kC/Kc4LdaKjX5g/KVilU3hY7l9UHIerPUIKPCC8fBQfq80rXZKtI/nmod9hmmtHIXBh9euHSIj0qY9Z6pFQ9dAZEBuwOUwnrh3B97zGgdAncxhL9UOWjjMLzrnI4I1AcOhNtg3kQW16o2Rz2EL3MInHEUWystgL7oCYr66sxsnrERs4BuhwxMID0NS+trL9Pqy4cAOwbfyfQ== github-actions-coucou-beaute"

echo "🔑 Ajout de la clé SSH publique au serveur..."

# Utiliser sshpass pour l'authentification par mot de passe
sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_HOST" "
  # Créer le répertoire .ssh s'il n'existe pas
  mkdir -p ~/.ssh
  
  # Ajouter la clé publique à authorized_keys
  echo '$PUBLIC_KEY' >> ~/.ssh/authorized_keys
  
  # Définir les bonnes permissions
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/authorized_keys
  
  echo '✅ Clé SSH publique ajoutée avec succès !'
"

echo "🎉 Configuration SSH terminée !"
