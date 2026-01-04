#!/bin/sh

#############################################################################
# Enhanced ls Command Script for Solaris
# Description: Advanced file listing with sorting, grouping, and filtering
# Author: Shell Programming Project
# Date: $(date)
# Version: 1.0
#
# Features:
# - List files with various sorting options
# - Count files by different parameters (date, size, type)
# - Filter by filename patterns (start, end, contain)
# - Support for subdirectories
# - Interactive menu system
# - Pagination for large results
#############################################################################

# Global variables
SCRIPT_DIR=""
INCLUDE_SUBDIRS="no"
FILTER_TYPE=""
FILTER_VALUE=""

#############################################################################
# Function: display_header
# Description: Shows the script title and clears screen
#############################################################################
display_header() {
    clear
    echo "=================================================================="
    echo "              ENHANCED LS COMMAND - SOLARIS"
    echo "=================================================================="
    echo ""
}

#############################################################################
# Function: get_directory
# Description: Prompts user for directory path and validates it
#############################################################################
get_directory() {
    while true; do
        echo "Please enter the directory path to analyze:"
        echo -n "> "
        read SCRIPT_DIR
        
        # Handle empty input (use current directory)
        if [ -z "$SCRIPT_DIR" ]; then
            SCRIPT_DIR="."
        fi
        
        # Validate directory exists
        if [ -d "$SCRIPT_DIR" ]; then
            echo "Directory selected: $SCRIPT_DIR"
            echo ""
            break
        else
            echo "ERROR: Directory '$SCRIPT_DIR' does not exist!"
            echo ""
        fi
    done
}

#############################################################################
# Function: ask_subdirectories
# Description: Asks user if they want to include subdirectories
#############################################################################
ask_subdirectories() {
    echo "Do you want to include subdirectories? (y/n)"
    echo -n "> "
    read response
    case "$response" in
        [Yy]|[Yy][Ee][Ss])
            INCLUDE_SUBDIRS="yes"
            echo "Including subdirectories in search."
            ;;
        *)
            INCLUDE_SUBDIRS="no"
            echo "Searching only in current directory."
            ;;
    esac
    echo ""
}

#############################################################################
# Function: set_filter
# Description: Sets filename filtering options
# Parameters: $1 = filter type (start|end|contain)
#############################################################################
set_filter() {
    FILTER_TYPE="$1"
    case "$1" in
        "start")
            echo "Enter the string that filenames should START with:"
            ;;
        "end")
            echo "Enter the string that filenames should END with:"
            ;;
        "contain")
            echo "Enter the string that filenames should CONTAIN:"
            ;;
    esac
    echo -n "> "
    read FILTER_VALUE
    echo "Filter set: Files must $1 with '$FILTER_VALUE'"
    echo ""
}

#############################################################################
# Function: get_file_list
# Description: Gets list of files based on current settings
#############################################################################
get_file_list() {
    temp_file="/tmp/filelist_$$"
    
    if [ "$INCLUDE_SUBDIRS" = "yes" ]; then
        # Use find for subdirectories (includes hidden files with -name '.*')
        find "$SCRIPT_DIR" \( -name ".*" -o -name "*" \) -type f -o -type d > "$temp_file" 2>/dev/null
    else
        # Use ls for current directory only (includes hidden files)
        ls -1a "$SCRIPT_DIR" 2>/dev/null | while read file; do
            if [ "$file" != "." ] && [ "$file" != ".." ]; then
                echo "$SCRIPT_DIR/$file"
            fi
        done > "$temp_file"
    fi
    
    # Apply filename filter if set
    if [ -n "$FILTER_TYPE" ] && [ -n "$FILTER_VALUE" ]; then
        temp_filtered="/tmp/filtered_$$"
        case "$FILTER_TYPE" in
            "start")
                grep "/[^/]*$FILTER_VALUE" "$temp_file" > "$temp_filtered"
                ;;
            "end")
                grep "$FILTER_VALUE$" "$temp_file" > "$temp_filtered"
                ;;
            "contain")
                grep "$FILTER_VALUE" "$temp_file" > "$temp_filtered"
                ;;
        esac
        mv "$temp_filtered" "$temp_file"
    fi
    
    echo "$temp_file"
}

#############################################################################
# Function: sort_by_date_recent
# Description: Sorts files by most recent date and shows count by date
#############################################################################
sort_by_date_recent() {
    display_header
    echo "FILES SORTED BY MOST RECENT DATE"
    echo "================================"
    echo ""
    
    file_list=$(get_file_list)
    
    # Create temporary file with file info
    temp_info="/tmp/fileinfo_$$"
    while read file; do
        if [ -e "$file" ]; then
            # Get file modification time and format it
            stat_info=$(ls -la "$file" 2>/dev/null | awk '{print $6" "$7" "$8}')
            echo "$stat_info|$file"
        fi
    done < "$file_list" > "$temp_info"
    
    # Sort by date (most recent first) and display with counts
    sort -t'|' -k1,1r "$temp_info" | {
        current_date=""
        count=0
        
        while IFS='|' read date_info file_path; do
            if [ "$date_info" != "$current_date" ]; then
                if [ $count -gt 0 ]; then
                    echo "  -> $count file(s) with date: $current_date"
                    echo ""
                fi
                current_date="$date_info"
                count=1
                echo "Date: $current_date"
                echo "----------------------------------------"
            else
                count=$((count + 1))
            fi
            
            basename_file=$(basename "$file_path")
            if [ -d "$file_path" ]; then
                echo "  [DIR]  $basename_file"
            else
                echo "  [FILE] $basename_file"
            fi
        done
        
        if [ $count -gt 0 ]; then
            echo "  -> $count file(s) with date: $current_date"
        fi
    } | more
    
    # Cleanup
    rm -f "$file_list" "$temp_info"
}

#############################################################################
# Function: sort_by_date_oldest
# Description: Sorts files by oldest date and shows count by date
#############################################################################
sort_by_date_oldest() {
    display_header
    echo "FILES SORTED BY OLDEST DATE"
    echo "==========================="
    echo ""
    
    file_list=$(get_file_list)
    
    # Create temporary file with file info
    temp_info="/tmp/fileinfo_$$"
    while read file; do
        if [ -e "$file" ]; then
            # Get file modification time and format it
            stat_info=$(ls -la "$file" 2>/dev/null | awk '{print $6" "$7" "$8}')
            echo "$stat_info|$file"
        fi
    done < "$file_list" > "$temp_info"
    
    # Sort by date (oldest first) and display with counts
    sort -t'|' -k1,1 "$temp_info" | {
        current_date=""
        count=0
        
        while IFS='|' read date_info file_path; do
            if [ "$date_info" != "$current_date" ]; then
                if [ $count -gt 0 ]; then
                    echo "  -> $count file(s) with date: $current_date"
                    echo ""
                fi
                current_date="$date_info"
                count=1
                echo "Date: $current_date"
                echo "----------------------------------------"
            else
                count=$((count + 1))
            fi
            
            basename_file=$(basename "$file_path")
            if [ -d "$file_path" ]; then
                echo "  [DIR]  $basename_file"
            else
                echo "  [FILE] $basename_file"
            fi
        done
        
        if [ $count -gt 0 ]; then
            echo "  -> $count file(s) with date: $current_date"
        fi
    } | more
    
    # Cleanup
    rm -f "$file_list" "$temp_info"
}

#############################################################################
# Function: sort_by_size_largest
# Description: Sorts files by largest size and shows count by size
#############################################################################
sort_by_size_largest() {
    display_header
    echo "FILES SORTED BY SIZE (LARGEST TO SMALLEST)"
    echo "=========================================="
    echo ""
    
    file_list=$(get_file_list)
    
    # Create temporary file with size info
    temp_info="/tmp/sizeinfo_$$"
    while read file; do
        if [ -e "$file" ]; then
            if [ -d "$file" ]; then
                echo "0|DIR|$file"
            else
                size=$(ls -la "$file" 2>/dev/null | awk '{print $5}')
                echo "$size|FILE|$file"
            fi
        fi
    done < "$file_list" > "$temp_info"
    
    # Sort by size (largest first) and display with counts
    sort -t'|' -k1,1nr "$temp_info" | {
        current_size=""
        count=0
        
        while IFS='|' read size_bytes type file_path; do
            if [ "$size_bytes" != "$current_size" ]; then
                if [ $count -gt 0 ]; then
                    if [ "$current_size" = "0" ]; then
                        echo "  -> $count item(s) with size: 0 bytes (directories)"
                    else
                        echo "  -> $count file(s) with size: $current_size bytes"
                    fi
                    echo ""
                fi
                current_size="$size_bytes"
                count=1
                if [ "$size_bytes" = "0" ]; then
                    echo "Size: 0 bytes (directories)"
                else
                    echo "Size: $size_bytes bytes"
                fi
                echo "----------------------------------------"
            else
                count=$((count + 1))
            fi
            
            basename_file=$(basename "$file_path")
            echo "  [$type] $basename_file"
        done
        
        if [ $count -gt 0 ]; then
            if [ "$current_size" = "0" ]; then
                echo "  -> $count item(s) with size: 0 bytes (directories)"
            else
                echo "  -> $count file(s) with size: $current_size bytes"
            fi
        fi
    } | more
    
    # Cleanup
    rm -f "$file_list" "$temp_info"
}

#############################################################################
# Function: sort_by_size_smallest
# Description: Sorts files by smallest size and shows count by size
#############################################################################
sort_by_size_smallest() {
    display_header
    echo "FILES SORTED BY SIZE (SMALLEST TO LARGEST)"
    echo "=========================================="
    echo ""
    
    file_list=$(get_file_list)
    
    # Create temporary file with size info
    temp_info="/tmp/sizeinfo_$$"
    while read file; do
        if [ -e "$file" ]; then
            if [ -d "$file" ]; then
                echo "0|DIR|$file"
            else
                size=$(ls -la "$file" 2>/dev/null | awk '{print $5}')
                echo "$size|FILE|$file"
            fi
        fi
    done < "$file_list" > "$temp_info"
    
    # Sort by size (smallest first) and display with counts
    sort -t'|' -k1,1n "$temp_info" | {
        current_size=""
        count=0
        
        while IFS='|' read size_bytes type file_path; do
            if [ "$size_bytes" != "$current_size" ]; then
                if [ $count -gt 0 ]; then
                    if [ "$current_size" = "0" ]; then
                        echo "  -> $count item(s) with size: 0 bytes (directories)"
                    else
                        echo "  -> $count file(s) with size: $current_size bytes"
                    fi
                    echo ""
                fi
                current_size="$size_bytes"
                count=1
                if [ "$size_bytes" = "0" ]; then
                    echo "Size: 0 bytes (directories)"
                else
                    echo "Size: $size_bytes bytes"
                fi
                echo "----------------------------------------"
            else
                count=$((count + 1))
            fi
            
            basename_file=$(basename "$file_path")
            echo "  [$type] $basename_file"
        done
        
        if [ $count -gt 0 ]; then
            if [ "$current_size" = "0" ]; then
                echo "  -> $count item(s) with size: 0 bytes (directories)"
            else
                echo "  -> $count file(s) with size: $current_size bytes"
            fi
        fi
    } | more
    
    # Cleanup
    rm -f "$file_list" "$temp_info"
}

#############################################################################
# Function: sort_by_type
# Description: Groups files by type (File/Directory) and shows counts
#############################################################################
sort_by_type() {
    display_header
    echo "FILES GROUPED BY TYPE"
    echo "===================="
    echo ""
    
    file_list=$(get_file_list)
    
    # Count files and directories
    file_count=0
    dir_count=0
    temp_files="/tmp/files_$$"
    temp_dirs="/tmp/dirs_$$"
    
    while read file; do
        if [ -e "$file" ]; then
            basename_file=$(basename "$file")
            if [ -d "$file" ]; then
                echo "$basename_file" >> "$temp_dirs"
                dir_count=$((dir_count + 1))
            else
                echo "$basename_file" >> "$temp_files"
                file_count=$((file_count + 1))
            fi
        fi
    done < "$file_list"
    
    {
        echo "DIRECTORIES ($dir_count items)"
        echo "=============================="
        if [ $dir_count -gt 0 ]; then
            sort "$temp_dirs" 2>/dev/null | while read dirname; do
                echo "  [DIR]  $dirname"
            done
        else
            echo "  No directories found."
        fi
        echo ""
        echo "  -> Total directories: $dir_count"
        echo ""
        
        echo "FILES ($file_count items)"
        echo "========================="
        if [ $file_count -gt 0 ]; then
            sort "$temp_files" 2>/dev/null | while read filename; do
                echo "  [FILE] $filename"
            done
        else
            echo "  No files found."
        fi
        echo ""
        echo "  -> Total files: $file_count"
        echo ""
        echo "SUMMARY"
        echo "======="
        echo "  Total directories: $dir_count"
        echo "  Total files: $file_count"
        echo "  Grand total: $((file_count + dir_count)) items"
    } | more
    
    # Cleanup
    rm -f "$file_list" "$temp_files" "$temp_dirs"
}

#############################################################################
# Function: show_menu
# Description: Displays the main menu options
#############################################################################
show_menu() {
    echo "=================================================================="
    echo "                        MAIN MENU"
    echo "=================================================================="
    echo "Current directory: $SCRIPT_DIR"
    echo "Include subdirectories: $INCLUDE_SUBDIRS"
    if [ -n "$FILTER_TYPE" ]; then
        echo "Active filter: Files that $FILTER_TYPE with '$FILTER_VALUE'"
    else
        echo "Active filter: None"
    fi
    echo ""
    echo "SORTING OPTIONS:"
    echo "  1) Sort by Most Recent Date"
    echo "  2) Sort by Oldest Date" 
    echo "  3) Sort by Size (Largest to Smallest)"
    echo "  4) Sort by Size (Smallest to Largest)"
    echo "  5) Group by Type (Files/Directories)"
    echo ""
    echo "FILTER OPTIONS:"
    echo "  6) Filter by files that START with string"
    echo "  7) Filter by files that END with string"
    echo "  8) Filter by files that CONTAIN string"
    echo "  9) Clear current filter"
    echo ""
    echo "SETTINGS:"
    echo "  s) Change directory"
    echo "  d) Toggle subdirectory inclusion"
    echo "  q) Quit"
    echo ""
    echo -n "Select an option: "
}

#############################################################################
# Function: wait_for_user
# Description: Waits for user to press Enter before continuing
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
    # Initial setup
    display_header
    echo "Welcome to the Enhanced ls Command Script!"
    echo ""
    
    # Get directory to work with
    get_directory
    ask_subdirectories
    
    # Main menu loop
    while true; do
        display_header
        show_menu
        read choice
        
        case "$choice" in
            1)
                sort_by_date_recent
                wait_for_user
                ;;
            2)
                sort_by_date_oldest
                wait_for_user
                ;;
            3)
                sort_by_size_largest
                wait_for_user
                ;;
            4)
                sort_by_size_smallest
                wait_for_user
                ;;
            5)
                sort_by_type
                wait_for_user
                ;;
            6)
                set_filter "start"
                ;;
            7)
                set_filter "end"
                ;;
            8)
                set_filter "contain"
                ;;
            9)
                FILTER_TYPE=""
                FILTER_VALUE=""
                echo "Filter cleared."
                echo ""
                ;;
            s|S)
                get_directory
                ask_subdirectories
                ;;
            d|D)
                if [ "$INCLUDE_SUBDIRS" = "yes" ]; then
                    INCLUDE_SUBDIRS="no"
                    echo "Subdirectories will NOT be included."
                else
                    INCLUDE_SUBDIRS="yes"
                    echo "Subdirectories WILL be included."
                fi
                echo ""
                ;;
            q|Q)
                display_header
                echo "Thank you for using Enhanced ls Command!"
                echo "Goodbye!"
                echo ""
                exit 0
                ;;
            *)
                echo "Invalid option. Please try again."
                echo ""
                ;;
        esac
    done
}

#############################################################################
# Script execution starts here
#############################################################################

# Trap to cleanup temporary files on exit
trap 'rm -f /tmp/filelist_$$ /tmp/fileinfo_$$ /tmp/sizeinfo_$$ /tmp/filtered_$$ /tmp/files_$$ /tmp/dirs_$$' EXIT

# Start the main program
main
