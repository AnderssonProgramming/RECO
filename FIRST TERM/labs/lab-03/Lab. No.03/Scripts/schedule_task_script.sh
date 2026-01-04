#!/bin/bash

# Schedule Task Script - Compatible with Solaris and Linux Slackware
# Usage: ./schedule-task-script.sh <frequency> <command>
# Example: ./schedule-task-script.sh "0 */2 * * *" "/usr/bin/backup.sh"
# Example: ./schedule-task-script.sh "daily" "echo 'Daily task executed'"

# Function to display usage information
show_usage() {
    echo "Usage: $0 <frequency> <command>"
    echo ""
    echo "Frequency can be:"
    echo "  - Cron format: \"minute hour day month weekday\""
    echo "    Examples: \"0 2 * * *\" (daily at 2 AM)"
    echo "              \"*/15 * * * *\" (every 15 minutes)"
    echo "              \"0 */6 * * *\" (every 6 hours)"
    echo ""
    echo "  - Predefined shortcuts:"
    echo "    @reboot    - Run once at startup"
    echo "    @yearly    - Run once a year (0 0 1 1 *)"
    echo "    @annually  - Same as @yearly"
    echo "    @monthly   - Run once a month (0 0 1 * *)"
    echo "    @weekly    - Run once a week (0 0 * * 0)"
    echo "    @daily     - Run once a day (0 0 * * *)"
    echo "    @hourly    - Run once an hour (0 * * * *)"
    echo ""
    echo "Command: The full path or command to execute"
    echo ""
    echo "Examples:"
    echo "  $0 \"@daily\" \"/home/user/backup.sh\""
    echo "  $0 \"0 2 * * *\" \"echo 'Backup completed' >> /var/log/backup.log\""
    echo "  $0 \"*/30 * * * *\" \"/usr/bin/system-check\""
}

# Function to validate cron time format
validate_cron_format() {
    local cron_time="$1"
    
    # Check for predefined shortcuts
    case "$cron_time" in
        "@reboot"|"@yearly"|"@annually"|"@monthly"|"@weekly"|"@daily"|"@hourly")
            return 0
            ;;
    esac
    
    # Validate standard cron format (5 fields)
    local field_count=$(echo "$cron_time" | awk '{print NF}')
    if [ "$field_count" -ne 5 ]; then
        return 1
    fi
    
    # Basic validation for each field (simplified check)
    local minute=$(echo "$cron_time" | awk '{print $1}')
    local hour=$(echo "$cron_time" | awk '{print $2}')
    local day=$(echo "$cron_time" | awk '{print $3}')
    local month=$(echo "$cron_time" | awk '{print $4}')
    local weekday=$(echo "$cron_time" | awk '{print $5}')
    
    # Check if fields contain valid cron characters
    for field in "$minute" "$hour" "$day" "$month" "$weekday"; do
        if ! echo "$field" | grep -qE '^(\*|[0-9,-/]+)$'; then
            return 1
        fi
    done
    
    return 0
}

# Function to check if command exists and is executable
validate_command() {
    local cmd="$1"
    local first_word=$(echo "$cmd" | awk '{print $1}')
    
    # Check if it's a full path
    if [[ "$first_word" == /* ]]; then
        if [ ! -f "$first_word" ] || [ ! -x "$first_word" ]; then
            echo "Warning: Command '$first_word' is not executable or doesn't exist"
            return 1
        fi
    else
        # Check if command exists in PATH
        if ! command -v "$first_word" >/dev/null 2>&1; then
            echo "Warning: Command '$first_word' not found in PATH"
            return 1
        fi
    fi
    return 0
}

# Function to backup current crontab
backup_crontab() {
    local backup_dir="$HOME/.cron_backups"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    # Create backup directory if it doesn't exist
    mkdir -p "$backup_dir"
    
    # Backup current crontab
    if crontab -l >/dev/null 2>&1; then
        crontab -l > "$backup_dir/crontab_backup_$timestamp"
        echo "Current crontab backed up to: $backup_dir/crontab_backup_$timestamp"
    fi
}

# Function to add task to crontab
add_cron_task() {
    local frequency="$1"
    local command="$2"
    local temp_cron="/tmp/crontab_temp_$$"
    
    # Get current crontab (if exists) and add new task
    (crontab -l 2>/dev/null; echo "$frequency $command") | sort | uniq > "$temp_cron"
    
    # Install new crontab
    if crontab "$temp_cron"; then
        echo "Task scheduled successfully!"
        echo "Frequency: $frequency"
        echo "Command: $command"
        echo ""
        echo "Current crontab entries:"
        crontab -l | grep -v "^#" | grep -v "^$" | nl
    else
        echo "Error: Failed to install crontab"
        rm -f "$temp_cron"
        exit 1
    fi
    
    # Clean up temporary file
    rm -f "$temp_cron"
}

# Function to check if cron service is running
check_cron_service() {
    # Check for different cron daemons on Solaris and Linux
    if pgrep -x "crond" >/dev/null 2>&1 || pgrep -x "cron" >/dev/null 2>&1; then
        return 0
    else
        echo "Warning: Cron service doesn't appear to be running"
        echo "Please ensure cron daemon is started:"
        
        # Detect OS and provide appropriate commands
        if [ -f /etc/solaris-release ] || uname -s | grep -q "SunOS"; then
            echo "  Solaris: svcadm enable cron"
        else
            echo "  Linux: /etc/rc.d/rc.crond start  (Slackware)"
            echo "         service crond start      (other distributions)"
        fi
        return 1
    fi
}

# Main script execution
main() {
    # Check arguments
    if [ $# -lt 2 ]; then
        echo "Error: Insufficient arguments"
        echo ""
        show_usage
        exit 1
    fi
    
    local frequency="$1"
    shift
    local command="$*"  # Join all remaining arguments as command
    
    # Display what we're about to do
    echo "Task Scheduler - Solaris/Linux Compatible"
    echo "========================================"
    echo "Frequency: $frequency"
    echo "Command: $command"
    echo ""
    
    # Validate frequency format
    if ! validate_cron_format "$frequency"; then
        echo "Error: Invalid frequency format"
        echo "Please use standard cron format or predefined shortcuts"
        echo ""
        show_usage
        exit 1
    fi
    
    # Validate command (with warning only)
    validate_command "$command"
    
    # Check if cron service is running
    check_cron_service
    
    # Backup current crontab
    backup_crontab
    
    # Confirmation prompt
    echo "Do you want to add this task to cron? (y/N)"
    read -r response
    case "$response" in
        [Yy]|[Yy][Ee][Ss])
            add_cron_task "$frequency" "$command"
            ;;
        *)
            echo "Task scheduling cancelled."
            exit 0
            ;;
    esac
}

# Handle help options
case "${1:-}" in
    -h|--help|help)
        show_usage
        exit 0
        ;;
esac

# Run main function with all arguments
main "$@"