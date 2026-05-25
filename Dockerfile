FROM ubuntu:22.04

# ── Environment (Docker-Optimized) ──
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Kolkata \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    TERM=dumb \
    PYTHON=/usr/bin/python3.12

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
        software-properties-common locales && \
    locale-gen en_US.UTF-8 && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update -qq && \
    rm -rf /var/lib/apt/lists/*

# ── Run Main Script ──
RUN bash /root/Aeon

# ── Optional Ports ──
EXPOSE 8080 6881 6881/udp 8112

CMD ["/bin/bash"]
