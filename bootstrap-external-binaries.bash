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
  curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o $HOME/.local/bin/docker-compose
}

function install_kubeseal() {
  wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.11.0/kubeseal-linux-amd64 -O $HOME/.local/bin/kubeseal
  chmod +x $HOME/.local/bin/kubeseal
}

function install_kompose() {
  curl -L https://github.com/kubernetes/kompose/releases/download/v1.21.0/kompose-linux-amd64 -o $HOME/.local/bin/kompose
  chmod +x $HOME/.local/bin/kompose
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
 #install_vault
 #install_docker_compose 
 install_kubeseal
 install_kompose
fi
