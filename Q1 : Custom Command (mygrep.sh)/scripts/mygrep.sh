#!/bin/bash

# mygrep.sh - A simple grep-like tool
# Usage: ./mygrep.sh [options] pattern file

# Function to display help message
show_help() {
    echo "Usage: $0 [options] pattern file"
    echo "Options:"
    echo "  -n    Show line numbers for each match"
    echo "  -v    Invert the match (show lines that do not match)"
    echo "  --help Display this help message"
    exit 1
}

# Initialize variables
show_line_numbers=false
invert_match=false
pattern=""
file=""

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        -n)
            show_line_numbers=true
            shift
            ;;
        -v)
            invert_match=true
            shift
            ;;
        -nv|-vn)
            show_line_numbers=true
            invert_match=true
            shift
            ;;
        --help)
            show_help
            ;;
        *)
            # First non-option argument is the pattern
            if [ -z "$pattern" ]; then
                pattern="$1"
            # Second non-option argument is the file
            elif [ -z "$file" ]; then
                file="$1"
            else
                echo "Error: Too many arguments" >&2
                show_help
            fi
            shift
            ;;
    esac
done

# Check if required arguments are provided
if [ -z "$pattern" ]; then
    echo "Error: Missing search pattern" >&2
    show_help
fi

if [ -z "$file" ]; then
    echo "Error: Missing filename" >&2
    show_help
fi

# Check if file exists
if [ ! -f "$file" ]; then
    echo "Error: File '$file' not found" >&2
    exit 1
fi

# Process the file
line_number=0
while IFS= read -r line; do
    line_number=$((line_number + 1))
    
    # Check if the line matches the pattern (case-insensitive)
    if echo "$line" | grep -qi "$pattern"; then
        match=true
    else
        match=false
    fi
    
    # Determine whether to print the line based on invert option
    if { $match && ! $invert_match; } || { ! $match && $invert_match; }; then
        if $show_line_numbers; then
            echo "$line_number:$line"
        else
            echo "$line"
        fi
    fi
done < "$file"

exit 0