#!/bin/bash

CMD_PATH=$(dirname $0)
source $CMD_PATH/_utils.sh

multipass launch --name client-ssl -m 4Gb -d 10Gb -c 2

# Transfer CA certificate to client-ssl VM
echo "Transferring CA certificate to client-ssl VM..."
multipass transfer ca.crt client-ssl:/home/ubuntu/ca.crt
check_error "Transferring CA certificate to client-ssl VM"

# Get server-ssl IP address
SERVER_SSL_IP=$(multipass info server-ssl | grep "IPv4" | awk '{print $2}')

# Configure client-ssl VM
multipass shell client-ssl <<EOF

# Install and configure openssl, firefox, and rdp
echo "Installing and configuring openssl, firefox, and rdp..."
sudo apt update
sudo apt install -y openssl firefox

echo "Installing rdp..."
sudo apt -qqy install --no-install-recommends ubuntu-desktop
sudo apt -qqy install xfce4 xfce4-goodies xrdp xdg-desktop-portal-gtk
echo ""exec startxfce4"" | sudo tee -a /etc/xrdp/xrdp.ini
sudo adduser xrdp ssl-cert
sudo systemctl restart xrdp
echo xfce4-session | sudo tee /home/ubuntu/.xsession
echo "ubuntu:ubuntu" | sudo chpasswd
echo "$SERVER_SSL_IP www.example.loc" | sudo tee -a /etc/hosts

# Add CA certificate to system certificates
echo "Adding CA certificate to system certificates..."
sudo cp /home/ubuntu/ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

EOF

# Execute SSL test on client-ssl VM
echo "Executing SSL test on client-ssl VM..."
multipass exec client-ssl -- curl -vvv https://www.example.loc 2>&1 | grep -A 6 "Server certificate:"
