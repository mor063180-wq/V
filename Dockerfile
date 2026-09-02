FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openssh-server \
        sudo \
        curl \
        vim \
        nano \
        net-tools \
        htop && \
    rm -rf /var/lib/apt/lists/*

# SSH runtime directory
RUN mkdir -p /run/sshd

# Create optional non-root user
RUN useradd -m -s /bin/bash learner && \
    echo 'learner:changeme123' | chpasswd && \
    usermod -aG sudo learner

# Temporary root password for initial setup
RUN echo 'root:changeme123' | chpasswd

# Basic SSH configuration
RUN sed -i \
        's/^#\?PermitRootLogin .*/PermitRootLogin yes/' \
        /etc/ssh/sshd_config && \
    sed -i \
        's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' \
        /etc/ssh/sshd_config && \
    sed -i \
        's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/' \
        /etc/ssh/sshd_config

# Railway routes its public TCP port to the container's SSH port
EXPOSE 22

# Run SSH in foreground and send logs to container stderr
CMD ["/usr/sbin/sshd", "-D", "-e"]
