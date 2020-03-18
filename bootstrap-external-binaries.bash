#!/usr/bin/env bash

vault=1.3.2

function install_vault() {
 local tmp
 tmp="$(mktemp -d --suffix norrsdotfiles)"
 wget -O "${tmp}/vault.zip" https://releases.hashicorp.com/vault/${vault}/vault_${vault}_linux_amd64.zip  
 ( cd "$tmp" && unzip vault.zip )
 cp "${tmp}/vault" "$HOME/.local/bin/vault-cli"
 chmod +x "$HOME/.local/bin/vault-cli"
}

function install_docker_compose() {
  curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o $HOME/.local/bin/docker-compose
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
 install_vault
 install_docker_compose 
fi
