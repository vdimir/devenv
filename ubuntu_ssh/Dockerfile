FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
                       git rsync sudo vim less \
                       bash-completion \
                       cmake ninja-build \
                       pbuilder debhelper lsb-release \
                       fakeroot debian-archive-keyring debian-keyring \
                       openssh-server \
                       less \
                       python \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"

RUN echo 'root:root' | chpasswd \
    && mkdir /root/.ssh

RUN mkdir /var/run/sshd \
    && sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config

EXPOSE 22

ARG USERNAME=ubuntu
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID -o $USERNAME \
    && useradd -r -m -d /home/$USERNAME -s /bin/bash -g $GID -G sudo -u $UID $USERNAME \
    && echo "$USERNAME:ubuntu" |chpasswd

USER $USERNAME
WORKDIR /home/$USERNAME

RUN mkdir -p $HOME/.ssh

CMD ["/usr/sbin/sshd", "-D"]
