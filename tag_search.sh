#!/bin/bash

# Project Tag Search Functions
# Add these to your ~/.bashrc or ~/.zshrc by sourcing this file:
# source ~/Projects/tagging/tag_search.sh

# Search projects by tag
ptag() {
    if [[ -z "$1" ]]; then
        echo "Usage: ptag <tag>"
        echo "Available tags:"
        find ~/Projects -maxdepth 2 -name ".tags" -exec cat {} \; | sort -u | grep -v '^$'
        return
    fi
    
    echo "Projects tagged with '$1':"
    find ~/Projects -maxdepth 2 -name ".tags" -exec grep -l "^$1$" {} \; 2>/dev/null | while read -r file; do
        project_dir=$(dirname "$file")
        project_name=$(basename "$project_dir")
        tags=$(cat "$file" | tr '\n' ' ')
        echo "  📁 $project_name ($tags)"
    done
}

# List all available tags with count
ptags() {
    echo "All available tags:"
    find ~/Projects -maxdepth 2 -name ".tags" -exec awk '1' {} + | \
    sed 's/%$//' | \
    sed 's/^[[:space:]]*//' | \
    sed 's/[[:space:]]*$//' | \
    grep -v '^$' | \
    sort | uniq -c | sort -nr | while read count tag; do
        printf "  %-15s (%d projects)\n" "$tag" "$count"
    done
}

# Search projects by multiple tags (AND operation)
ptag-and() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: ptag-and <tag1> <tag2> [tag3...]"
        return
    fi
    
    echo "Projects tagged with ALL of: $*"
    find ~/Projects -maxdepth 2 -name ".tags" | while read -r file; do
        project_dir=$(dirname "$file")
        project_name=$(basename "$project_dir")
        
        # Check if all tags are present
        all_present=true
        for tag in "$@"; do
            if ! grep -q "^$tag$" "$file"; then
                all_present=false
                break
            fi
        done
        
        if $all_present; then
            tags=$(cat "$file" | tr '\n' ' ')
            echo "  📁 $project_name ($tags)"
        fi
    done
}
