FROM ubuntu:25.04
COPY . .
RUN bash Aeon
# Requirements Mirror Bot
COPY requirements.txt .
RUN pip3 install --break-system-packages --no-cache-dir -r requirements.txt

RUN apt-get -y update && apt-get -y upgrade && apt-get -y autoremove && apt-get -y autoclean

WORKDIR /usr/src/app
RUN chmod 777 /usr/src/app
