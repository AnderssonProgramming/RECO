#!/bin/sh

#############################################################################
# File Search or Viewing Commands Script for Solaris
# Description: Advanced file search and viewing utilities
# Author: Shell Programming Project
# Date: $(date)
# Version: 1.0
#
# Features:
# - Search for files by name/partial name
# - Search for words in files with line numbers and counts
# - Combined file and word search
# - Count lines in files
# - Show first n lines of files
# - Show last n lines of files
#############################################################################

#############################################################################
# Function: display_header
# Description: Shows the script title and clears screen
#############################################################################
display_header() {
    clear
    echo "=================================================================="
    echo "           FILE SEARCH AND VIEWING COMMANDS - SOLARIS"
    echo "=================================================================="
    echo ""
}

#############################################################################
# Function: search_files_by_name
# Description: Search for files by name or partial name
#############################################################################
search_files_by_name() {
    display_header
    echo "SEARCH FOR FILES BY NAME"
    echo "========================"
    echo ""
    
    echo "Enter the search path (or press Enter for current directory):"
    echo -n "> "
    read search_path
    
    if [ -z "$search_path" ]; then
        search_path="."
    fi
    
    if [ ! -d "$search_path" ]; then
        echo "ERROR: Directory '$search_path' does not exist!"
        return
    fi
    
    echo "Enter the file name or partial name to search for:"
    echo -n "> "
    read filename
    
    if [ -z "$filename" ]; then
        echo "ERROR: Please enter a filename to search for!"
        return
    fi
    
    echo ""
    echo "Searching for files containing '$filename' in '$search_path'..."
    echo "=============================================================="
    echo ""
    
    # Create temporary file to store results
    temp_results="/tmp/search_results_$$"
    
    # Search for files using find command
    find "$search_path" -name "*$filename*" -type f 2>/dev/null > "$temp_results"
    find "$search_path" -name "*$filename*" -type d 2>/dev/null | sed 's/$/\//' >> "$temp_results"
    
    # Count results and display
    file_count=$(wc -l < "$temp_results")
    
    if [ "$file_count" -eq 0 ]; then
        echo "No files found matching '$filename' in '$search_path'"
    else
        echo "FOUND FILES:"
        echo "============"
        sort "$temp_results" | nl -w3 -s'. '
        echo ""
        echo "-> Total files found: $file_count"
    fi
    
    # Cleanup
    rm -f "$temp_results"
}

#############################################################################
# Function: search_word_in_file
# Description: Search for word/partial word in a given file
#############################################################################
search_word_in_file() {
    display_header
    echo "SEARCH FOR WORD IN FILE"
    echo "======================="
    echo ""
    
    echo "Enter the file path:"
    echo -n "> "
    read file_path
    
    if [ ! -f "$file_path" ]; then
        echo "ERROR: File '$file_path' does not exist or is not a regular file!"
        return
    fi
    
    echo "Enter the word or partial word to search for:"
    echo -n "> "
    read search_word
    
    if [ -z "$search_word" ]; then
        echo "ERROR: Please enter a word to search for!"
        return
    fi
    
    echo ""
    echo "Searching for '$search_word' in '$file_path'..."
    echo "================================================"
    echo ""
    
    # Search for word and show results with line numbers
    temp_grep="/tmp/grep_results_$$"
    grep -n -i "$search_word" "$file_path" > "$temp_grep" 2>/dev/null
    
    # Count occurrences
    word_count=$(grep -o -i "$search_word" "$file_path" 2>/dev/null | wc -l)
    line_count=$(wc -l < "$temp_grep")
    
    if [ "$line_count" -eq 0 ]; then
        echo "No occurrences of '$search_word' found in '$file_path'"
    else
        echo "FOUND LINES:"
        echo "============"
        cat "$temp_grep"
        echo ""
        echo "-> Lines containing the word: $line_count"
        echo "-> Total word occurrences: $word_count"
    fi
    
    # Cleanup
    rm -f "$temp_grep"
}

#############################################################################
# Function: search_files_and_word
# Description: Search for files, then search for word in found files
#############################################################################
search_files_and_word() {
    display_header
    echo "SEARCH FILES AND WORD COMBINATION"
    echo "================================="
    echo ""
    
    echo "Enter the search path (or press Enter for current directory):"
    echo -n "> "
    read search_path
    
    if [ -z "$search_path" ]; then
        search_path="."
    fi
    
    if [ ! -d "$search_path" ]; then
        echo "ERROR: Directory '$search_path' does not exist!"
        return
    fi
    
    echo "Enter the file name pattern to search for:"
    echo -n "> "
    read filename_pattern
    
    if [ -z "$filename_pattern" ]; then
        echo "ERROR: Please enter a filename pattern!"
        return
    fi
    
    echo "Enter the word to search for inside the files:"
    echo -n "> "
    read search_word
    
    if [ -z "$search_word" ]; then
        echo "ERROR: Please enter a word to search for!"
        return
    fi
    
    echo ""
    echo "Searching for '$search_word' in files matching '$filename_pattern' in '$search_path'..."
    echo "======================================================================================"
    echo ""
    
    # Find files matching pattern
    temp_files="/tmp/found_files_$$"
    find "$search_path" -name "*$filename_pattern*" -type f 2>/dev/null > "$temp_files"
    
    file_count=$(wc -l < "$temp_files")
    
    if [ "$file_count" -eq 0 ]; then
        echo "No files found matching '$filename_pattern' in '$search_path'"
        rm -f "$temp_files"
        return
    fi
    
    total_word_count=0
    files_with_word=0
    
    # Search for word in each found file
    while read file; do
        if [ -r "$file" ]; then
            word_occurrences=$(grep -c -i "$search_word" "$file" 2>/dev/null)
            if [ "$word_occurrences" -gt 0 ]; then
                files_with_word=$((files_with_word + 1))
                total_word_count=$((total_word_count + word_occurrences))
                
                echo "FILE: $file"
                echo "$(echo "$file" | sed 's/./=/g')"
                grep -n -i "$search_word" "$file" 2>/dev/null
                echo "-> Occurrences in this file: $word_occurrences"
                echo ""
            fi
        fi
    done < "$temp_files"
    
    if [ "$files_with_word" -eq 0 ]; then
        echo "Word '$search_word' not found in any of the $file_count files matching '$filename_pattern'"
    else
        echo "SUMMARY:"
        echo "========"
        echo "Files searched: $file_count"
        echo "Files containing '$search_word': $files_with_word"
        echo "Total word occurrences: $total_word_count"
    fi
    
    # Cleanup
    rm -f "$temp_files"
}

#############################################################################
# Function: count_lines_in_file
# Description: Count number of lines in a file
#############################################################################
count_lines_in_file() {
    display_header
    echo "COUNT LINES IN FILE"
    echo "==================="
    echo ""
    
    echo "Enter the file path:"
    echo -n "> "
    read file_path
    
    if [ ! -f "$file_path" ]; then
        echo "ERROR: File '$file_path' does not exist or is not a regular file!"
        return
    fi
    
    # Count lines
    line_count=$(wc -l < "$file_path")
    
    echo ""
    echo "FILE: $file_path"
    echo "$(echo "$file_path" | sed 's/./=/g')"
    echo "Number of lines: $line_count"
    
    # Additional information
    word_count=$(wc -w < "$file_path")
    char_count=$(wc -c < "$file_path")
    
    echo ""
    echo "Additional statistics:"
    echo "- Lines: $line_count"
    echo "- Words: $word_count"
    echo "- Characters: $char_count"
}

#############################################################################
# Function: show_first_lines
# Description: Show first n lines of a file
#############################################################################
show_first_lines() {
    display_header
    echo "SHOW FIRST N LINES OF FILE"
    echo "=========================="
    echo ""
    
    echo "Enter the file path:"
    echo -n "> "
    read file_path
    
    if [ ! -f "$file_path" ]; then
        echo "ERROR: File '$file_path' does not exist or is not a regular file!"
        return
    fi
    
    echo "Enter the number of lines to show:"
    echo -n "> "
    read num_lines
    
    # Validate number
    case "$num_lines" in
        ''|*[!0-9]*)
            echo "ERROR: Please enter a valid positive number!"
            return
            ;;
    esac
    
    if [ "$num_lines" -le 0 ]; then
        echo "ERROR: Number of lines must be greater than 0!"
        return
    fi
    
    echo ""
    echo "FIRST $num_lines LINES OF: $file_path"
    echo "$(echo "FIRST $num_lines LINES OF: $file_path" | sed 's/./=/g')"
    echo ""
    
    head -n "$num_lines" "$file_path" | nl -w3 -s'. '
    
    total_lines=$(wc -l < "$file_path")
    echo ""
    echo "-> Showing first $num_lines lines of $total_lines total lines"
}

#############################################################################
# Function: show_last_lines
# Description: Show last n lines of a file
#############################################################################
show_last_lines() {
    display_header
    echo "SHOW LAST N LINES OF FILE"
    echo "========================="
    echo ""
    
    echo "Enter the file path:"
    echo -n "> "
    read file_path
    
    if [ ! -f "$file_path" ]; then
        echo "ERROR: File '$file_path' does not exist or is not a regular file!"
        return
    fi
    
    echo "Enter the number of lines to show:"
    echo -n "> "
    read num_lines
    
    # Validate number
    case "$num_lines" in
        ''|*[!0-9]*)
            echo "ERROR: Please enter a valid positive number!"
            return
            ;;
    esac
    
    if [ "$num_lines" -le 0 ]; then
        echo "ERROR: Number of lines must be greater than 0!"
        return
    fi
    
    echo ""
    echo "LAST $num_lines LINES OF: $file_path"
    echo "$(echo "LAST $num_lines LINES OF: $file_path" | sed 's/./=/g')"
    echo ""
    
    tail -n "$num_lines" "$file_path" | nl -w3 -s'. '
    
    total_lines=$(wc -l < "$file_path")
    echo ""
    echo "-> Showing last $num_lines lines of $total_lines total lines"
}

#############################################################################
# Function: show_menu
# Description: Display main menu
#############################################################################
show_menu() {
    echo "=================================================================="
    echo "                        MAIN MENU"
    echo "=================================================================="
    echo ""
    echo "  1) Search for files by name/partial name"
    echo "  2) Search for word in a specific file"
    echo "  3) Search files and word combination"
    echo "  4) Count lines in a file"
    echo "  5) Show first n lines of a file"
    echo "  6) Show last n lines of a file"
    echo "  q) Quit"
    echo ""
    echo -n "Select an option: "
}

#############################################################################
# Function: wait_for_user
# Description: Wait for user input to continue
#############################################################################
wait_for_user() {
    echo ""
    echo "Press Enter to continue..."
    read dummy
}

#############################################################################
# Function: main
# Description: Main program loop
#############################################################################
main() {
    while true; do
        display_header
        show_menu
        read choice
        
        case "$choice" in
            1)
                search_files_by_name
                wait_for_user
                ;;
            2)
                search_word_in_file
                wait_for_user
                ;;
            3)
                search_files_and_word
                wait_for_user
                ;;
            4)
                count_lines_in_file
                wait_for_user
                ;;
            5)
                show_first_lines
                wait_for_user
                ;;
            6)
                show_last_lines
                wait_for_user
                ;;
            q|Q)
                display_header
                echo "Thank you for using File Search and Viewing Commands!"
                echo "Goodbye!"
                echo ""
                exit 0
                ;;
            *)
                echo "Invalid option. Please try again."
                sleep 1
                ;;
        esac
    done
}

#############################################################################
# Script execution starts here
#############################################################################

# Cleanup temporary files on exit
trap 'rm -f /tmp/search_results_$$ /tmp/grep_results_$$ /tmp/found_files_$$' EXIT

# Start main program
main
