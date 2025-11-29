#!/bin/bash
# Start Ryu controller with the simple firewall application

echo "Starting Ryu controller with simple_firewall_student.py..."
ryu-manager /app/simple_firewall_student.py --verbose
