FROM       ubuntu:18.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
                       git rsync sudo vim less \
                       bash-completion \
                       cmake ninja-build \
                       pbuilder debhelper lsb-release \
                       fakeroot debian-archive-keyring debian-keyring \
                       openssh-server \
                       less \
                       python \
    && apt-get install -y software-properties-common && \
       apt-add-repository -y ppa:ubuntu-toolchain-r/test && \
       apt-get install -y gcc-9 g++-9 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /var/run/sshd

# RUN echo 'root:root' |chpasswd

# RUN sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
# RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config

# RUN mkdir /root/.ssh

EXPOSE 22

ARG USERNAME=ubuntu
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID -o $USERNAME && \
    useradd -r -m -d /home/$USERNAME -s /bin/bash -g $GID -G sudo -u $UID $USERNAME && \
    echo "$USERNAME:ubuntu" |chpasswd

# USER $USERNAME
# WORKDIR /home/$USERNAME

CMD    ["/usr/sbin/sshd", "-D"]

