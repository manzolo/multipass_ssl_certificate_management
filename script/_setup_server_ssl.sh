#!/bin/bash

CMD_PATH=$(dirname $0)
source $CMD_PATH/_utils.sh

multipass launch --name server-ssl -m 2Gb -d 10Gb -c 1

# Transfer certificates from CA VM to server-ssl VM
echo "Transferring certificates from CA VM to server-ssl VM..."

# Transfer server chain certificate
multipass transfer certificates/server_chain.crt server-ssl:/home/ubuntu/server_chain.crt
check_error "Transferring server chain certificate from CA VM to server-ssl VM"

# Transfer CA certificate
multipass transfer certificates/ca.crt server-ssl:/home/ubuntu/ca.crt
check_error "Transferring CA certificate from CA VM to server-ssl VM"

# Transfer server certificate
multipass transfer certificates/server.crt server-ssl:/home/ubuntu/server.crt
check_error "Transferring server certificate from CA VM to server-ssl VM"

# Transfer server key
multipass transfer certificates/server.key server-ssl:/home/ubuntu/server.key
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

