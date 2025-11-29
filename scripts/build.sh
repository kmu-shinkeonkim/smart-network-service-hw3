#!/bin/bash
# Build Docker image for SDN HW3

echo "=== Building Docker image for SDN HW3 ==="
echo ""

cd "$(dirname "$0")/.."

docker-compose build --no-cache

if [ $? -eq 0 ]; then
    echo ""
    echo "=== Build successful! ==="
    echo ""
    echo "To start the container, run:"
    echo "  docker-compose up -d"
    echo ""
    echo "To access the container, run:"
    echo "  docker exec -it sdn-hw3-firewall /bin/bash"
else
    echo ""
    echo "=== Build failed! ==="
    exit 1
fi
