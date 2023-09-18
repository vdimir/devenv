#!/bin/bash

GPG_KEY=${GPG_KEY:-$(git config user.signingkey)}

CLANG_VERSION=${CLANG_VERSION:-14}

set -eux

if [ ! -z ${BASH_SOURCE:-} ]; then
    if [ -z ${DEVHOST} ]; then
        echo "Please, set DEVHOST env variable"
        exit 1
    fi
    if [ ! -z ${GPG_KEY} ] && [ ${GPG_KEY} != "0" ]; then
        gpg --export-secret-key ${GPG_KEY} | ssh $DEVHOST "cat > /tmp/git_key.asc"
        echo "export GPG_KEY=${GPG_KEY}" | ssh $DEVHOST "cat >> /tmp/setup_env"
    fi

    [ ! -z ${INSTALL_PACKAGES:-} ] && echo "export INSTALL_PACKAGES=${INSTALL_PACKAGES}" | ssh $DEVHOST "cat >> /tmp/setup_env"

    rsync -avPL ~/.gitconfig $DEVHOST:.
	ssh $DEVHOST "bash -s" -- < ${BASH_SOURCE}
	exit
fi

set -ue

exec sudo -i -u root
whoami

[ -f /tmp/setup_env ] && source /tmp/setup_env

WORKUSER=ubuntu

echo " ===== Install Packages ====="

if [ ${INSTALL_PACKAGES:-"1"} != "0" ]; then

    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash

    # bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"
    # wget https://apt.llvm.org/llvm.sh && chmod +x llvm.sh && sudo ./llvm.sh ${CLANG_VERSION}

    apt-get update
    apt-get install -y tmux gpg python3 openssh-server cmake ninja-build ccache curl wget
    apt-get install -y git-lfs clang-format-${CLANG_VERSION} clangd-${CLANG_VERSION}
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

[ -f /tmp/setup_env ] && source /tmp/setup_env
[ -f /tmp/git_key.asc ] && gpg --batch --import /tmp/git_key.asc && rm /tmp/git_key.asc

echo " ===== Setup Config Files ====="

grep -q -E '^# user_config$' /home/${USER}/.bashrc || cat <<'EOT' >> /home/${USER}/.bashrc
# user_config
export CC=clang-13 CXX=clang++-13
export EDITOR=vim
alias df="df -h"
alias gis="git st"
export GPG_TTY=$(tty)
EOT

echo " ===== .tmux.conf ====="
grep -q -E '^set -g mouse on$' /home/${USER}/.tmux.conf || cat <<'EOT' >> /home/${USER}/.tmux.conf
set -g default-terminal "screen-256color"
set -g mouse on
EOT

rm -f /tmp/setup_env

cat <<'EOT' > /home/${USER}/bld.sh
#!/bin/bash

set -eux

CLANG_VERSION=14

if [ ! -z ${1:-} ] && [ ! -d $1 ]; then
    echo "Cant find $1"

    SUFFIX=$(realpath $1 | grep -Po '/build\K[a-zA-Z0-9]*')
    ls -d ~/ClickHouse${SUFFIX}
    BUILD_TYPE=$(realpath $1 | grep -Po '/build[a-zA-Z0-9]*/\K.*/?')
    echo ${BUILD_TYPE}

    ARGS=""
    # ARGS="${ARGS} -DENABLE_CLICKHOUSE_ALL=ON"

    case ${BUILD_TYPE} in
    "reldeb")
        ARGS="${ARGS} -DCMAKE_BUILD_TYPE=RelWithDebInfo"
    ;;
    "debug")
        ARGS="${ARGS} -DCMAKE_BUILD_TYPE=Debug"
    ;;
    "asan")
        ARGS="${ARGS} -DCMAKE_BUILD_TYPE=RelWithDebInfo"
        ARGS="${ARGS} -DSANITIZE=address"
    ;;
    "msan")
        ARGS="${ARGS} -DCMAKE_BUILD_TYPE=RelWithDebInfo"
        ARGS="${ARGS} -DSANITIZE=memory"
    ;;
    "tsan")
        ARGS="${ARGS} -DCMAKE_BUILD_TYPE=RelWithDebInfo"
        ARGS="${ARGS} -DSANITIZE=thread"
    ;;
    "ubsan")
        ARGS="${ARGS} -DCMAKE_BUILD_TYPE=RelWithDebInfo"
        ARGS="${ARGS} -DSANITIZE=undefined"
    ;;
    "arm")
        ARGS="${ARGS} -DCMAKE_TOOLCHAIN_FILE=cmake/linux/toolchain-aarch64.cmake"
    ;;
    *)
        echo "Unknown build type '${BUILD_TYPE}'"
        exit 1
    ;;
    esac

    cmake -S ~/ClickHouse${SUFFIX} -B $1 \
        -DCMAKE_C_COMPILER=`which clang-${CLANG_VERSION}` \
        -DCMAKE_CXX_COMPILER=`which clang++-${CLANG_VERSION}` \
        -DCMAKE_C_COMPILER_LAUNCHER=ccache \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
        ${ARGS}
    ninja -C $1
    exit
fi


if [ ! -z ${1:-} ] && [ -d $1 ] ; then
	ln -sf $1/programs/clickhouse ~/clickhouse
	ls -l ~/clickhouse
else
    echo "Please, specify directory with clickhouse"
    exit 1
fi

ninja -C $(realpath ~/clickhouse | sed -e "s|/programs/clickhouse$||") clickhouse  || exit 1

mkdir -p ~/_tmp && cd ~/_tmp
~/clickhouse server
EOT
chmod +x /home/${USER}/bld.sh

echo " ===== Completed ====="
echo "Completed!"
