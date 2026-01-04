#!/bin/bash
# ============================================================
# Script Name: file_search_menu.sh
# Location: /usr/local/bin/
# Author: Andersson
# Description:
#   This script provides a menu-driven interface to perform
#   file search and viewing operations:
#     1. Search for files by name/part of name.
#     2. Search for words inside a file.
#     3. Search for files and then search for a word in them.
#     4. Count the number of lines in a file.
#     5. Show the first N lines of a file.
#     6. Show the last N lines of a file.
#   Results are paginated with 'less' when appropriate.
#
# Usage:
#   chmod +x /usr/local/bin/file_search_menu.sh
#   /usr/local/bin/file_search_menu.sh
# ============================================================

# 1) Search for file by name/part of name
search_file_by_name() {
    clear
    read -p "Enter the path to search in: " PATH_TO_SEARCH
    read -p "Enter file name or part of name: " FILENAME
    echo ">>> Searching for files containing '$FILENAME' in '$PATH_TO_SEARCH'..."
    RESULTS=$(find "$PATH_TO_SEARCH" -type f -name "*$FILENAME*")
    echo "$RESULTS" | less
    echo
    COUNT=$(echo "$RESULTS" | wc -l)
    echo "Total files found: $COUNT"
    read -p "Press ENTER to return to menu..."
}

# 2) Search for a word in a given file
search_word_in_file() {
    clear
    read -p "Enter the file path: " FILE
    if [ ! -f "$FILE" ]; then
        echo "Error: File not found!"
        sleep 2
        return
    fi
    read -p "Enter the word/part of word to search: " WORD
    echo ">>> Searching for '$WORD' in $FILE..."
    grep -n "$WORD" "$FILE" | less
    COUNT=$(grep -c "$WORD" "$FILE")
    echo "Total occurrences found: $COUNT"
    read -p "Press ENTER to return to menu..."
}

# 3) Search for file, then for a word inside it
search_file_and_word() {
    clear
    read -p "Enter the path to search in: " PATH_TO_SEARCH
    read -p "Enter file name or part of name: " FILENAME
    FILES=$(find "$PATH_TO_SEARCH" -type f -name "*$FILENAME*")
    if [ -z "$FILES" ]; then
        echo "No files found."
        sleep 2
        return
    fi
    read -p "Enter the word to search inside the found files: " WORD
    for f in $FILES; do
        echo ">>> Searching in file: $f"
        grep -n "$WORD" "$f"
        COUNT=$(grep -c "$WORD" "$f")
        echo "Occurrences in $f: $COUNT"
        echo "---------------------------------"
    done | less
    read -p "Press ENTER to return to menu..."
}

# 4) Count number of lines in a file
count_lines() {
    clear
    read -p "Enter the file path: " FILE
    if [ ! -f "$FILE" ]; then
        echo "Error: File not found!"
        sleep 2
        return
    fi
    LINES=$(wc -l < "$FILE")
    echo "The file '$FILE' has $LINES lines."
    read -p "Press ENTER to return to menu..."
}

# 5) Show first N lines of a file
show_first_lines() {
    clear
    read -p "Enter the file path: " FILE
    if [ ! -f "$FILE" ]; then
        echo "Error: File not found!"
        sleep 2
        return
    fi
    read -p "Enter the number of lines: " N
    echo ">>> Showing first $N lines of $FILE:"
    head -n "$N" "$FILE" | less
    read -p "Press ENTER to return to menu..."
}

# 6) Show last N lines of a file
show_last_lines() {
    clear
    read -p "Enter the file path: " FILE
    if [ ! -f "$FILE" ]; then
        echo "Error: File not found!"
        sleep 2
        return
    fi
    read -p "Enter the number of lines: " N
    echo ">>> Showing last $N lines of $FILE:"
    tail -n "$N" "$FILE" | less
    read -p "Press ENTER to return to menu..."
}

# ============ Main Program ============
while true; do
    clear
    echo "======================================="
    echo "  File Search and Viewing Menu"
    echo "======================================="
    echo "1) Search for file by name"
    echo "2) Search for word in file"
    echo "3) Search file and then word inside it"
    echo "4) Count lines in file"
    echo "5) Show first N lines"
    echo "6) Show last N lines"
    echo "7) Exit"
    echo "======================================="
    read -p "Choose an option [1-7]: " OPT

    case $OPT in
        1) search_file_by_name ;;
        2) search_word_in_file ;;
        3) search_file_and_word ;;
        4) count_lines ;;
        5) show_first_lines ;;
        6) show_last_lines ;;
        7) echo "Exiting..."; break ;;
        *) echo "Invalid option, try again." ; sleep 1 ;;
    esac
done
