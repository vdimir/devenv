#!/bin/bash

if [ ! -z ${BASH_SOURCE} ]; then
    if [ -z ${DODEV} ]; then
        echo "Please, set DODEV env variable"
        exit 1
    fi

	ssh -i ~/.ssh/id_rsa_do root@$DODEV "bash -s" -- < ${BASH_SOURCE}
	exit
fi

set -ue

echo " ===== Create User ====="

useradd -m -d /home/vdimir -s /bin/bash vdimir
mkdir -p /home/vdimir/.ssh/
cp ~/.ssh/authorized_keys /home/vdimir/.ssh/authorized_keys
chown -R vdimir:vdimir /home/vdimir/.ssh

usermod -aG docker vdimir || echo "No 'docker' group"
usermod -aG sudo vdimir

echo " ===== Install Packages ====="

apt-get update
apt-get install -y tmux
apt-get install -y cmake ninja-build python sudo
apt-get install -y clang clang-10 clang++10 libc++-dev lld ccache

sudo -i -u vdimir bash << USERCONFIGEOT

echo " ===== Setup Config Files ====="

echo " ===== .bashrc ====="
cat <<EOT >> /home/vdimir/.bashrc
export CC=clang CXX=clang++
export EDITOR=vim
alias df="df -h"
alias gis="git st"
EOT

echo " ===== .tmux.conf ====="
cat <<EOT >> /home/vdimir/.tmux.conf
set -g default-terminal "screen-256color"
set -g mouse on
EOT

echo " ===== .gitconfig ====="
cat <<EOT >> /home/vdimir/.gitconfig
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
    email = vdimirc@gmail.com
    name = vdimir
EOT


echo " ===== Completed ====="
echo "Completed!"

USERCONFIGEOT
