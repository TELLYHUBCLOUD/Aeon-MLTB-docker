# ── Aeon Setup - Dockerfile ──
FROM ubuntu:22.04

# ── Environment Variables ──
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Kolkata \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# ── Working Directory ──
WORKDIR /root

# ── Copy Script First (for better layer caching) ──
COPY Aeon /root/Aeon
COPY .dockerignore /root/.dockerignore 2>/dev/null || true

# ── Make Script Executable ──
RUN chmod +x /root/Aeon

# ── Install Minimal Prerequisites (before running main script) ──
RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
        bash curl wget git ca-certificates gnupg \
        software-properties-common && \
    rm -rf /var/lib/apt/lists/*

# ── Add Deadsnakes PPA for Python 3.12 (Ubuntu 22.04 default is 3.10) ──
RUN add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update -qq && \
    rm -rf /var/lib/apt/lists/*

# ── Run Main Setup Script ──
# Using --allow-run-as-root for safety check bypass in container
RUN bash /root/Aeon

# ── Expose Common Ports (Optional - Adjust as needed) ──
EXPOSE 8080 6881 6881/udp 8112 51413 51413/udp

# ── Default Command ──
CMD ["/bin/bash"]
