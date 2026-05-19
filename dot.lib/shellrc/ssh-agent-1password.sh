#!/usr/bin/env bash
# Configure SSH to use 1Password SSH agent on macOS
# This overrides any SSH_AUTH_SOCK set by launchd or other sources

if [[ "$OSTYPE" == "darwin"* ]]; then
    # 1Password SSH agent socket path (use full path without tilde)
    _1password_socket="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    if [[ -S "$_1password_socket" ]]; then
        # Force override of SSH_AUTH_SOCK to use 1Password
        export SSH_AUTH_SOCK="$_1password_socket"
    fi
    unset _1password_socket
fi
