#!/bin/bash

# Process Management Menu - Compatible with Solaris and Linux Slackware
# Provides interactive menu for process management operations

# Global variables for OS detection
OS_TYPE=""
PS_CMD=""

# Function to detect operating system and set appropriate commands
detect_os() {
    if [ -f /etc/solaris-release ] || uname -s | grep -q "SunOS"; then
        OS_TYPE="solaris"
        PS_CMD="ps -eo pid,comm,pmem,pcpu"
    else
        OS_TYPE="linux"
        # Check if ps supports GNU options (most Linux distributions)
        if ps --help 2>/dev/null | grep -q "\-\-format"; then
            PS_CMD="ps -eo pid,comm,%mem,%cpu"
        else
            # Fallback for older or different ps implementations
            PS_CMD="ps -eo pid,comm,pmem,pcpu"
        fi
    fi
}

# Function to clear screen in a portable way
clear_screen() {
    if command -v clear >/dev/null 2>&1; then
        clear
    else
        printf '\033[2J\033[H'
    fi
}

# Function to display the main menu
display_menu() {
    echo "================================================="
    echo "           PROCESS MANAGEMENT MENU"
    echo "================================================="
    echo "System: $(uname -s) $(uname -r)"
    echo "Host: $(hostname)"
    echo "User: $(whoami)"
    echo "Date: $(date)"
    echo "================================================="
    echo ""
    echo "1) Display currently running processes"
    echo "2) Search for a process by name"
    echo "3) Kill/close a running process"
    echo "4) Restart a running process"
    echo "5) Show detailed process information"
    echo "6) Show system resource usage"
    echo "7) Exit"
    echo ""
    echo -n "Please select an option (1-7): "
}

# Function to display running processes with formatting
show_processes() {
    clear_screen
    echo "==============================================="
    echo "           CURRENTLY RUNNING PROCESSES"
    echo "==============================================="
    echo ""
    
    if [ "$OS_TYPE" = "solaris" ]; then
        printf "%-8s %-20s %-8s %-8s\n" "PID" "PROCESS NAME" "MEM%" "CPU%"
        printf "%-8s %-20s %-8s %-8s\n" "----" "------------" "----" "----"
        ps -eo pid,comm,pmem,pcpu --sort=-pcpu | tail -n +2 | head -n 20 | \
        while read pid comm pmem pcpu; do
            printf "%-8s %-20s %-8s %-8s\n" "$pid" "$comm" "$pmem" "$pcpu"
        done
    else
        printf "%-8s %-20s %-8s %-8s\n" "PID" "PROCESS NAME" "MEM%" "CPU%"
        printf "%-8s %-20s %-8s %-8s\n" "----" "------------" "----" "----"
        ps -eo pid,comm,%mem,%cpu --sort=-%cpu 2>/dev/null | tail -n +2 | head -n 20 | \
        while read pid comm mem cpu; do
            printf "%-8s %-20s %-8s %-8s\n" "$pid" "$comm" "$mem" "$cpu"
        done
    fi
    
    echo ""
    echo "Showing top 20 processes by CPU usage"
    echo "Press Enter to continue..."
    read -r dummy
}

# Function to search for a process by name
search_process() {
    clear_screen
    echo "==============================================="
    echo "              SEARCH FOR PROCESS"
    echo "==============================================="
    echo ""
    echo -n "Enter process name to search for: "
    read -r process_name
    
    if [ -z "$process_name" ]; then
        echo "Error: Process name cannot be empty"
        echo "Press Enter to continue..."
        read -r dummy
        return
    fi
    
    echo ""
    echo "Searching for processes matching: '$process_name'"
    echo ""
    
    # Search using ps and grep
    if [ "$OS_TYPE" = "solaris" ]; then
        result=$(ps -eo pid,ppid,uid,comm,args,pmem,pcpu,time | grep -i "$process_name" | grep -v grep)
    else
        result=$(ps -eo pid,ppid,uid,comm,args,%mem,%cpu,time | grep -i "$process_name" | grep -v grep)
    fi
    
    if [ -n "$result" ]; then
        printf "%-8s %-8s %-8s %-15s %-8s %-8s %-10s %s\n" "PID" "PPID" "UID" "COMMAND" "MEM%" "CPU%" "TIME" "FULL COMMAND"
        printf "%-8s %-8s %-8s %-15s %-8s %-8s %-10s %s\n" "---" "----" "---" "-------" "----" "----" "----" "------------"
        echo "$result" | while IFS= read -r line; do
            echo "$line" | awk '{printf "%-8s %-8s %-8s %-15s %-8s %-8s %-10s", $1, $2, $3, $4, $6, $7, $8; for(i=5; i<=NF; i++) printf " %s", $i; printf "\n"}'
        done
    else
        echo "No processes found matching: '$process_name'"
    fi
    
    echo ""
    echo "Press Enter to continue..."
    read -r dummy
}

# Function to validate PID
validate_pid() {
    local pid="$1"
    
    # Check if PID is numeric
    if ! echo "$pid" | grep -qE '^[0-9]+$'; then
        return 1
    fi
    
    # Check if process exists
    if ! kill -0 "$pid" 2>/dev/null; then
        return 1
    fi
    
    return 0
}

# Function to kill a process
kill_process() {
    clear_screen
    echo "==============================================="
    echo "              KILL/CLOSE PROCESS"
    echo "==============================================="
    echo ""
    
    # First show current processes for reference
    echo "Current running processes (top 15 by CPU):"
    printf "%-8s %-20s %-8s %-8s\n" "PID" "PROCESS NAME" "MEM%" "CPU%"
    printf "%-8s %-20s %-8s %-8s\n" "----" "------------" "----" "----"
    
    if [ "$OS_TYPE" = "solaris" ]; then
        ps -eo pid,comm,pmem,pcpu | tail -n +2 | head -n 15 | \
        while read pid comm pmem pcpu; do
            printf "%-8s %-20s %-8s %-8s\n" "$pid" "$comm" "$pmem" "$pcpu"
        done
    else
        ps -eo pid,comm,%mem,%cpu --sort=-%cpu 2>/dev/null | tail -n +2 | head -n 15 | \
        while read pid comm mem cpu; do
            printf "%-8s %-20s %-8s %-8s\n" "$pid" "$comm" "$mem" "$cpu"
        done
    fi
    
    echo ""
    echo -n "Enter the PID of the process to kill: "
    read -r pid
    
    if [ -z "$pid" ]; then
        echo "Error: PID cannot be empty"
        echo "Press Enter to continue..."
        read -r dummy
        return
    fi
    
    if ! validate_pid "$pid"; then
        echo "Error: Invalid PID or process doesn't exist: $pid"
        echo "Press Enter to continue..."
        read -r dummy
        return
    fi
    
    # Get process information before killing
    process_info=$(ps -p "$pid" -o comm= 2>/dev/null)
    
    echo ""
    echo "Process to kill: PID=$pid, Command=$process_info"
    echo ""
    echo "Choose kill signal:"
    echo "1) SIGTERM (15) - Graceful termination (recommended)"
    echo "2) SIGKILL (9)  - Force kill (use with caution)"
    echo "3) SIGINT (2)   - Interrupt signal"
    echo "4) Cancel"
    echo ""
    echo -n "Select signal (1-4): "
    read -r signal_choice
    
    case "$signal_choice" in
        1)
            if kill -15 "$pid" 2>/dev/null; then
                echo "SIGTERM signal sent to process $pid ($process_info)"
                sleep 2
                if kill -0 "$pid" 2>/dev/null; then
                    echo "Process still running. It may take time to terminate gracefully."
                else
                    echo "Process $pid terminated successfully."
                fi
            else
                echo "Error: Failed to send SIGTERM to process $pid"
            fi
            ;;
        2)
            echo "Warning: SIGKILL will forcefully terminate the process."
            echo -n "Are you sure? (y/N): "
            read -r confirm
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                if kill -9 "$pid" 2>/dev/null; then
                    echo "Process $pid ($process_info) forcefully killed."
                else
                    echo "Error: Failed to kill process $pid"
                fi
            else
                echo "Kill operation cancelled."
            fi
            ;;
        3)
            if kill -2 "$pid" 2>/dev/null; then
                echo "SIGINT signal sent to process $pid ($process_info)"
            else
                echo "Error: Failed to send SIGINT to process $pid"
            fi
            ;;
        4)
            echo "Kill operation cancelled."
            ;;
        *)
            echo "Invalid option. Kill operation cancelled."
            ;;
    esac
    
    echo ""
    echo "Press Enter to continue..."
    read -r dummy
}

# Function to restart a process
restart_process() {
    clear_screen
    echo "==============================================="
    echo "              RESTART PROCESS"
    echo "==============================================="
    echo ""
    echo -n "Enter process name to restart: "
    read -r process_name
    
    if [ -z "$process_name" ]; then
        echo "Error: Process name cannot be empty"
        echo "Press Enter to continue..."
        read -r dummy
        return
    fi
    
    # Find the process
    pids=$(pgrep "$process_name" 2>/dev/null)
    
    if [ -z "$pids" ]; then
        echo "No running process found with name: '$process_name'"
        echo "Press Enter to continue..."
        read -r dummy
        return
    fi
    
    # Show found processes
    echo "Found processes:"
    for pid in $pids; do
        process_info=$(ps -p "$pid" -o pid,comm,args 2>/dev/null | tail -n +2)
        echo "  $process_info"
    done
    
    echo ""
    echo "Process restart methods:"
    echo "1) Kill and restart (you provide restart command)"
    echo "2) Send SIGHUP (for processes that support reload)"
    echo "3) Cancel"
    echo ""
    echo -n "Select method (1-3): "
    read -r restart_method
    
    case "$restart_method" in
        1)
            echo ""
            echo -n "Enter the command to restart the process: "
            read -r restart_cmd
            
            if [ -z "$restart_cmd" ]; then
                echo "Error: Restart command cannot be empty"
                echo "Press Enter to continue..."
                read -r dummy
                return
            fi
            
            echo ""
            echo "This will:"
            echo "1. Kill process(es) with name '$process_name'"
            echo "2. Execute: $restart_cmd"
            echo ""
            echo -n "Continue? (y/N): "
            read -r confirm
            
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                # Kill the process
                for pid in $pids; do
                    if kill "$pid" 2>/dev/null; then
                        echo "Killed process PID: $pid"
                    fi
                done
                
                # Wait a moment
                sleep 2
                
                # Start the new process
                echo "Starting new process..."
                if eval "$restart_cmd" >/dev/null 2>&1 &; then
                    echo "Restart command executed: $restart_cmd"
                    sleep 1
                    new_pids=$(pgrep "$process_name" 2>/dev/null)
                    if [ -n "$new_pids" ]; then
                        echo "Process restarted successfully. New PID(s): $new_pids"
                    else
                        echo "Warning: Process restart command executed but process not found running"
                    fi
                else
                    echo "Error: Failed to execute restart command"
                fi
            else
                echo "Restart cancelled."
            fi
            ;;
        2)
            echo ""
            echo -n "Send SIGHUP to all processes? (y/N): "
            read -r confirm
            
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                for pid in $pids; do
                    if kill -HUP "$pid" 2>/dev/null; then
                        echo "SIGHUP sent to PID: $pid"
                    else
                        echo "Failed to send SIGHUP to PID: $pid"
                    fi
                done
            else
                echo "Restart cancelled."
            fi
            ;;
        3)
            echo "Restart cancelled."
            ;;
        *)
            echo "Invalid option. Restart cancelled."
            ;;
    esac
    
    echo ""
    echo "Press Enter to continue..."
    read -r dummy
}

# Function to show detailed process information
show_detailed_info() {
    clear_screen
    echo "==============================================="
    echo "          DETAILED PROCESS INFORMATION"
    echo "==============================================="
    echo ""
    echo -n "Enter PID or process name: "
    read -r input
    
    if [ -z "$input" ]; then
        echo "Error: Input cannot be empty"
        echo "Press Enter to continue..."
        read -r dummy
        return
    fi
    
    # Check if input is a PID (numeric)
    if echo "$input" | grep -qE '^[0-9]+$'; then
        # It's a PID
        if validate_pid "$input"; then
            echo ""
            echo "Detailed information for PID: $input"
            echo "----------------------------------------"
            
            if [ "$OS_TYPE" = "solaris" ]; then
                ps -p "$input" -o pid,ppid,uid,gid,comm,args,pmem,pcpu,time,tty
            else
                ps -p "$input" -o pid,ppid,uid,gid,comm,args,%mem,%cpu,time,tty
            fi
            
            # Additional info if available
            if [ -r "/proc/$input/status" ]; then
                echo ""
                echo "Additional information from /proc/$input/status:"
                echo "----------------------------------------"
                grep -E "(Name|State|Pid|PPid|Uid|Gid|VmSize|VmRSS)" "/proc/$input/status" 2>/dev/null || echo "Not available"
            fi
        else
            echo "Error: Invalid PID or process doesn't exist: $input"
        fi
    else
        # It's a process name
        pids=$(pgrep "$input" 2>/dev/null)
        if [ -n "$pids" ]; then
            echo ""
            echo "Detailed information for processes matching: '$input'"
            echo "----------------------------------------"
            
            for pid in $pids; do
                echo ""
                echo "=== PID: $pid ==="
                if [ "$OS_TYPE" = "solaris" ]; then
                    ps -p "$pid" -o pid,ppid,uid,gid,comm,args,pmem,pcpu,time,tty
                else
                    ps -p "$pid" -o pid,ppid,uid,gid,comm,args,%mem,%cpu,time,tty
                fi
            done
        else
            echo "No processes found matching: '$input'"
        fi
    fi
    
    echo ""
    echo "Press Enter to continue..."
    read -r dummy
}

# Function to show system resource usage
show_system_resources() {
    clear_screen
    echo "==============================================="
    echo "           SYSTEM RESOURCE USAGE"
    echo "==============================================="
    echo ""
    
    # System uptime
    echo "System Uptime:"
    uptime
    echo ""
    
    # Memory usage
    echo "Memory Usage:"
    if command -v free >/dev/null 2>&1; then
        free -h 2>/dev/null || free
    else
        # Fallback for Solaris
        echo "Memory information (using vmstat):"
        vmstat 1 2 | tail -1
    fi
    echo ""
    
    # Disk usage
    echo "Disk Usage:"
    df -h 2>/dev/null || df
    echo ""
    
    # Load average and top processes
    echo "Top 10 CPU-consuming processes:"
    if [ "$OS_TYPE" = "solaris" ]; then
        ps -eo pid,comm,pmem,pcpu | sort -k4 -nr | head -n 11
    else
        ps -eo pid,comm,%mem,%cpu --sort=-%cpu | head -n 11
    fi
    
    echo ""
    echo "Press Enter to continue..."
    read -r dummy
}

# Function to handle script termination
cleanup_and_exit() {
    clear_screen
    echo "==============================================="
    echo "           PROCESS MANAGER EXITING"
    echo "==============================================="
    echo ""
    echo "Thank you for using the Process Management Menu"
    echo "Session ended: $(date)"
    echo ""
    exit 0
}

# Main program loop
main() {
    # Detect OS and set commands
    detect_os
    
    # Main menu loop
    while true; do
        clear_screen
        display_menu
        read -r choice
        
        case "$choice" in
            1)
                show_processes
                ;;
            2)
                search_process
                ;;
            3)
                kill_process
                ;;
            4)
                restart_process
                ;;
            5)
                show_detailed_info
                ;;
            6)
                show_system_resources
                ;;
            7)
                cleanup_and_exit
                ;;
            *)
                echo ""
                echo "Invalid option. Please select 1-7."
                echo "Press Enter to continue..."
                read -r dummy
                ;;
        esac
    done
}

# Trap signals for clean exit
trap cleanup_and_exit INT TERM

# Start the program
main