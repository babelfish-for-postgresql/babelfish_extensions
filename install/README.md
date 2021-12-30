# Quick install scripts

This directory contains scripts for installing Babelfish for PostgreSQL. 

The installation process consist in two steps, one for for installting the pre-requisites and another for downloading and compiling babelfish. 

At this point we only have quickstart scripts for Centos8 and Ubuntu 20. 

## Installing for Centos 8 

For centos8 you need to run the following commands:
``` sh
sudo sh centos.centos8.prerequisites.sh
sudo sh install.sh
```

## Installing for Centos 7
For centos8 you need to run the following commands:
``` sh
sudo sh centos.centos7.prerequisites.sh
sudo sh install.sh
```
## Installing for Ubuntu 20.04

For Ubuntu 20 you need to run the following commands:
``` sh
sudo sh ubuntu.20.04.prerequisites.sh
sudo sh install.sh
```

## Installing for Amazon Linux 2
For Amazon linux 2 you need to run following commands:
``` sh
sudo sh amazonlinux.2.prerequisites.sh
sudo sh install.sh
```

## Install instructions configurations
The are some environment variable that can be set in order to customize the installation script. 

| Variable | Description | Default |
| -------- | ----------- | ------- |
| `BABELFISH_CODE_USER` | The user that will compile babelfish, it cannot be root. If the user doesn't exists it would be created | babelfish-compiler |
| `BABELFISH_CODE_PATH` | The path in which the babelfish code will be downloaded | /opt/babelfish-code |
| `BABELFISH_INSTALLATION_PATH` | The path in which babelfish will be installed | /usr/local/pgsql-13.4 |