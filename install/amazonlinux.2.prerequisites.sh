#!/bin/sh
yum update -y
yum install -y gcc gcc-c++ kernel-devel make
yum install -y bison flex libxml2-devel readline-devel zlib-devel
yum install -y uuid-devel pkg-config openssl-devel
yum install -y libicu-devel postgresql-devel perl
yum install -y shadow-utils wget
yum install -y java unzip curl git
yum install -y cmake3 libuuid-devel

ln -s /usr/bin/cmake3 /usr/bin/cmake
