#!/usr/bin/env bash
# Only load kcd completion if kcd is available and executable
if command -v kcd >/dev/null 2>&1 && kcd version >/dev/null 2>&1; then
    source <(kcd completion bash)
fi
