#!/bin/bash

# Function for command selection
select_command() {
    while true; do
        OPTION=$(whiptail --title "Certificate Management" --menu "Select a command:" 20 70 13 \
        "Create VM" "Create VM" \
        "Start VM" "Start VM" \
        "Stop VM" "Stop VM" \
        "Destroy VM" "Destroy VM" \
        "Exit" "Exit the program" 3>&1 1>&2 2>&3)

        if [ $? -eq 0 ]; then
            case $OPTION in
                "Create VM")
                    ./setup.sh || echo "Error during execution of setup.sh"
                    ;;
                "Start VM")
                    multipass start ca-vm || echo "Error starting ca-vm"
                    multipass start server-ssl || echo "Error starting server-ssl"
                    multipass start client-ssl || echo "Error starting client-ssl"
                    ;;
                "Stop VM")
                    multipass stop ca-vm || echo "Error stopping ca-vm"
                    multipass stop server-ssl || echo "Error stopping server-ssl"
                    multipass stop client-ssl || echo "Error stopping client-ssl"
                    ;;
                "Destroy VM")
                    ./destroy.sh || echo "Error during execution of destroy.sh"
                    ;;
                "Exit")
                    echo "Exiting..."
                    break
                    ;;
                *)
                    echo "Invalid choice."
                    ;;
            esac
        else
            echo "Exiting..."
            break
        fi
    done
}

# Execute the function
select_command
