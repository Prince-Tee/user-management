#!/bin/bash

# Log file path
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Ensure the log directory exists
mkdir -p /var/log
mkdir -p /var/secure

# Log function to log actions
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Check if a user list file is provided as an argument
if [ -z "$1" ]; then
    log "No user list file provided."
    exit 1
fi

USER_LIST_FILE="$1"

# Read the user list file line by line
while IFS=";" read -r username groups; do
    # Remove leading/trailing whitespace
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    # Skip empty lines
    if [ -z "$username" ]; then
        continue
    fi

    # Check if the user already exists
    if id "$username" &>/dev/null; then
        log "User $username already exists."
    else
        # Create the user
        useradd -m -s /bin/bash "$username"
        log "User $username created."

        # Generate a random password
        password=$(openssl rand -base64 12)
        echo "$username:$password" | tee -a $PASSWORD_FILE
        echo "$username:$password" | chpasswd
        log "Password for user $username: $password"
    fi

    # Create a personal group for the user if it doesn't exist
    if ! getent group "$username" &>/dev/null; then
        groupadd "$username"
        log "Group $username created."
    fi

    # Add the user to their personal group
    usermod -aG "$username" "$username"

    # Add the user to additional groups if specified
    IFS=',' read -r -a group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        group=$(echo "$group" | xargs)  # Remove leading/trailing whitespace
        if ! getent group "$group" &>/dev/null; then
            groupadd "$group"
            log "Group $group created."
        fi
        usermod -aG "$group" "$username"
        log "User $username added to group $group."
    done

done < "$USER_LIST_FILE"

log "User creation completed."

