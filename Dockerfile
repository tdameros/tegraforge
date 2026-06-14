FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update && apt-get install -y \
    sudo \
    wget \
    curl \
    git \
    git-lfs \
    rsync \
    unzip \
    zip \
    xz-utils \
    bc \
    bison \
    flex \
    cpio \
    kmod \
    file \
    vim \
    nano \
    jq \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    ninja-build \
    pkg-config \
    libssl-dev \
    libelf-dev \
    dwarves \
    device-tree-compiler \
    qemu-user-static \
    qemu-utils \
    binfmt-support \
    dosfstools \
    mtools \
    parted \
    gdisk \
    e2fsprogs \
    openssh-client \
    sshpass \
    ca-certificates \
    lz4 \
    zstd \
    pigz \
 && rm -rf /var/lib/apt/lists/*

RUN wget -qO /usr/local/bin/yq \
    https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq


RUN useradd -m -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /workspace

CMD ["/bin/bash"]