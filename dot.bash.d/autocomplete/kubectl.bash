#!/usr/bin/env bash

if command -v mise >/dev/null 2>&1 && mise ls kubectl >/dev/null 2>&1; then
    source <(mise exec -- kubectl completion bash)
    # Enable completion for the 'k' alias
    if [[ $(type -t compopt) = "builtin" ]]; then
        complete -o default -F __start_kubectl k
    else
        complete -o default -o nospace -F __start_kubectl k
    fi
fi
