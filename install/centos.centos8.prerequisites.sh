#!/bin/sh
dnf install -y gcc gcc-c++ kernel-devel make
dnf install -y bison flex libxml2-devel readline-devel zlib-devel
dnf --enablerepo=powertools install -y uuid-devel pkg-config openssl-devel
dnf install -y libicu-devel postgresql-devel perl
dnf install -y java unzip curl git wget
dnf install -y cmake libuuid-devel
