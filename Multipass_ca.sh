#!/bin/bash

##############################################################################################################################
# ENV VARS:
CA_SUBJ="/C=IT/ST=Italy/L=Scarperia e San Piero/O=Manzolo/OU=Manzolo CA"

##############################################################################################################################


print_message() {
    local color="\e[0;33m"  # Colore arancione
    local message="$1"       # Messaggio da stampare
    echo -e "${color}${message}\e[0m"  # Stampare il messaggio con il colore
}

# Function to handle errors
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "\e[1;31mError while executing command: $1\e[0m"
        exit 1
    fi
}

# Function to clean up temporary files
cleanup_files() {
    rm -f server_chain.crt ca.crt server.crt server.key
}

print_message "Using CA Subject: $CA_SUBJ"
echo

# Stop and remove existing VMs
print_message "Stopping and removing existing VMs..."

multipass stop ca-vm
multipass stop server-ssl
multipass stop client-ssl
multipass delete ca-vm
multipass delete server-ssl
multipass delete client-ssl
multipass purge

check_error "Stopping and removing existing VMs"

cleanup_files

# Create VM for the private CA
print_message "Creating VM for the private CA..."
multipass launch --name ca-vm -m 1Gb -d 5Gb -c 1
multipass transfer openssl_ext.conf ca-vm:/home/ubuntu/openssl_ext.conf
check_error "Creating VM for the private CA"

# Install dependencies on CA VM
print_message "Installing dependencies on CA VM..."
multipass shell ca-vm <<EOF
# Function to handle errors
check_error() {
    if [ $? -ne 0 ]; then
        echo "Error while executing command: $1"
        exit 1
    fi
}
sudo apt update
sudo apt install -y openssl
check_error "Installing dependencies on CA VM"

# Create private CA and certificates
echo "Creating private CA and certificates..."
mkdir -p /home/ubuntu/ca
cd /home/ubuntu/ca
openssl genrsa -out ca.key 2048
openssl req -new -key ca.key -out ca.csr -subj "$CA_SUBJ"
openssl x509 -req -days 365 -in ca.csr -signkey ca.key -out ca.crt
check_error "Creating private CA and certificates"

# Create private key and server certificate
echo "Creating private key and server certificate..."
mkdir -p /home/ubuntu/server
cd /home/ubuntu/server
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -subj "$CA_SUBJ/CN=www.example.loc"
openssl x509 -req -days 365 -in server.csr -CA /home/ubuntu/ca/ca.crt -CAkey /home/ubuntu/ca/ca.key -CAcreateserial -out server.crt -extfile /home/ubuntu/openssl_ext.conf -extensions server_cert
check_error "Creating private key and server certificate"

# Combine server certificate and CA certificate into server chain
cat /home/ubuntu/server/server.crt /home/ubuntu/ca/ca.crt > /home/ubuntu/server_chain.crt
check_error "Combining server certificate and CA certificate"

EOF

# Transfer certificates from CA VM
print_message "Transferring certificates from CA VM..."

# Transfer CA certificate
multipass transfer ca-vm:/home/ubuntu/ca/ca.crt .
check_error "Transferring CA certificate from CA VM"

# Transfer server certificate
multipass transfer ca-vm:/home/ubuntu/server_chain.crt .
check_error "Transferring server chain certificate from CA VM"

# Transfer server certificate
multipass transfer ca-vm:/home/ubuntu/server/server.crt .
check_error "Transferring server certificate from CA VM"

# Transfer server key
multipass transfer ca-vm:/home/ubuntu/server/server.key .
check_error "Transferring server key from CA VM"

# Create VM for SSL testing
print_message "Creating VM for SSL testing..."
multipass launch --name server-ssl -m 2Gb -d 10Gb -c 1

# Transfer certificates from CA VM to server-ssl VM
print_message "Transferring certificates from CA VM to server-ssl VM..."

# Transfer server chain certificate
multipass transfer server_chain.crt server-ssl:/home/ubuntu/server_chain.crt
check_error "Transferring server chain certificate from CA VM to server-ssl VM"

# Transfer CA certificate
multipass transfer ca.crt server-ssl:/home/ubuntu/ca.crt
check_error "Transferring CA certificate from CA VM to server-ssl VM"

# Transfer server certificate
multipass transfer server.crt server-ssl:/home/ubuntu/server.crt
check_error "Transferring server certificate from CA VM to server-ssl VM"

# Transfer server key
multipass transfer server.key server-ssl:/home/ubuntu/server.key
check_error "Transferring server key from CA VM to server-ssl VM"

# Configure server-ssl VM
multipass shell server-ssl <<EOF

# Configuration of server-ssl VM for SSL testing
sudo apt update
sudo apt install -y apache2

# Copy server certificate and key to Apache directory
sudo cp /home/ubuntu/server.crt /etc/ssl/certs/
sudo cp /home/ubuntu/server.key /etc/ssl/certs/
sudo cp /home/ubuntu/server_chain.crt /etc/ssl/certs/

sudo cp /home/ubuntu/ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# Enable SSL and vhost modules of Apache
sudo a2enmod ssl
sudo a2enmod vhost_alias

sudo mkdir -p /var/www/html/www.example.loc/public_html

# Create a test webpage
echo "<!DOCTYPE html>
<html lang=\"en\">
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>Example Website</title>
</head>
<body>
    <h1>Welcome to Example Website</h1>
    <p>This is a test page for the www.example.loc website.</p>
</body>
</html>" | sudo tee /var/www/html/www.example.loc/public_html/index.html

# Configure virtual host for HTTPS
sudo tee /etc/apache2/sites-available/www.example.loc-ssl.conf > /dev/null <<EOT
<IfModule mod_ssl.c>
    <VirtualHost *:443>
        ServerAdmin webmaster@www.example.loc
        ServerName www.example.loc
        ServerAlias www.www.example.loc
        DocumentRoot /var/www/html/www.example.loc/public_html

        SSLEngine on
        SSLCertificateFile /etc/ssl/certs/server_chain.crt
        SSLCertificateKeyFile /etc/ssl/certs/server.key

        ErrorLog /var/www/html/www.example.loc/error.log
        CustomLog /var/www/html/www.example.loc/access.log combined
    </VirtualHost>
</IfModule>
EOT

# Enable SSL virtual host
sudo a2ensite www.example.loc-ssl

# Restart Apache to apply changes
sudo systemctl restart apache2
EOF

# Create client-ssl VM
print_message "Creating client-ssl VM..."
multipass launch --name client-ssl -m 4Gb -d 10Gb -c 2

# Transfer CA certificate to client-ssl VM
print_message "Transferring CA certificate to client-ssl VM..."
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
print_message "Executing SSL test on client-ssl VM..."
multipass exec client-ssl -- curl -vvv https://www.example.loc 2>&1 | grep -A 6 "Server certificate:"

print_message "Done! VMs have been created and configured for use with private CA and SSL certificates."
vms=("ca-vm" "server-ssl" "client-ssl")
# List of used VMs and their IP addresses
echo "List of VMs and their IP addresses:"
for vm in "${vms[@]}"; do
    ip=$(multipass info "$vm" | grep "IPv4" | awk '{print $2}')
    print_message "$ip	$vm"
done

# Ask if the IP addresses should be added to the /etc/hosts file
read -r -p "Do you want to add these IP addresses to the /etc/hosts file? [Y/n] " response
response=${response,,}  # Convert to lowercase
if [[ $response =~ ^(y|yes|)$ ]]; then
    for vm in "${vms[@]}"; do
        ip=$(multipass info "$vm" | grep "IPv4" | awk '{print $2}')
        echo "$ip	$vm" | sudo tee -a /etc/hosts
    done
    print_message "IP addresses added to the /etc/hosts file."
else
    print_message "No changes made to the /etc/hosts file."
fi
