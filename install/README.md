# Quick install scripts

This directory contains scripts for installing Babelfish for PostgreSQL. 

By running the install.sh script it will perform the installation process for your linux distribution. 

Currently the supported linux distribution for this script are:

- Centos 7
- Centos 8
- Ubuntu 20.04
- Debian bullseye
- Fedora 36
- Amazon Linux 2

## Install instructions configurations
The are some environment variable that can be set in order to customize the installation script. 

| Variable | Description | Default |
| -------- | ----------- | ------- |
| `BABELFISH_CODE_USER` | The user that will compile babelfish, it cannot be root. If the user doesn't exists it would be created | babelfish-compiler |
| `BABELFISH_CODE_PATH` | The path in which the babelfish code will be downloaded | /opt/babelfish-code |
| `BABELFISH_INSTALLATION_PATH` | The path in which babelfish will be installed | /usr/local/pgsql-13.4 |