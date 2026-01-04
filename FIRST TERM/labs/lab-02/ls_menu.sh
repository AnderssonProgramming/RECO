#!/bin/bash
# ============================================================
# Script Name: ls_menu.sh
# Location: /usr/local/bin/
# Author: Andersson
# Description:
#   This script provides a menu-based interface to list files
#   in a directory (including hidden ones) with various filters:
#   - Sort by most recent, oldest, size, or file type.
#   - Group results by quantity (same date, same size, same type).
#   - Apply conditions: starts with, ends with, or contains a string.
#
# Requirements:
#   - Must run in Slackware with standard bash utilities (ls, find, sort, awk).
#   - Output should be paginated if too long (via 'less').
#
# Usage:
#   chmod +x /usr/local/bin/ls_menu.sh
#   /usr/local/bin/ls_menu.sh
# ============================================================

# Function to list files by most recent modification date
list_most_recent() {
    clear
    echo ">>> Files sorted by most recent modification:"
    ls -lt "$DIR" | less
    echo
    echo "Grouped by date:"
    ls -lt "$DIR" | awk '{print $6, $7, $8}' | sort | uniq -c
    read -p "Press ENTER to return to menu..."
}

# Function to list files by oldest modification date
list_oldest() {
    clear
    echo ">>> Files sorted by oldest modification:"
    ls -lst "$DIR" | less
    echo
    echo "Grouped by date:"
    ls -lst "$DIR" | awk '{print $6, $7, $8}' | sort | uniq -c
    read -p "Press ENTER to return to menu..."
}

# Function to list files largest to smallest
list_largest() {
    clear#
    echo ">>> Files sorted by size (largest first):"
    ls -laS "$DIR" | less
    echo
    echo "Grouped by size:"
    ls -laS "$DIR" | awk '{print $5}' | sort -nr | uniq -c
    read -p "Press ENTER to return to menu..."
}

# Function to list files smallest to largest
list_smallest() {
    clear
    echo ">>> Files sorted by size (smallest first):"
    ls -laSr "$DIR" | less
    echo
    echo "Grouped by size:"
    ls -laSr "$DIR" | awk '{print $5}' | sort -n | uniq -c
    read -p "Press ENTER to return to menu..."
}

# Function to group files by type
list_by_type() {
    clear
    echo ">>> Files grouped by type:"
    find "$DIR" -maxdepth 1 -exec file --brief --mime-type {} \; | sort | uniq -c
    echo
    echo "Files and directories separately:"
    echo "Files: $(find "$DIR" -maxdepth 1 -type f | wc -l)"
    echo "Directories: $(find "$DIR" -maxdepth 1 -type d | wc -l)"
    read -p "Press ENTER to return to menu..."
}

# Function to filter files starting with a string
start_with() {
    clear
    read -p "Enter the starting string: " STR
    echo ">>> Files starting with '$STR':"
    find "$DIR" -type f -name "${STR}*" | less
    read -p "Press ENTER to return to menu..."
}

# Function to filter files ending with a string
end_with() {
    clear
    read -p "Enter the ending string: " STR
    echo ">>> Files ending with '$STR':"
    find "$DIR" -type f -name "*${STR}" | less
    read -p "Press ENTER to return to menu..."
}

# Function to filter files containing a string
contain_string() {
    clear
    read -p "Enter the contained string: " STR
    echo ">>> Files containing '$STR':"
    find "$DIR" -type f -name "*${STR}*" | less
    read -p "Press ENTER to return to menu..."
}

# ============ Main Program ============

clear
read -p "Enter the directory path: " DIR

# Validate directory
if [ ! -d "$DIR" ]; then
    echo "Error: '$DIR' is not a valid directory."
    exit 1
fi

while true; do
    clear
    echo "======================================="
    echo "     LS Command Menu for $DIR"
    echo "======================================="
    echo "1) List by most recent (with grouping)"
    echo "2) List by oldest (with grouping)"
    echo "3) List by size (largest to smallest)"
    echo "4) List by size (smallest to largest)"
    echo "5) Group by file type"
    echo "6) Filter: starts with string"
    echo "7) Filter: ends with string"
    echo "8) Filter: contains string"
    echo "9) Exit"
    echo "======================================="
    read -p "Choose an option [1-9]: " OPT

    case $OPT in
        1) list_most_recent ;;
        2) list_oldest ;;
        3) list_largest ;;
        4) list_smallest ;;
        5) list_by_type ;;
        6) start_with ;;
        7) end_with ;;
        8) contain_string ;;
        9) echo "Exiting..."; break ;;
        *) echo "Invalid option, try again." ; sleep 1 ;;
    esac
done
