#!/bin/bash

LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then echo "Usage: $0 <user-list-file>" exit 1 fi

USER_LIST_FILE=$1

# Check if the user list file exists
if [ ! -f "$USER_LIST_FILE" ]; then echo "User list file not found!" 
    exit 1
fi

# Ensure log and password directories exist
sudo mkdir -p /var/log /var/secure sudo touch $PASSWORD_FILE sudo chmod 
600 $PASSWORD_FILE

# Read the user list file line by line
while IFS=";" read -r username groups; do username=$(echo $username | 
    xargs) groups=$(echo $groups | xargs)

    # Check if the user already exists
    if id "$username" &>/dev/null; then echo "$(date '+%Y-%m-%d 
        %H:%M:%S') - User $username already exists" | sudo tee -a 
        $LOG_FILE continue fi

    # Create user and bash shell
    sudo useradd -m -s /bin/bash $username if [ $? -eq 0 ]; then echo 
        "$(date '+%Y-%m-%d %H:%M:%S') - User $username created" | sudo 
        tee -a $LOG_FILE
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Failed to create user $username" | sudo tee -a $LOG_FILE
        continue
    fi

    # Create personal group for the user
    sudo groupadd $username
    sudo usermod -aG $username $username
    if [ $? -eq 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Group $username created and user added to it" | sudo tee -a $LOG_FILE
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Failed to create group $username or add user to it" | sudo tee -a $LOG_FILE
    fi

    # Create specified groups and add user to them
    IFS=',' read -r -a group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        group=$(echo $group | xargs)
        if ! getent group $group > /dev/null 2>&1; then
            sudo groupadd $group
            if [ $? -eq 0 ]; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Group $group created" | sudo tee -a $LOG_FILE
            else
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Failed to create group $group" | sudo tee -a $LOG_FILE
                continue
            fi
        fi
        sudo usermod -aG $group $username
        if [ $? -eq 0 ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - User $username added to group $group" | sudo tee -a $LOG_FILE
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Failed to add user $username to group $group" | sudo tee -a $LOG_FILE
        fi
    done

    # Generate password for the user
    password=$(openssl rand -base64 12)
    echo "$username:$password" | sudo chpasswd
    if [ $? -eq 0 ]; then
        echo "$username,$password" | sudo tee -a $PASSWORD_FILE
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Password for user $username set" | sudo tee -a $LOG_FILE
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Failed to set password for user $username" | sudo tee -a $LOG_FILE
    fi

done < $USER_LIST_FILE

echo "$(date '+%Y-%m-%d %H:%M:%S') - User creation process completed" | sudo tee -a $LOG_FILE

