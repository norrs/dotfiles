#!/usr/bin/env bash

rtx where kubectl >/dev/null 2>&1 && source <(rtx x -- kubectl completion bash)
