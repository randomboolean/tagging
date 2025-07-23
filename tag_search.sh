#!/bin/bash

# Project Tag Search Functions
# Add these to your ~/.bashrc or ~/.zshrc by sourcing this file:
# source ~/Projects/tagging/tag_search.sh

# Search projects by tag
ptag() {
    if [[ -z "$1" ]]; then
        echo "Usage: ptag <tag>"
        echo "Available tags:"
        find ~/Projects -maxdepth 2 -name ".tags" -exec awk '1' {} + | \
        sed 's/%$//' | \
        sed 's/^[[:space:]]*//' | \
        sed 's/[[:space:]]*$//' | \
        grep -v '^$' | \
        sort -u
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

# Helper function to get all available tags for completion
_get_available_tags() {
    find ~/Projects -maxdepth 2 -name ".tags" -exec awk '1' {} + 2>/dev/null | \
    sed 's/%$//' | \
    sed 's/^[[:space:]]*//' | \
    sed 's/[[:space:]]*$//' | \
    grep -v '^$' | \
    sort -u
}

# Bash completion
if [[ -n "${BASH_VERSION:-}" ]]; then
    _ptag_completion() {
        local cur="${COMP_WORDS[COMP_CWORD]}"
        COMPREPLY=($(compgen -W "$(_get_available_tags)" -- "$cur"))
    }
    
    _ptag_and_completion() {
        local cur="${COMP_WORDS[COMP_CWORD]}"
        local used_tags="${COMP_WORDS[@]:1:$((COMP_CWORD-1))}"
        local available_tags=$(_get_available_tags)
        
        # Filter out already used tags
        local remaining_tags=""
        for tag in $available_tags; do
            if [[ ! " $used_tags " =~ " $tag " ]]; then
                remaining_tags="$remaining_tags $tag"
            fi
        done
        
        COMPREPLY=($(compgen -W "$remaining_tags" -- "$cur"))
    }
    
    complete -F _ptag_completion ptag
    complete -F _ptag_and_completion ptag-and
fi

# Zsh completion
if [[ -n "${ZSH_VERSION:-}" ]]; then
    _ptag_zsh() {
        local -a tags
        tags=(${(f)"$(_get_available_tags)"})
        _describe 'tags' tags
    }
    
    _ptag_and_zsh() {
        local -a tags
        tags=(${(f)"$(_get_available_tags)"})
        _describe 'tags' tags
    }
    
    compdef _ptag_zsh ptag
    compdef _ptag_and_zsh ptag-and
fi
