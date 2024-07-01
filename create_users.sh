#!/bin/bash

LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <user-list-file>"
    exit 1
fi

USER_LIST_FILE=$1

if [ ! -f "$USER_LIST_FILE" ]; then
    echo "User list file not found!"
    exit 1
fi

sudo mkdir -p /var/secure
sudo touch $PASSWORD_FILE
sudo chmod 600 $PASSWORD_FILE

while IFS=";" read -r username groups; do
    username=$(echo $username | xargs)
    groups=$(echo $groups | xargs)

    if id "$username" &>/dev/null; then
        echo "User $username already exists" | sudo tee -a $LOG_FILE
        continue
    fi

    sudo useradd -m -G $groups -s /bin/bash $username
    sudo groupadd $username
    sudo usermod -aG $username $username
    password=$(openssl rand -base64 12)
    echo "$username:$password" | sudo tee -a $PASSWORD_FILE
    echo "$username:$password" | sudo chpasswd
    echo "User $username created and added to groups $groups" | sudo tee -a $LOG_FILE

done < $USER_LIST_FILE

echo "User creation completed" | sudo tee -a $LOG_FILE

