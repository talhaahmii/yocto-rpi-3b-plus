FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    gawk \
    wget \
    git \
    diffstat \
    unzip \
    texinfo \
    gcc \
    build-essential \
    chrpath \
    socat \
    cpio \
    python3 \
    python3-pip \
    python3-pexpect \
    python3-venv \
    xz-utils \
    debianutils \
    iputils-ping \
    python3-git \
    python3-jinja2 \
    libegl1 \
    libsdl1.2-dev \
    pylint \
    xterm \
    file \
    locales \
    sudo \
    vim \
    nano \
    rsync \
    bc \
    bzip2 \
    zstd \
    lz4 \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

ARG USER_UID=1000
ARG USER_GID=1000

RUN userdel ubuntu 2>/dev/null || true && \
    groupadd --gid ${USER_GID} yocto && \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash yocto && \
    echo "yocto ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/yocto

USER yocto
WORKDIR /workspace
