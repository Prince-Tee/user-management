# User Management Script

This script automates the process of creating users and assigning them to specified groups on a Linux system based on a provided user list file. 

## Prerequisites

- Ensure you have superuser (root) privileges to run this script, as it requires permissions to create users and groups.
- Make sure you have the necessary tools installed, such as `useradd` and `groupadd`.

## Script Overview

The script performs the following tasks:
1. Reads a user list file containing usernames and their corresponding groups.
2. Creates users and assigns them to the specified groups.
3. Sets up home directories with appropriate permissions and ownership.
4. Generates random passwords for the users.
5. Logs all actions to `/var/log/user_management.log`.
6. Stores the generated passwords securely in `/var/secure/user_passwords.csv`.

## Usage

1. **Create the User List File**

   You need to create a file named `users.txt` that contains the list of users and their groups. This file should be in the same directory as the `create_users.sh` script.

2. **User List File Format**

   Each line in the user list file should be formatted as follows:

   ```plaintext
   username;group1,group2,group3
