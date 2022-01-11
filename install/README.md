# Quick install scripts

This directory contains scripts that install Babelfish for PostgreSQL. Select the install.sh script for your Linux platform to install Babelfish on your system.

Currently the supported Linux distributions are:

- Centos 7
- Centos 8
- Ubuntu 20.04
- Debian bullseye
- Fedora 36
- Amazon Linux 2

## Install instructions configurations

You can use environment variables to customize the installation script:

| Variable | Description | Default |
| -------- | ----------- | ------- |
| `BABELFISH_CODE_USER` | The user that will compile babelfish, it cannot be root. If the user doesn't exists it would be created | babelfish-compiler |
| `BABELFISH_CODE_PATH` | The path in which the babelfish code will be downloaded | /opt/babelfish-code |
| `BABELFISH_INSTALLATION_PATH` | The path in which babelfish will be installed | /usr/local/pgsql-13.4 |