#!/bin/bash
echo "=== Checking if admin-mobile.css exists in container ==="
ssh vpsuser@196.203.120.35 "docker exec coucou_web test -f /app/adminpanel/static/adminpanel/css/admin-mobile.css && echo 'EXISTS' || echo 'NOT FOUND'"

echo ""
echo "=== Checking collected static ==="
ssh vpsuser@196.203.120.35 "docker exec coucou_web test -f /app/static/adminpanel/css/admin-mobile.css && echo 'EXISTS' || echo 'NOT FOUND'"

echo ""
echo "=== Running collectstatic again ==="
ssh vpsuser@196.203.120.35 "docker exec coucou_web python manage.py collectstatic --noinput -v 2 | tail -20"

echo ""
echo "=== Checking again after collectstatic ==="
ssh vpsuser@196.203.120.35 "docker exec coucou_web ls -la /app/static/adminpanel/css/"

echo ""
echo "=== Try accessing the site ==="
ssh vpsuser@196.203.120.35 "docker exec coucou_web curl -s -o /dev/null -w '%{http_code}' http://localhost:8000/"

