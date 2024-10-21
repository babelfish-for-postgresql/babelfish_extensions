FROM ubuntu:20.04
 
ENV DEBIAN_FRONTEND=noninteractive 
EXPOSE 5432
COPY . /src/

RUN	apt-get update &&\
	apt-get install -y cmake uuid-dev wget unzip build-essential pkg-config g++ build-essential bison \
	libicu-dev libxml2-dev libssl-dev libossp-uuid-dev libpq-dev openjdk-8-jdk git sudo libreadline-dev flex \
	maven


ARG USER_ID GROUP_ID

RUN adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID user && \
	echo "ALL ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER user

WORKDIR /src