#!/bin/bash
echo "=== Checking static files in container ==="
docker exec coucou_web ls -la /app/adminpanel/static/adminpanel/css/ 2>&1
echo ""
echo "=== Checking shared static images ==="
docker exec coucou_web ls -la /app/shared/static/images/ 2>&1
echo ""
echo "=== Checking collected static ==="
docker exec coucou_web ls -la /app/static/images/ 2>&1
echo ""
echo "=== Checking adminpanel CSS in collected static ==="
docker exec coucou_web ls -la /app/static/adminpanel/css/ 2>&1

