#!/bin/bash

# =============================================================================
# SOLARIS USER AND GROUP CREATION SCRIPT
# =============================================================================
# Description: Script to create users and groups in Solaris
# Usage: 
#   newuser name group description directory shell user_perm group_perm other_perm
#   newgroup group_name group_ID
# =============================================================================

# Function to display usage information
usage() {
    echo "Usage:"
    echo "  $0 newuser <name> <group> <description> <directory> <shell> <user_perm> <group_perm> <other_perm>"
    echo "  $0 newgroup <group_name> <group_ID>"
    echo ""
    echo "Examples:"
    echo "  $0 newgroup finance 1001"
    echo "  $0 newuser ander finance \"Systems Engineering student\" /usuarios/ander /bin/bash 7 5 0"
    exit 1
}

# Function to create a new group
create_group() {
    local group_name=$1
    local group_id=$2
    
    # Validate parameters
    if [ -z "$group_name" ] || [ -z "$group_id" ]; then
        echo "ERROR: Group name and group ID are required"
        usage
    fi
    
    # Check if group already exists
    if getent group "$group_name" > /dev/null 2>&1; then
        echo "ERROR: Group '$group_name' already exists"
        exit 1
    fi
    
    # Check if group ID is already in use
    if getent group "$group_id" > /dev/null 2>&1; then
        echo "ERROR: Group ID '$group_id' is already in use"
        exit 1
    fi
    
    # Create the group using groupadd (Solaris command)
    echo "Creating group '$group_name' with GID $group_id..."
    
    if groupadd -g "$group_id" "$group_name"; then
        echo "SUCCESS: Group '$group_name' created successfully with GID $group_id"
        echo "Verification: $(getent group $group_name)"
    else
        echo "ERROR: Failed to create group '$group_name'"
        exit 1
    fi
}

# Function to create a new user
create_user() {
    local username=$1
    local group_name=$2
    local description=$3
    local home_dir=$4
    local shell=$5
    local user_perm=$6
    local group_perm=$7
    local other_perm=$8
    
    # Validate parameters
    if [ $# -ne 8 ]; then
        echo "ERROR: All 8 parameters are required for user creation"
        usage
    fi
    
    # Check if user already exists
    if id "$username" > /dev/null 2>&1; then
        echo "ERROR: User '$username' already exists"
        exit 1
    fi
    
    # Check if group exists
    if ! getent group "$group_name" > /dev/null 2>&1; then
        echo "ERROR: Group '$group_name' does not exist. Create it first."
        exit 1
    fi
    
    # Create home directory if it doesn't exist
    home_parent=$(dirname "$home_dir")
    if [ ! -d "$home_parent" ]; then
        echo "Creating parent directory: $home_parent"
        mkdir -p "$home_parent"
    fi
    
    # Create the user using useradd (Solaris command)
    echo "Creating user '$username'..."
    echo "  Group: $group_name"
    echo "  Description: $description"
    echo "  Home directory: $home_dir"
    echo "  Shell: $shell"
    
    # In Solaris, useradd syntax:
    # -g: primary group
    # -c: comment/description
    # -d: home directory
    # -s: shell
    # -m: create home directory
    
    if useradd -g "$group_name" -c "$description" -d "$home_dir" -s "$shell" -m "$username"; then
        echo "SUCCESS: User '$username' created successfully"
        
        # Set directory permissions
        local perm_string="${user_perm}${group_perm}${other_perm}"
        echo "Setting directory permissions to $perm_string for $home_dir"
        
        if chmod "$perm_string" "$home_dir"; then
            echo "SUCCESS: Permissions set to $perm_string for $home_dir"
        else
            echo "WARNING: Failed to set permissions for $home_dir"
        fi
        
        # Change ownership of home directory
        if chown "$username:$group_name" "$home_dir"; then
            echo "SUCCESS: Ownership set to $username:$group_name for $home_dir"
        else
            echo "WARNING: Failed to set ownership for $home_dir"
        fi
        
        # Display user information
        echo ""
        echo "User Information:"
        echo "$(id $username)"
        echo "Home directory: $(ls -ld $home_dir)"
        
    else
        echo "ERROR: Failed to create user '$username'"
        exit 1
    fi
}

# Main script logic
if [ $# -lt 2 ]; then
    echo "ERROR: Insufficient arguments"
    usage
fi

case "$1" in
    "newgroup")
        if [ $# -ne 3 ]; then
            echo "ERROR: newgroup requires exactly 2 parameters"
            usage
        fi
        create_group "$2" "$3"
        ;;
    "newuser")
        if [ $# -ne 9 ]; then
            echo "ERROR: newuser requires exactly 8 parameters"
            usage
        fi
        create_user "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
        ;;
    *)
        echo "ERROR: Invalid command '$1'"
        usage
        ;;
esac

exit 0
