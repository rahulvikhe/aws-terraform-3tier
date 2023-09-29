#!/bin/bash

# Update the system
yum update -y

# Install Apache HTTP Server
yum install -y httpd.x86_64

# Start the Apache service
systemctl start httpd.service

# Enable Apache to start on boot
systemctl enable httpd.service

# Create a simple HTML file with a greeting
echo "Hello World from $(hostname -f)" > /var/www/html/index.html

# Inform the user about the script completion
echo "Apache HTTP Server is installed and configured."
