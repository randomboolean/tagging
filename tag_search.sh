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
        tags=$(cat "$file" | tr '\n' ' ' | sed 's/[[:space:]]*$//')
        echo "$project_name|$tags"
    done | sort | while IFS='|' read -r project_name tags; do
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
            tags=$(cat "$file" | tr '\n' ' ' | sed 's/[[:space:]]*$//')
            echo "$project_name|$tags"
        fi
    done | sort | while IFS='|' read -r project_name tags; do
        echo "  📁 $project_name ($tags)"
    done
}

# Search projects NOT tagged with a specific tag
ptag-not() {
    if [[ -z "$1" ]]; then
        echo "Usage: ptag-not <tag>"
        echo "This will list projects that do NOT have the specified tag."
        return
    fi
    
    echo "Projects NOT tagged with '$1':"
    find ~/Projects -maxdepth 2 -name ".tags" | while read -r file; do
        project_dir=$(dirname "$file")
        project_name=$(basename "$project_dir")
        
        # Check if the tag is NOT present
        if ! grep -q "^$1$" "$file"; then
            tags=$(cat "$file" | tr '\n' ' ' | sed 's/[[:space:]]*$//')
            echo "$project_name|$tags"
        fi
    done | sort | while IFS='|' read -r project_name tags; do
        echo "  📁 $project_name ($tags)"
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
        local used_tags=(${COMP_WORDS[@]:1:$((COMP_CWORD-1))})
        
        # If no tags specified yet, show all tags
        if [[ ${#used_tags[@]} -eq 0 ]]; then
            COMPREPLY=($(compgen -W "$(_get_available_tags)" -- "$cur"))
            return
        fi
        
        # Find projects that have ALL the already specified tags
        local matching_projects=""
        find ~/Projects -maxdepth 2 -name ".tags" | while read -r file; do
            local has_all_tags=true
            for tag in "${used_tags[@]}"; do
                if ! grep -q "^$tag$" "$file" 2>/dev/null; then
                    has_all_tags=false
                    break
                fi
            done
            
            if $has_all_tags; then
                echo "$file"
            fi
        done > /tmp/ptag_matching_projects_$$
        
        # Get all tags from those matching projects
        local candidate_tags=""
        if [[ -s /tmp/ptag_matching_projects_$$ ]]; then
            candidate_tags=$(cat /tmp/ptag_matching_projects_$$ | xargs -I{} awk '1' {} 2>/dev/null | \
                sed 's/%$//' | \
                sed 's/^[[:space:]]*//' | \
                sed 's/[[:space:]]*$//' | \
                grep -v '^$' | \
                sort -u)
        fi
        
        # Filter out already used tags
        local remaining_tags=""
        for tag in $candidate_tags; do
            local already_used=false
            for used_tag in "${used_tags[@]}"; do
                if [[ "$tag" == "$used_tag" ]]; then
                    already_used=true
                    break
                fi
            done
            if [[ "$already_used" == false ]]; then
                remaining_tags="$remaining_tags $tag"
            fi
        done
        
        # Clean up temp file
        rm -f /tmp/ptag_matching_projects_$$
        
        COMPREPLY=($(compgen -W "$remaining_tags" -- "$cur"))
    }
    
    complete -F _ptag_completion ptag
    complete -F _ptag_completion ptag-not
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
        local used_tags=(${words[2,-2]})
        
        # If no tags specified yet, show all tags
        if [[ ${#used_tags[@]} -eq 0 ]]; then
            tags=(${(f)"$(_get_available_tags)"})
            _describe 'tags' tags
            return
        fi
        
        # Find projects that have ALL the already specified tags
        local matching_projects_file="/tmp/ptag_matching_projects_zsh_$$"
        find ~/Projects -maxdepth 2 -name ".tags" | while read -r file; do
            local has_all_tags=true
            for tag in "${used_tags[@]}"; do
                if ! grep -q "^$tag$" "$file" 2>/dev/null; then
                    has_all_tags=false
                    break
                fi
            done
            
            if $has_all_tags; then
                echo "$file"
            fi
        done > "$matching_projects_file"
        
        # Get all tags from those matching projects
        local candidate_tags
        if [[ -s "$matching_projects_file" ]]; then
            candidate_tags=$(cat "$matching_projects_file" | xargs -I{} awk '1' {} 2>/dev/null | \
                sed 's/%$//' | \
                sed 's/^[[:space:]]*//' | \
                sed 's/[[:space:]]*$//' | \
                grep -v '^$' | \
                sort -u)
        fi
        
        # Filter out already used tags
        local -a remaining_tags
        for tag in ${(f)candidate_tags}; do
            local already_used=false
            for used_tag in "${used_tags[@]}"; do
                if [[ "$tag" == "$used_tag" ]]; then
                    already_used=true
                    break
                fi
            done
            if [[ "$already_used" == false ]]; then
                remaining_tags+=("$tag")
            fi
        done
        
        # Clean up temp file
        rm -f "$matching_projects_file"
        
        _describe 'tags' remaining_tags
    }
    
    compdef _ptag_zsh ptag
    compdef _ptag_zsh ptag-not
    compdef _ptag_and_zsh ptag-and
fi
