FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ---------- ابزار پایه + زبان‌های برنامه‌نویسی ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server sudo curl wget unzip tar git vim nano net-tools htop \
    build-essential gdb cmake valgrind \
    python3 python3-pip python3-venv \
    nodejs npm \
    golang-go \
    openjdk-21-jdk \
    php-cli \
    ruby-full \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# ---------- SSH ----------
RUN mkdir -p /run/sshd
RUN useradd -m -s /bin/bash learner && \
    echo 'learner:changeme123' | chpasswd && \
    usermod -aG sudo learner
RUN echo 'root:changeme123' | chpasswd
RUN sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# ---------- 3x-ui (شامل Xray-core: VLESS, VMess, Trojan, Shadowsocks) ----------
RUN mkdir -p /usr/local/x-ui && cd /usr/local/x-ui && \
    curl -L -o x-ui.tar.gz https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz && \
    tar -xzf x-ui.tar.gz --strip-components=1 && \
    chmod +x x-ui bin/xray-linux-amd64 && \
    rm x-ui.tar.gz

# ---------- sing-box (برای NaiveProxy, ShadowTLS, TUIC, Hysteria2) ----------
RUN mkdir -p /usr/local/sing-box && cd /usr/local/sing-box && \
    SING_VER=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | grep tag_name | cut -d '"' -f4 | sed 's/^v//') && \
    curl -L -o sing-box.tar.gz "https://github.com/SagerNet/sing-box/releases/download/v${SING_VER}/sing-box-${SING_VER}-linux-amd64.tar.gz" && \
    tar -xzf sing-box.tar.gz --strip-components=1 && \
    chmod +x sing-box && \
    rm sing-box.tar.gz

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 22
EXPOSE 443
EXPOSE 2053
EXPOSE 8443

CMD ["/start.sh"]
