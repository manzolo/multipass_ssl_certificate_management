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

check_error "Stopping and removing existing VMs"

cleanup_files
