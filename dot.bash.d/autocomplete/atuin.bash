#!/usr/bin/env bash

# Initialize atuin if available via mise
# Atuin needs to be in PATH for its init script to work properly

_atuin_init() {
    local atuin_bin=""
    
    # Try mise which first (works if atuin is in active config)
    if command -v mise >/dev/null 2>&1; then
        atuin_bin=$(mise which atuin 2>/dev/null)
    fi
    
    # Fallback: find atuin in mise installs directory
    if [[ -z "$atuin_bin" || ! -x "$atuin_bin" ]]; then
        local mise_installs="${MISE_DATA_DIR:-$HOME/.local/share/mise}/installs/atuin"
        if [[ -d "$mise_installs" ]]; then
            # Find the latest version's atuin binary
            atuin_bin=$(find "$mise_installs" -name "atuin" -type f -perm +111 2>/dev/null | head -1)
        fi
    fi
    
    # Initialize if we found atuin
    if [[ -n "$atuin_bin" && -x "$atuin_bin" ]]; then
        local atuin_dir
        atuin_dir=$(dirname "$atuin_bin")
        # Add to PATH so atuin's init script can find itself
        if [[ ":$PATH:" != *":$atuin_dir:"* ]]; then
            export PATH="$atuin_dir:$PATH"
        fi
        eval "$("$atuin_bin" init bash)"
    fi
}

_atuin_init
unset -f _atuin_init
