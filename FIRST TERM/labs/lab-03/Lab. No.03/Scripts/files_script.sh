#!/bin/bash

# File System Traversal Script - Compatible with Solaris and Linux Slackware
# Usage: ./files-script.sh <no_files> <max_size> [start_directory]
# Example: ./files-script.sh 10 1GB /home/user

# Global variables
OS_TYPE=""
FIND_SIZE_FORMAT=""
START_DIR=""

# Function to detect operating system
detect_os() {
    if [ -f /etc/solaris-release ] || uname -s | grep -q "SunOS"; then
        OS_TYPE="solaris"
    else
        OS_TYPE="linux"
    fi
}

# Function to display usage information
show_usage() {
    echo "File System Traversal Script"
    echo "Usage: $0 <no_files> <max_size> [start_directory]"
    echo ""
    echo "Parameters:"
    echo "  no_files       - Number of smallest files to display"
    echo "  max_size       - Maximum file size limit"
    echo "  start_directory - Directory to start search (optional, default: current directory)"
    echo ""
    echo "Size format examples:"
    echo "  123        - 123 bytes"
    echo "  1K or 1KB  - 1 kilobyte (1024 bytes)"
    echo "  1M or 1MB  - 1 megabyte (1024*1024 bytes)"
    echo "  1G or 1GB  - 1 gigabyte (1024*1024*1024 bytes)"
    echo "  500K       - 500 kilobytes"
    echo "  2.5M       - 2.5 megabytes"
    echo ""
    echo "Examples:"
    echo "  $0 10 1GB                    # Find 10 smallest files under 1GB in current directory"
    echo "  $0 5 500K /home/user        # Find 5 smallest files under 500KB in /home/user"
    echo "  $0 20 1M /var/log           # Find 20 smallest files under 1MB in /var/log"
}

# Function to convert human-readable size to bytes
convert_size_to_bytes() {
    local size_input="$1"
    local size_bytes=""
    
    # Remove any trailing 'B' and convert to uppercase
    size_input=$(echo "$size_input" | sed 's/[Bb]$//' | tr '[:lower:]' '[:upper:]')
    
    # Extract number and unit
    local number=$(echo "$size_input" | sed 's/[KMGT]$//')
    local unit=$(echo "$size_input" | sed 's/^[0-9.]*\([KMGT]\)$/\1/')
    
    # Validate number
    if ! echo "$number" | grep -qE '^[0-9]+(\.[0-9]+)?$'; then
        echo "Error: Invalid size format: $1" >&2
        return 1
    fi
    
    # Convert based on unit
    case "$unit" in
        K)
            size_bytes=$(echo "$number * 1024" | bc 2>/dev/null || echo "scale=0; $number * 1024" | awk '{print int($1)}')
            ;;
        M)
            size_bytes=$(echo "$number * 1024 * 1024" | bc 2>/dev/null || echo "scale=0; $number * 1024 * 1024" | awk '{print int($1)}')
            ;;
        G)
            size_bytes=$(echo "$number * 1024 * 1024 * 1024" | bc 2>/dev/null || echo "scale=0; $number * 1024 * 1024 * 1024" | awk '{print int($1)}')
            ;;
        T)
            size_bytes=$(echo "$number * 1024 * 1024 * 1024 * 1024" | bc 2>/dev/null || echo "scale=0; $number * 1024 * 1024 * 1024 * 1024" | awk '{print int($1)}')
            ;;
        *)
            # No unit, assume bytes
            size_bytes="$number"
            ;;
    esac
    
    echo "$size_bytes"
    return 0
}

# Function to format size in human-readable format
format_size_human() {
    local bytes="$1"
    
    if [ "$bytes" -lt 1024 ]; then
        echo "${bytes}B"
    elif [ "$bytes" -lt 1048576 ]; then
        echo "scale=1; $bytes / 1024" | bc 2>/dev/null | sed 's/\.0$//' | sed 's/$/K/'
    elif [ "$bytes" -lt 1073741824 ]; then
        echo "scale=1; $bytes / 1048576" | bc 2>/dev/null | sed 's/\.0$//' | sed 's/$/M/'
    else
        echo "scale=1; $bytes / 1073741824" | bc 2>/dev/null | sed 's/\.0$//' | sed 's/$/G/'
    fi
}

# Function to validate directory
validate_directory() {
    local directory="$1"
    
    if [ ! -d "$directory" ]; then
        echo "Error: Directory '$directory' does not exist or is not accessible"
        return 1
    fi
    
    if [ ! -r "$directory" ]; then
        echo "Error: Directory '$directory' is not readable"
        return 1
    fi
    
    return 0
}

# Function to validate number of files
validate_number() {
    local number="$1"
    
    if ! echo "$number" | grep -qE '^[0-9]+$'; then
        echo "Error: Number of files must be a positive integer"
        return 1
    fi
    
    if [ "$number" -le 0 ]; then
        echo "Error: Number of files must be greater than 0"
        return 1
    fi
    
    if [ "$number" -gt 10000 ]; then
        echo "Warning: Large number of files requested ($number). This may take some time."
    fi
    
    return 0
}

# Function to find files using appropriate method based on OS
find_files() {
    local max_size_bytes="$1"
    local start_directory="$2"
    
    # For Solaris compatibility, we need to handle find differently
    if [ "$OS_TYPE" = "solaris" ]; then
        # Solaris find may not support -printf, use alternative approach
        find "$start_directory" -type f -size "-${max_size_bytes}c" 2>/dev/null | while read -r file; do
            if [ -f "$file" ] && [ -r "$file" ]; then
                # Get file size using ls
                size=$(ls -l "$file" 2>/dev/null | awk '{print $5}')
                if [ -n "$size" ] && [ "$size" -le "$max_size_bytes" ]; then
                    # Get directory path
                    dir_path=$(dirname "$file")
                    file_name=$(basename "$file")
                    echo "$size|$file_name|$dir_path|$file"
                fi
            fi
        done
    else
        # Linux find with -printf support
        if find /dev/null -printf '%s' 2>/dev/null >/dev/null; then
            # GNU find supports -printf
            find "$start_directory" -type f -size "-${max_size_bytes}c" -printf "%s|%f|%h|%p\n" 2>/dev/null
        else
            # Fallback method for systems without -printf
            find "$start_directory" -type f -size "-${max_size_bytes}c" 2>/dev/null | while read -r file; do
                if [ -f "$file" ] && [ -r "$file" ]; then
                    size=$(stat -c '%s' "$file" 2>/dev/null || ls -l "$file" 2>/dev/null | awk '{print $5}')
                    if [ -n "$size" ] && [ "$size" -le "$max_size_bytes" ]; then
                        dir_path=$(dirname "$file")
                        file_name=$(basename "$file")
                        echo "$size|$file_name|$dir_path|$file"
                    fi
                fi
            done
        fi
    fi
}

# Function to display results in formatted table
display_results() {
    local results="$1"
    local num_files="$2"
    local max_size="$3"
    local start_dir="$4"
    
    echo "============================================================================"
    echo "                    FILE SYSTEM TRAVERSAL RESULTS"
    echo "============================================================================"
    echo "Search Directory: $start_dir"
    echo "Maximum Size: $max_size"
    echo "Number of Files Requested: $num_files"
    echo "Search Time: $(date)"
    echo "============================================================================"
    echo ""
    
    if [ -z "$results" ]; then
        echo "No files found matching the criteria."
        return
    fi
    
    local total_files=$(echo "$results" | wc -l)
    echo "Total files found: $total_files"
    echo "Displaying smallest $num_files files:"
    echo ""
    
    # Header
    printf "%-6s %-30s %-10s %-10s %s\n" "RANK" "FILE NAME" "SIZE" "SIZE (H)" "DIRECTORY PATH"
    printf "%-6s %-30s %-10s %-10s %s\n" "----" "----------" "----" "-------" "--------------"
    
    # Display results
    echo "$results" | sort -t'|' -k1 -n | head -n "$num_files" | awk -F'|' '
    {
        rank = NR
        size = $1
        name = $2
        path = $3
        full_path = $4
        
        # Truncate long filenames
        if (length(name) > 30) {
            display_name = substr(name, 1, 27) "..."
        } else {
            display_name = name
        }
        
        # Format size in human readable format
        if (size < 1024) {
            human_size = size "B"
        } else if (size < 1048576) {
            human_size = sprintf("%.1fK", size/1024)
        } else if (size < 1073741824) {
            human_size = sprintf("%.1fM", size/1048576)
        } else {
            human_size = sprintf("%.1fG", size/1073741824)
        }
        
        # Truncate long paths
        if (length(path) > 40) {
            display_path = "..." substr(path, length(path)-36, 37)
        } else {
            display_path = path
        }
        
        printf "%-6d %-30s %-10s %-10s %s\n", rank, display_name, size, human_size, display_path
    }'
    
    echo ""
    echo "============================================================================"
}

# Function to show progress during search
show_progress() {
    local start_dir="$1"
    local max_size="$2"
    
    echo "Searching for files in: $start_dir"
    echo "Maximum file size: $max_size"
    echo "Please wait, this may take some time for large directories..."
    echo ""
    
    # Simple progress indicator
    if command -v pv >/dev/null 2>&1; then
        # If pv is available, use it for progress
        return 0
    else
        # Simple spinner
        local pid=$!
        local spin='-\|/'
        local i=0
        while kill -0 $pid 2>/dev/null; do
            i=$(( (i+1) %4 ))
            printf "\r[%c] Scanning directories..." "${spin:$i:1}"
            sleep 0.1
        done
        printf "\r"
    fi
}

# Function to get directory statistics
get_directory_stats() {
    local directory="$1"
    
    echo "Directory Statistics for: $directory"
    echo "------------------------------------"
    
    # Count total files and directories
    local total_files=0
    local total_dirs=0
    local total_size=0
    
    if command -v find >/dev/null 2>&1; then
        total_files=$(find "$directory" -type f 2>/dev/null | wc -l)
        total_dirs=$(find "$directory" -type d 2>/dev/null | wc -l)
        
        # Calculate total size (this might be slow for large directories)
        if [ "$total_files" -lt 1000 ]; then
            if [ "$OS_TYPE" = "solaris" ]; then
                total_size=$(find "$directory" -type f -exec ls -l {} \; 2>/dev/null | awk '{sum += $5} END {print sum+0}')
            else
                total_size=$(find "$directory" -type f -exec stat -c '%s' {} \; 2>/dev/null | awk '{sum += $1} END {print sum+0}')
            fi
        fi
    fi
    
    echo "Total files: $total_files"
    echo "Total directories: $total_dirs"
    if [ "$total_size" -gt 0 ]; then
        echo "Total size: $(format_size_human $total_size)"
    fi
    echo ""
}

# Main function
main() {
    # Detect operating system
    detect_os
    
    # Check arguments
    if [ $# -lt 2 ]; then
        echo "Error: Insufficient arguments"
        echo ""
        show_usage
        exit 1
    fi
    
    local no_files="$1"
    local max_size="$2"
    local start_directory="${3:-.}"  # Default to current directory if not specified
    
    # Resolve relative path to absolute path
    if [ "$start_directory" = "." ]; then
        start_directory=$(pwd)
    elif [ "${start_directory#/}" = "$start_directory" ]; then
        # Relative path, convert to absolute
        start_directory="$(pwd)/$start_directory"
    fi
    
    # Validate inputs
    if ! validate_number "$no_files"; then
        exit 1
    fi
    
    if ! validate_directory "$start_directory"; then
        exit 1
    fi
    
    # Convert size to bytes
    local max_size_bytes
    max_size_bytes=$(convert_size_to_bytes "$max_size")
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    echo "File System Traversal Script"
    echo "============================"
    echo "OS Type: $OS_TYPE"
    echo "Start Directory: $start_directory"
    echo "Number of files: $no_files"
    echo "Maximum size: $max_size ($max_size_bytes bytes)"
    echo ""
    
    # Show directory statistics
    get_directory_stats "$start_directory"
    
    # Perform the search
    echo "Starting file search..."
    local search_results
    search_results=$(find_files "$max_size_bytes" "$start_directory")
    
    if [ $? -ne 0 ]; then
        echo "Error occurred during file search"
        exit 1
    fi
    
    # Display results
    display_results "$search_results" "$no_files" "$max_size" "$start_directory"
    
    # Additional summary
    if [ -n "$search_results" ]; then
        local total_found=$(echo "$search_results" | wc -l)
        local smallest_size=$(echo "$search_results" | sort -t'|' -k1 -n | head -n 1 | cut -d'|' -f1)
        
        echo ""
        echo "Summary:"
        echo "  Files matching criteria: $total_found"
        echo "  Smallest file size: $(format_size_human $smallest_size)"
        echo "  Search completed successfully"
    fi
}

# Handle help options
case "${1:-}" in
    -h|--help|help)
        show_usage
        exit 0
        ;;
esac

# Check if bc is available for calculations (install if needed)
if ! command -v bc >/dev/null 2>&1; then
    echo "Warning: 'bc' calculator not found. Size calculations may be less precise."
fi

# Run main function
main "$@"