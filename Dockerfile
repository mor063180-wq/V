# Ubuntu server with SSH enabled — hardened but keeps normal root/password VPS-style access
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install SSH server, sudo, tools, and hardening packages
# (rsyslog is required so fail2ban has auth logs to read inside the container)
RUN apt-get update && apt-get install -y \
    openssh-server \
    sudo \
    curl \
    vim \
    nano \
    net-tools \
    htop \
    fail2ban \
    rsyslog \
    unattended-upgrades \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd

# Non-root user, kept for convenience (optional to use)
RUN useradd -m -s /bin/bash learner \
    && echo "learner:changeme123" | chpasswd \
    && usermod -aG sudo learner

# Root password — CHANGE "changeme123" BEFORE DEPLOYING. Use a long, random
# password (20+ characters). A weak one here defeats all the hardening below.
RUN echo "root:changeme123" | chpasswd

# --- SSH hardening while keeping normal root+password login ---
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/' /etc/ssh/sshd_config \
    && sed -i 's/#LoginGraceTime 2m/LoginGraceTime 20/' /etc/ssh/sshd_config \
    && sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 300/' /etc/ssh/sshd_config \
    && sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 2/' /etc/ssh/sshd_config

# --- fail2ban: bans an IP after repeated failed SSH logins ---
# backend=auto + rsyslog gives fail2ban a real auth.log to poll inside the container
RUN mkdir -p /etc/fail2ban/jail.d && \
    cat > /etc/fail2ban/jail.d/sshd.local << 'JAILEOF'
[sshd]
enabled = true
port = ssh
maxretry = 3
findtime = 10m
bantime = 1h
backend = auto
JAILEOF

# --- Automatic security updates ---
RUN printf '%s\n' 'Unattended-Upgrade::Allowed-Origins {' '    "${distro_id}:${distro_codename}-security";' '};' > /etc/apt/apt.conf.d/51unattended-upgrades-security

EXPOSE 22

# Start rsyslog (so sshd auth attempts get logged for fail2ban to read),
# then fail2ban, then sshd in the foreground so the container stays alive
CMD service rsyslog start && service fail2ban start && /usr/sbin/sshd -D
