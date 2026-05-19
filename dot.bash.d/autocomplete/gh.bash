#!/usr/bin/env bash

if command -v gh >/dev/null 2>&1; then
    eval "$(gh completion -s bash)"
fi
