#!/bin/sh
yum update -y
yum install -y gcc gcc-c++ bzip2 make wget

mkdir /opt/gcc
cd /opt/gcc

wget http://mirrors.up.pt/pub/gnu/gcc/gcc-8.5.0/gcc-8.5.0.tar.gz
tar -xzvf gcc-8.5.0.tar.gz

mkdir /opt/gcc/gcc-8.5.0/build
cd /opt/gcc/gcc-8.5.0

./contrib/download_prerequisites
cd /opt/gcc/gcc-8.5.0/build

yum install -y kernel-devel zlib-devel glibc-devel

../configure -enable-bootstrap --enable-languages=c,c++,fortran,lto --prefix=/usr \
  --mandir=/usr/share/man --infodir=/usr/share/info \
  --with-bugurl=http://bugzilla.redhat.com/bugzilla --enable-shared --enable-threads=posix \
  --enable-checking=release --disable-multilib --with-system-zlib --enable-__cxa_atexit \
  --disable-libunwind-exceptions --enable-gnu-unique-object --enable-linker-build-id \
  --with-gcc-major-version-only --with-linker-hash-style=gnu --enable-plugin \
  --enable-initfini-array --with-isl --disable-libmpx --enable-offload-targets=nvptx-none \
  --without-cuda-driver --enable-gnu-indirect-function --with-tune=generic \
  --with-arch_32=x86-64 --build=x86_64-redhat-linux

make -j6
make install

yum install -y bison flex libxml2-devel readline-devel
yum install -y uuid-devel pkg-config openssl-devel
yum install -y libicu-devel postgresql-devel perl
yum install -y java unzip curl git
yum install -y http://repo.okay.com.mx/centos/7/x86_64/release/okay-release-1-1.noarch.rpm
yum install -y cmake3 libuuid-devel


ln -s /usr/bin/cmake3 /usr/bin/cmake