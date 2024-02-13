# Multipass SSL Certificate Management
[![.github/workflows/ci.yml](https://github.com/manzolo/multipass_ssl_certificate_management/actions/workflows/ci.yml/badge.svg)](https://github.com/manzolo/multipass_ssl_certificate_management/actions/workflows/ci.yml)

This repository contains a Bash script named setup.sh for managing SSL certificates using Multipass virtual machines.

## Requirements

* Multipass: A lightweight VM manager for Linux, Windows, and macOS.
* Bash shell environment.

## Clone the repository:
```
git clone https://github.com/manzolo/multipass_ssl_certificate_management.git
cd multipass_ssl_certificate_management
```

## Run the script:
```
./setup.sh
```
![immagine](https://github.com/manzolo/multipass_ssl_certificate_management/assets/7722346/83909e46-4407-4cf4-8845-7a04299ed5eb)
![immagine](https://github.com/manzolo/multipass_ssl_certificate_management/assets/7722346/3602ae30-8469-4db3-a076-f554ca83779b)
![immagine](https://github.com/manzolo/multipass_ssl_certificate_management/assets/7722346/5de4c67c-73f7-4334-ab67-7c87b666bfd7)

![immagine](https://github.com/manzolo/multipass_ssl_certificate_management/assets/7722346/4f4288da-eb57-47dc-be1c-b3d5cfb88d97)
* user: ubuntu
* password: ubuntu
![immagine](https://github.com/manzolo/multipass_ssl_certificate_management/assets/7722346/7f37ee80-4761-4d85-9657-ed837cc1a347)

![immagine](https://github.com/manzolo/multipass_ssl_certificate_management/assets/7722346/1b55972e-7896-4542-aa18-0761fa2bfb9b)
![immagine](https://github.com/manzolo/multipass_ssl_certificate_management/assets/7722346/8ec504fa-1d00-4ed6-a2b2-d18798716482)

![immagine](https://github.com/manzolo/multipass_ssl_certificate_management/assets/7722346/ca978b55-de6e-4093-a9de-46eb64c296c1)

![immagine](https://github.com/manzolo/multipass_ssl_certificate_management/assets/7722346/6597a261-960d-4684-9c3f-e9b497cc8321)


## Description
The script setup.sh automates the management of SSL certificates using Multipass, a lightweight VM manager. Here's what it does:
* Creating VM for the Private CA: Launches a VM named ca-vm with specified resources and transfers the openssl_ext.conf file to it.
* Installing Dependencies on CA VM: Installs OpenSSL on the ca-vm and creates a private CA along with certificates.
* Creating Private Key and Server Certificate: Generates a private key and a server certificate signed by the private CA.
* Transferring Certificates from CA VM: Transfers the CA certificate, server chain certificate, server certificate, and server key from the ca-vm to the local machine.
* Creating VM for SSL Testing: Launches a VM named server-ssl for SSL testing.
* Transferring Certificates to Server-SSL VM: Transfers the server chain certificate, CA certificate, server certificate, and server key from the local machine to the server-ssl VM.
* Configuring Server-SSL VM: Installs Apache, copies SSL certificates and keys to the appropriate directory, creates a test webpage, configures a virtual host for HTTPS, and restarts Apache.
* Creating Client-SSL VM: Launches a VM named client-ssl and transfers the CA certificate to it.
* Configuring Client-SSL VM: Installs OpenSSL and Firefox, configures RDP, and adds the CA certificate to the system certificates.
* Executing SSL Test: Performs an SSL test on the client-ssl VM by sending a request to www.example.loc.
* Printing VM Information: Prints the IP addresses of the created VMs along with their names.
* Adding IP Addresses to /etc/hosts: Asks the user if they want to add the IP addresses of the VMs to the /etc/hosts file.

## Use Firefox to check ssl certificate
Users can connect to the client-ssl VM via RDP to open Firefox and verify SSL connections to the server-ssl VM.
To use the SSL certificates in Firefox, follow these steps:

* Open Firefox and navigate to the settings.
* Go to the "Privacy & Security" section.
* Scroll down to the "Certificates" section.
* Click on "View Certificates".
* In the "Authorities" tab, click on "Import" and select the CA certificate (/home/ubuntu/ca.crt in client-ssl VM) file.
* Follow the prompts to import the CA certificate.
* Once imported, Firefox will trust SSL connections signed by the private CA.

![Screenshot from 2024-02-13 01-38-51](https://github.com/manzolo/multipass_ssl_certificate_management/assets/7722346/95f8d9f5-56e5-490c-a5e9-53bedbe4a3ec)



## Features
* Automated setup of private CA and SSL certificates.
* Virtual machine management using Multipass.
* SSL configuration for Apache web server.
* Automated SSL test execution.

## Screenshot

![Screenshot from 2024-02-13 01-39-45](https://github.com/manzolo/multipass_ssl_certificate_management/assets/7722346/b82685b1-78f5-488e-9b78-86c45f420736)
