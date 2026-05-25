FROM ubuntu:22.04

# ── Environment (Docker-Optimized) ──
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Kolkata \
    LANG=en_US.UTF-8 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    TERM=dumb

# ── Prevent SIGPIPE in shell ──
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /root

# ── Copy Script ──
COPY Aeon /root/Aeon
RUN chmod +x /root/Aeon

# ── Install Prerequisites ──
RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
        bash curl wget git ca-certificates gnupg \
        software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update -qq && \
    rm -rf /var/lib/apt/lists/*

# ── Run Main Script (with SIGPIPE tolerance) ──
# Using || [ $? -eq 141 ] to ignore SIGPIPE exits
RUN bash /root/Aeon || { EXIT_CODE=$?; [ $EXIT_CODE -eq 141 ] && exit 0 || exit $EXIT_CODE; }

# ── Optional Ports ──
EXPOSE 8080 6881 6881/udp 8112

CMD ["/bin/bash"]
