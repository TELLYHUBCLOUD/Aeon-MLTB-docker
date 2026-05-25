FROM ubuntu:22.04

# ── Environment ──
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Kolkata \
    LANG=en_US.UTF-8 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /root

# ── Copy & Permissions ──
COPY Aeon /root/Aeon
RUN chmod +x /root/Aeon

# ── Prerequisites (PFA & Basic Tools) ──
RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
        bash curl wget git ca-certificates gnupg software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update -qq && \
    rm -rf /var/lib/apt/lists/*

# ── Run Script ──
RUN bash /root/Aeon

CMD ["/bin/bash"]
