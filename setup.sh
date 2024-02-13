#!/bin/bash

CMD_PATH=$(dirname $0)
source $CMD_PATH/script/_utils.sh

print_message "Using CA Subject: $CA_SUBJ"
echo

# Stop and remove existing VMs
print_message "Stopping and removing existing VMs..."

for vm in "${vms[@]}"; do
    multipass stop $vm
    multipass delete $vm
done

multipass purge

check_error "Stopping and removing existing VMs"

cleanup_files

# Create VM for the private CA
print_message "Creating VM for the private CA, please wait..."
bash $CMD_PATH/script/_setup_ca_vm.sh > $CMD_PATH/ca_vm.log 2>&1

# Create VM for SSL testing
print_message "Creating VM for SSL testing, please wait..."
bash $CMD_PATH/script/_setup_server_ssl.sh > $CMD_PATH/server_ssl_vm.log 2>&1

# Create client-ssl VM
print_message "Creating client-ssl VM, please wait..."
bash $CMD_PATH/script/_setup_client_ssl.sh > $CMD_PATH/client_ssl_vm.log 2>&1

#bash $CMD_PATH/script/_setup_client_ssl.sh > $CMD_PATH/client_ssl_vm.log 2>&1 &
#show_spinner $!

print_message "Done! VMs have been created and configured for use with private CA and SSL certificates."

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
