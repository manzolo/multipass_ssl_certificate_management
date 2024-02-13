#!/bin/bash

# Importa funzioni di utilità comuni
CMD_PATH=$(dirname $0)
source $CMD_PATH/_utils.sh

multipass launch --name ca-vm -m 1Gb -d 5Gb -c 1
multipass transfer openssl_ext.conf ca-vm:/home/ubuntu/openssl_ext.conf
check_error "Creating VM for the private CA"

# Install dependencies on CA VM
echo "Installing dependencies on CA VM..."
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
echo "Transferring certificates from CA VM..."

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

