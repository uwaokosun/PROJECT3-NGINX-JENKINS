#!/bin/bash

# Update package lists
sudo apt update -y

# Install Nginx
sudo apt install nginx -y

# Restart Nginx
sudo systemctl restart nginx