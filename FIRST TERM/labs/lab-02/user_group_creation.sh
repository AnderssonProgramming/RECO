#!/bin/bash
# ===========================================================
# Script: user_group_creation.sh
# Description: Create users, groups, and set permissions
# Usage:
#   ./user_group_creation.sh newgroup group_name group_ID
#   ./user_group_creation.sh newuser username group "description" home_directory shell user_perm group_perm other_perm
# ===========================================================

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root!"
   exit 1
fi

# Function to create a new group
newgroup() {
    local group_name=$1
    local group_id=$2

    if getent group "$group_name" >/dev/null; then
        echo "Group '$group_name' already exists."
    else
        groupadd -g "$group_id" "$group_name"
        echo "Group '$group_name' created with GID $group_id."
    fi
}

# Function to create a new user
newuser() {
    local username=$1
    local group=$2
    local description=$3
    local home_directory=$4
    local shell=$5
    local user_perm=$6
    local group_perm=$7
    local other_perm=$8

    # Ensure group exists
    if ! getent group "$group" >/dev/null; then
        echo "Group '$group' does not exist. Creating..."
        groupadd "$group"
    fi

    # Create home directory if not exists
    if [ ! -d "$home_directory" ]; then
        mkdir -p "$home_directory"
        echo "Home directory $home_directory created."
    fi

    # Create the user
    if id "$username" &>/dev/null; then
        echo "User '$username' already exists."
    else
        useradd -m -d "$home_directory" -c "$description" -g "$group" -s "$shell" "$username"
        echo "User '$username' created and added to group '$group'."
        passwd "$username"
    fi

    # Set permissions on home directory
    chmod "$user_perm""$group_perm""$other_perm" "$home_directory"
    chown "$username:$group" "$home_directory"
    echo "Permissions set to $user_perm$group_perm$other_perm on $home_directory"
}

# ===========================================================
# Main program dispatcher
# ===========================================================
case $1 in
    newgroup)
        shift
        newgroup "$@"
        ;;
    newuser)
        shift
        newuser "$@"
        ;;
    *)
        echo "Usage:"
        echo "  $0 newgroup group_name group_ID"
        echo "  $0 newuser username group \"description\" home_directory shell user_perm group_perm other_perm"
        exit 1
        ;;
esac
