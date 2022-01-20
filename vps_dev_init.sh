#!/bin/bash

GPG_KEY=${GPG_KEY:-60A6DF2F983FCD4667C41A1C9B404D301C0CC7EB}

set -eux

if [ ! -z ${BASH_SOURCE:-} ]; then
    if [ -z ${DEVHOST} ]; then
        echo "Please, set DEVHOST env variable"
        exit 1
    fi
    if [ ! -z ${GPG_KEY} ]; then
        gpg --export-secret-key ${GPG_KEY} | ssh -i ${DEVHOSTKEY:-~/.keys/aws_key.pem} ${DEVHOSTUSER:-ubuntu}@$DEVHOST "cat > /tmp/git_key.asc"
        echo "export GPG_KEY=${GPG_KEY}" | ssh -i ${DEVHOSTKEY:-~/.keys/aws_key.pem} ${DEVHOSTUSER:-ubuntu}@$DEVHOST "cat >> /tmp/setup_env"
    fi

	ssh -i ${DEVHOSTKEY:-~/.keys/aws_key.pem} ${DEVHOSTUSER:-ubuntu}@$DEVHOST "bash -s" -- < ${BASH_SOURCE}
	exit
fi

set -ue

exec sudo -i -u root
whoami

WORKUSER=ubuntu

echo " ===== Install Packages ====="

if [ ! -z ${SKIP_PACKAGES:-} ]; then

apt-get update
apt-get install -y tmux
apt-get install -y gpg python3
apt-get install -y cmake ninja-build ccache

bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"

fi

echo " ===== Create User ====="
echo ${WORKUSER}


if [ ! $(id -u ${WORKUSER}) ]; then
    useradd -m -d /home/${WORKUSER} -s /bin/bash ${WORKUSER}
    mkdir -p /home/${WORKUSER}/.ssh/
    cp ~/.ssh/authorized_keys /home/${WORKUSER}/.ssh/authorized_keys
    chown -R ${WORKUSER}:${WORKUSER} /home/${WORKUSER}/.ssh
fi

usermod -aG docker ${WORKUSER} || echo "No 'docker' group"
usermod -aG sudo ${WORKUSER}

exec sudo -i -u ${WORKUSER}
whoami

[ -f /tmp/setup_env ] && source /tmp/setup_env && rm /tmp/setup_env

[ -f /tmp/git_key.asc ] && gpg --import /tmp/git_key.asc && rm /tmp/git_key.asc

echo " ===== Setup Config Files ====="

echo " ===== .bashrc ====="
cat <<EOT >> /home/${USER}/.bashrc
export CC=clang CXX=clang++
export EDITOR=vim
alias df="df -h"
alias gis="git st"
EOT

echo " ===== .tmux.conf ====="
cat <<EOT >> /home/${USER}/.tmux.conf
set -g default-terminal "screen-256color"
set -g mouse on
EOT

echo " ===== .gitconfig ====="
cat <<EOT >> /home/${USER}/.gitconfig
[alias]
    co = checkout
    st = status
    ci = commit -v
    lg = log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all
    br = branch
[push]
    default = current
[pull]
    rebase = true
[fetch]
    prune = true
[core]
    autocrlf = input
[user]
    email = vdimir@clickhouse.com
    name = vdimir
    signingkey = ${GPG_KEY:-}
EOT


echo " ===== Completed ====="
echo "Completed!"

