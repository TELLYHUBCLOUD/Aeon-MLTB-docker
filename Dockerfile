FROM python:3.12-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    LD_LIBRARY_PATH="/usr/local/lib"

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gcc g++ make python3-dev libc6-dev git curl wget unzip p7zip-full tar ffmpeg mediainfo aria2 qbittorrent-nox openjdk-17-jre-headless cpulimit util-linux procps autoconf automake libtool pkg-config swig cmake libffi-dev libssl-dev libcurl4-openssl-dev libsqlite3-dev libsodium-dev libfreeimage-dev libpcre3-dev libcrypto++-dev zlib1g-dev libuv1-dev libc-ares-dev libmagic1 libmediainfo0v5 ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

RUN curl https://rclone.org/install.sh | bash && \
    mkdir -p /JDownloader/cfg && \
    wget -O /JDownloader/JDownloader.jar http://installer.jdownloader.org/JDownloader.jar

RUN ln -sf /usr/bin/qbittorrent-nox /usr/local/bin/torrentgod && \
    ln -sf /usr/bin/aria2c /usr/local/bin/speeddemon && \
    ln -sf /usr/bin/ffmpeg /usr/local/bin/vidwarlock && \
    ln -sf /usr/bin/ffprobe /usr/local/bin/ffprobe && \
    ln -sf /usr/bin/mediainfo /usr/local/bin/mediainfo && \
    ln -sf /usr/local/bin/rclone /usr/local/bin/cloudphantom

RUN uv pip install --system cython setuptools wheel

COPY requirements.txt /tmp/requirements.txt
RUN uv pip install --system --no-cache-dir -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

RUN git clone --depth 1 --branch v8.1.1 https://github.com/meganz/sdk.git /tmp/sdk && \
    PIP_BREAK_SYSTEM_PACKAGES=1 python3 -m pip install wheel setuptools && \
    cmake -S /tmp/sdk -B /tmp/sdk/build \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_PYTHON_BINDINGS=ON \
        -DENABLE_SDKLIB_EXAMPLES=OFF \
        -DENABLE_SDKLIB_TESTS=OFF \
        -DUSE_FREEIMAGE=OFF \
        -DUSE_FFMPEG=OFF \
        -DUSE_MEDIAINFO=OFF \
        -DUSE_PDFIUM=OFF && \
    cmake --build /tmp/sdk/build -j$(nproc) && \
    cmake --install /tmp/sdk/build && \
    ldconfig && \
    PIP_BREAK_SYSTEM_PACKAGES=1 python3 -m pip install /tmp/sdk/build/bindings/python/dist/*.whl && \
    cd / && \
    rm -rf /tmp/sdk && \
    apt-get purge -y autoconf automake libtool swig cmake && \
    apt-get autoremove -y && \
    apt-get clean

WORKDIR /usr/src/app
