#!/bin/bash

##############################################################################################################################
# ENV VARS:
CA_SUBJ="/C=IT/ST=Italy/L=Scarperia e San Piero/O=Manzolo/OU=Manzolo CA"

##############################################################################################################################

vms=("ca-vm" "server-ssl" "client-ssl")

# Funzione per stampare un messaggio colorato
print_message() {
    local color="\e[0;33m"  # Colore arancione
    local message="$1"       # Messaggio da stampare
    echo -e "${color}${message}\e[0m"  # Stampare il messaggio con il colore
}

# Funzione per gestire gli errori
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