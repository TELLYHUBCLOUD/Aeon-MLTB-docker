FROM python:3.13.3
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    LD_LIBRARY_PATH="/usr/local/lib"

# ── System packages ──────────────────────────────────────────────────────────
RUN echo "deb http://deb.debian.org/debian bookworm-backports main" \
        > /etc/apt/sources.list.d/backports.list && \
    apt-get update && \
    # OpenJDK 21 only available via backports on Debian Bookworm
    apt-get install -y -t bookworm-backports --no-install-recommends \
        openjdk-21-jre-headless && \
    apt-get install -y --no-install-recommends \
        build-essential gcc g++ make python3-dev libc6-dev \
        git curl wget unzip tar xz-utils zstd \
        aria2 \
        mediainfo \
        cpulimit util-linux procps \
        autoconf automake libtool pkg-config swig cmake \
        libffi-dev libssl-dev libcurl4-openssl-dev libsqlite3-dev \
        libsodium-dev libfreeimage-dev libpcre3-dev libcrypto++-dev \
        libboost-all-dev zlib1g-dev libuv1-dev libc-ares-dev \
        libmagic1 libmediainfo0v5 \
        ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
    
# ── uv ───────────────────────────────────────────────────────────────────────
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# ── qBittorrent-nox 5.2.0 + FFmpeg 7.1.1 static binaries (arch-aware) ───────
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        QB_URL="https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/x86_64-qbittorrent-nox"; \
        FFM_URL="https://github.com/5hojib/FFmpeg-Builds/releases/download/latest/ffmpeg-n7.1-latest-linux64-gpl-7.1.tar.xz"; \
    else \
        QB_URL="https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/aarch64-qbittorrent-nox"; \
        FFM_URL="https://github.com/5hojib/FFmpeg-Builds/releases/download/latest/ffmpeg-n7.1-latest-linuxarm64-gpl-7.1.tar.xz"; \
    fi && \
    # qbittorrent-nox
    wget -qO /usr/local/bin/qbittorrent-nox "$QB_URL" && \
    chmod 755 /usr/local/bin/qbittorrent-nox && \
    # ffmpeg 7.1.1
    wget -qO /tmp/ffmpeg.tar.xz "$FFM_URL" && \
    tar -xf /tmp/ffmpeg.tar.xz -C /tmp && \
    FFM_DIR=$(find /tmp -maxdepth 1 -type d -name "ffmpeg-n7.1-latest-linux*" | head -n 1) && \
    mv "$FFM_DIR/bin/ffmpeg"  /usr/bin/ffmpeg  && \
    mv "$FFM_DIR/bin/ffprobe" /usr/bin/ffprobe && \
    mv "$FFM_DIR/bin/ffplay"  /usr/bin/ffplay  && \
    chmod +x /usr/bin/ffmpeg /usr/bin/ffprobe /usr/bin/ffplay && \
    rm -rf /tmp/ffmpeg.tar.xz "$FFM_DIR"

# ── rclone 1.74.1 ────────────────────────────────────────────────────────────
RUN curl -fsSL https://rclone.org/install.sh | bash

# ── 7-Zip 24.09 ──────────────────────────────────────────────────────────────
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        SZ_URL="https://www.7-zip.org/a/7z2409-linux-x64.tar.xz"; \
    else \
        SZ_URL="https://www.7-zip.org/a/7z2409-linux-arm64.tar.xz"; \
    fi && \
    mkdir /tmp/7z_tmp && \
    wget -qO /tmp/7z_tmp/7z.tar.xz "$SZ_URL" && \
    tar -xf /tmp/7z_tmp/7z.tar.xz -C /tmp/7z_tmp && \
    cp /tmp/7z_tmp/7zz /usr/bin/7z  && \
    cp /tmp/7z_tmp/7zz /usr/bin/7za && \
    cp /tmp/7z_tmp/7zz /usr/bin/7zz && \
    chmod +x /usr/bin/7z /usr/bin/7za /usr/bin/7zz && \
    rm -rf /tmp/7z_tmp

# ── JDownloader ──────────────────────────────────────────────────────────────
RUN mkdir -p /JDownloader/cfg && \
    wget -qO /JDownloader/JDownloader.jar http://installer.jdownloader.org/JDownloader.jar

# ── Symlinks ─────────────────────────────────────────────────────────────────
RUN ln -sf /usr/local/bin/qbittorrent-nox /usr/local/bin/torrentgod  && \
    ln -sf /usr/bin/aria2c                /usr/local/bin/speeddemon   && \
    ln -sf /usr/bin/ffmpeg                /usr/local/bin/vidwarlock   && \
    ln -sf /usr/bin/rclone                /usr/local/bin/cloudphantom && \
    ln -sf /usr/bin/mediainfo             /usr/local/bin/mediainfo

# ── Python base packages ──────────────────────────────────────────────────────
RUN uv pip install --system --no-cache-dir cython setuptools wheel

# ── Python requirements ───────────────────────────────────────────────────────
COPY requirements.txt /tmp/requirements.txt
RUN uv pip install --system --no-cache-dir -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

# ── MegaSDK v8.1.1 ───────────────────────────────────────────────────────────
RUN git clone --depth 1 --branch v8.1.1 https://github.com/meganz/sdk.git /tmp/sdk && \
    cd /tmp/sdk && \
    ./autogen.sh && \
    ./configure --disable-silent-rules --enable-python --with-sodium --disable-examples && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd bindings/python && \
    python3 setup.py bdist_wheel && \
    pip install --no-cache-dir dist/megasdk-*.whl && \
    cd / && rm -rf /tmp/sdk && \
    # Purge build-only packages
    apt-get purge -y \
        autoconf automake libtool swig cmake \
        build-essential gcc g++ make \
        libboost-all-dev libcurl4-openssl-dev libssl-dev \
        libc-ares-dev libsqlite3-dev zlib1g-dev && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app
