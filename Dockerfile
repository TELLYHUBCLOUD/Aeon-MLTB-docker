FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Kolkata \
    LANG=en_US.UTF-8

WORKDIR /root

COPY Aeon /root/Aeon
RUN chmod +x /root/Aeon

RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
        bash curl wget git ca-certificates gnupg \
        software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update -qq && \
    rm -rf /var/lib/apt/lists/*

RUN bash /root/Aeon

CMD ["/bin/bash"]
